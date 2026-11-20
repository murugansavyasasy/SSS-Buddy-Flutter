# Trip distance API: accurate, road-following distance

Backend contract for **Today Visit**, **Root Tracker** and **Status Report**. The goal is that every screen (the rep's phone, the manager's report, conveyance claims) shows **one** distance per trip. That distance is the road distance the rep actually travelled, calculated **on the server** from the phone's GPS track.

This extends `docs/ROOT_TRACKER_API.md`. That file defines `SaveTripLocations` / `GetTripLocations`, and this document keeps them backward compatible.

- Base URL: VIMS (`http://score.savyasasy.com/`). Every request sends `Authorization: Bearer <login token>`.
- Times are the phone's local time (IST), `yyyy-MM-dd HH:mm:ss`, as today.
- Distances in the API are **kilometres** (`distance_km`, 2 decimals) unless the name says `_m`.

---

## 1. Why the current numbers are wrong

| Where | How the distance is made today | Problem |
|---|---|---|
| Status Report / Root Tracker total | App joins **start → each visit's school lat/lng → end** with straight lines, then multiplies by **1.3** (`DistanceCalculator.totalApproximateRoadDistance`, `lib/auth/model/OverallTripDetailsModel.dart`). | Ignores the real route: driving 30 km between two visits counts as the straight gap. The ×1.3 is a guess. The haversine there divides by 1.8 instead of 2 (app bug, being fixed separately). |
| Today Visit (live, on phone) | Sums straight segments between GPS fixes (10 m filter, drops accuracy > 50 m and jumps > 180 km/h). | Better, but GPS jitter adds distance and gaps (tunnel, phone killed, GPS off) lose distance. It stays on the phone only and never reaches the server. |

**Fix:** the phone uploads the full GPS track (it already does via `SaveTripLocations`). When the trip ends, the **server map-matches the track to roads**, stores `distance_km` on the trip, and returns it everywhere. The app stops calculating report distances itself.

---

## 2. Trip start / end: `POST /api/mobile/ManageTripDetails` (changed response)

Request is unchanged:

```json
{ "latitude": "13.082712", "longitude": "80.270718", "type": "start", "user_id": "123" }
```

### `type: "start"`: response must include the new trip id

```json
{ "status": 1, "result": "1", "trip_id": 456, "segment": 0 }
```

- `trip_id`: id of the trip row just created. The app sends it with every GPS batch.
- `segment`: 0 for the first trip of the day, then 1, 2… when the rep starts again the same day.

### `type: "stop"`: response returns the trip summary

The server finishes the distance calculation (section 4) **before** responding. If processing takes longer than about 10 s, respond with `"distance_status": "processing"` and fill the distance in later (the app re-reads it with `GetTripRoute`).

```json
{
  "status": 1,
  "result": "1",
  "trip_id": 456,
  "distance_km": 42.37,
  "duration_min": 385,
  "distance_status": "done",
  "method": "map_matched",
  "points_used": 1840
}
```

| Field | Values |
|---|---|
| `distance_status` | `done` · `processing` · `failed` |
| `method` | `map_matched` (normal) · `gps_sum` (map matching failed, sum of filtered GPS segments) · `stops_only` (fewer than 2 usable GPS points, road route through start, visits and end) |

Before ending the trip, the app first uploads every point still queued on the phone, then calls `stop`. Points that arrive **after** `stop` (e.g. phone was offline) must trigger a recalculation (section 4.6).

---

## 3. GPS points: `POST /api/mobile/SaveTripLocations` (new optional fields)

```json
{
  "user_id": "123",
  "trip_id": 456,
  "trip_date": "2026-11-20",
  "points": [
    {
      "latitude": 13.082712,
      "longitude": 80.270718,
      "recorded_at": "2026-11-20 09:14:03",
      "accuracy_m": 8.5,
      "speed_mps": 11.2,
      "heading": 87.0,
      "segment": 0
    }
  ]
}
```

| Field | Type | Notes |
|---|---|---|
| `trip_id` | int | **New.** From the `start` response. If missing (older app), attach by `user_id` + `trip_date` + `segment`. |
| `accuracy_m` | number | **New.** GPS horizontal accuracy in metres (smaller = better). Used as the matching radius. |
| `speed_mps` | number \| null | **New.** Speed from GPS, metres/second. |
| `heading` | number \| null | **New.** 0–360°. |
| others | | Unchanged from `ROOT_TRACKER_API.md`. |

- The app sends a batch every 20 points or 2 minutes, plus once before `stop`. It keeps only fixes with accuracy ≤ 30 m.
- **Idempotent:** a batch can be resent after a network error. Ignore exact duplicates (`user_id` + `recorded_at` + latitude + longitude).
- Response:

```json
{ "status": 1, "saved": 20, "duplicates": 0 }
```

Any other `status`, or a non-200, and the app keeps the batch and retries later.

### Table changes

```
trip_locations(
  id, trip_id, user_id, trip_date, segment,
  latitude DECIMAL(9,6), longitude DECIMAL(9,6),
  accuracy_m DECIMAL(6,1) NULL, speed_mps DECIMAL(6,2) NULL, heading DECIMAL(5,1) NULL,
  recorded_at DATETIME,
  UNIQUE (user_id, recorded_at, latitude, longitude),
  INDEX (trip_id, recorded_at)
)

trips  -- add:
  distance_km DECIMAL(8,2) NULL,
  distance_method VARCHAR(16) NULL,       -- map_matched | gps_sum | stops_only
  distance_status VARCHAR(16) NULL,       -- done | processing | failed
  route_polyline MEDIUMTEXT NULL,         -- encoded polyline (precision 6)
  points_used INT NULL,
  distance_calculated_at DATETIME NULL
```

---

## 4. Server: how to calculate the distance (on `stop`)

### 4.1 Load and clean the points
1. All `trip_locations` of the trip, ordered by `recorded_at`.
2. Drop points with `accuracy_m > 30` (keep them if `accuracy_m` is null, as older app versions don't send it).
3. Drop exact duplicates and points less than 5 m from the previous kept point (standing still).
4. Drop "teleports": implied speed from the previous point > 180 km/h.

### 4.2 Split into runs at gaps
A **gap** is more than 2 minutes, or more than 1 km, between two consecutive points. Each continuous run is matched on its own (4.3). Each gap is bridged with a road route (4.4).

### 4.3 Map-match each run (OSRM `match` service)

Send runs in **chunks of at most 100 points**. That is the default `--max-matching-size` of `osrm-routed`, and the public demo server has the same limit. Overlap chunks by 1 point so no stretch is lost.

```
GET {OSRM}/match/v1/driving/{lng1},{lat1};{lng2},{lat2};...
    ?timestamps={unix1};{unix2};...
    &radiuses={r1};{r2};...          # r = clamp(accuracy_m, 5, 30), default 15
    &gaps=split
    &tidy=true
    &overview=full
    &geometries=polyline6
```

Response (relevant parts):

```json
{
  "code": "Ok",
  "matchings": [
    { "distance": 18234.6, "duration": 1840.2, "confidence": 0.93, "geometry": "..." }
  ],
  "tracepoints": [ { "location": [80.2707, 13.0827], "matchings_index": 0 }, null, ... ]
}
```

- Chunk distance = **sum of `matchings[].distance`** (metres).
- If `code` is not `Ok`, or a matching has `confidence < 0.3`, use the straight sum of that chunk's cleaned points instead and mark the trip `gps_sum`.
- Keep `geometry` of each matching. Concatenate them for `route_polyline`.

### 4.4 Bridge the gaps (OSRM `route` service)

```
GET {OSRM}/route/v1/driving/{lngA},{latA};{lngB},{latB}?overview=full&geometries=polyline6
```

Add `routes[0].distance`. Record the gap for the report (section 5).

### 4.5 Total
```
distance_km = round((Σ chunk distances + Σ gap route distances) / 1000, 2)
```
Store it with `distance_method`, `route_polyline`, `points_used`, `distance_status = done`, `distance_calculated_at = now()`.

**Fallback:** if a trip has fewer than 2 usable points, route start → visits (by visit time) → end with OSRM `route` and mark it `stops_only`. Never multiply a straight line by 1.3.

### 4.6 Late points
If `SaveTripLocations` receives points for a trip that is already ended, recalculate that trip, at most once per minute per trip.

### 4.7 OSRM server
- `router.project-osrm.org` (used by the app today to draw lines) is a **demo server** with rate limits and no uptime guarantee. Don't use it for production calculations.
- Recommended: **self-host OSRM** (open source) with the India extract from Geofabrik, car profile. Expose `/match` and `/route` only to the backend.
- Alternatives: Google Roads API (Snap to Roads) or Mapbox Map Matching. Both are paid, so check their current pricing and per-request point limits.

---

## 5. Read a trip's route: `GET /api/mobile/GetTripRoute?TripId=456` (new)

Used by Root Tracker (map + distance) and by the app after a `processing` stop.

```json
{
  "status": 1,
  "data": {
    "trip_id": 456,
    "user_id": 123,
    "trip_date": "2026-11-20",
    "start_time": "2026-11-20 09:10:00",
    "end_time": "2026-11-20 15:35:00",
    "distance_km": 42.37,
    "duration_min": 385,
    "distance_status": "done",
    "method": "map_matched",
    "points_used": 1840,
    "polyline": "_p~iF~ps|U_ulLnnqC_mqNvxq`@",
    "polyline_precision": 6,
    "gaps": [
      { "from": "2026-11-20 11:02:10", "to": "2026-11-20 11:20:44", "distance_km": 3.10 }
    ],
    "visits": [
      { "school_name": "ABC Matric", "latitude": 13.0827, "longitude": 80.2707, "visited_at": "2026-11-20 10:05:00" }
    ]
  }
}
```

Access: same hierarchy rule as `GetReportingMembersByHierarchy`. A user sees their own trips and those of people reporting to them, otherwise 403.

---

## 6. Trips list: `GET api/mobile/GetOverallTripDetails?UserId=` (add fields)

Add to **each trip** in the existing response (all other fields unchanged):

```json
{
  "trip_id": 456,
  "...": "existing fields",
  "distance_km": 42.37,
  "distance_status": "done",
  "distance_method": "map_matched"
}
```

The app will show `distance_km` when `distance_status` is `done`. For older trips without it, run a one-time backfill job (section 4 on stored points; `stops_only` when a trip has no points).

---

## 7. Errors

Same as the other mobile APIs: `{ "status": "error", "message": "..." }` with HTTP 400 / 401 / 403 / 404 / 500. The app shows `message`.

---

## 8. App changes once these are live

| App | Change |
|---|---|
| Today Visit START | Save `trip_id` from the response and send it with every batch. |
| GPS batches | Add `accuracy_m`, `speed_mps`, `heading`. Tighten the accuracy filter from 50 m to 30 m. |
| Today Visit END | Upload pending points, call `stop`, show the returned `distance_km`. If `processing`, poll `GetTripRoute` for up to 30 s. |
| Status Report / Root Tracker | Use `distance_km` from `GetOverallTripDetails`. Remove the straight-line ×1.3 calculation. Draw `GetTripRoute.polyline` on the map instead of calling OSRM from the phone. |

---

## 9. Backend test checklist

- [ ] `start` returns `trip_id`. Batches with and without `trip_id` are both stored against the right trip.
- [ ] Resending the same batch stores nothing new (`duplicates` = batch size).
- [ ] A drive along a known road with a known odometer distance: `distance_km` is within ±3 %.
- [ ] Phone switched off for 20 minutes mid-trip: one gap is reported and bridged with a road route.
- [ ] A trip with 0–1 points: `stops_only`, no crash.
- [ ] OSRM down: `stop` still succeeds with `distance_status: failed` or `gps_sum`, and a later retry fills it in.
- [ ] A manager can read team members' routes. Anyone else gets 403.
