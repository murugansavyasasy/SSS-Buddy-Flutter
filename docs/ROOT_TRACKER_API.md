# Root Tracker — backend APIs

The app records GPS points from the moment a user taps **START** in Today Visit
until **END DAY**. It uploads them in batches (every 20 points or 2 minutes,
plus once on END). Until these two APIs exist, points stay queued on the phone
and are resent automatically, so nothing is lost.

Both live on the VIMS base URL (`http://score.savyasasy.com/`) with the usual
`Authorization: Bearer <token>` header.

## 1. Save points — `POST /api/mobile/SaveTripLocations`

```json
{
  "user_id": "123",
  "trip_date": "2026-11-05",
  "points": [
    { "latitude": 13.0827, "longitude": 80.2707, "recorded_at": "2026-11-05 09:14:03", "segment": 0 },
    { "latitude": 13.0835, "longitude": 80.2712, "recorded_at": "2026-11-05 09:14:21", "segment": 0 }
  ]
}
```

- `recorded_at` is the phone's local time (IST), `yyyy-MM-dd HH:mm:ss`.
- `segment` increases each time the user starts a new trip on the same day.
- A batch can be resent after a network failure, so ignore exact duplicates
  (same `user_id` + `recorded_at` + lat/lng).
- Response: `{ "status": 1 }` on success. Any other value, or a non-200
  response, makes the app retry later.

Suggested table: `trip_locations(id, user_id, trip_date, latitude, longitude, recorded_at, segment)`
with an index on `(user_id, trip_date)`.

## 2. Get points — `GET /api/mobile/GetTripLocations?UserId=123&Date=2026-11-05`

Returns the day's points, oldest first, as a plain array (or `{ "data": [...] }`):

```json
[
  { "latitude": 13.0827, "longitude": 80.2707, "recorded_at": "2026-11-05 09:14:03", "segment": 0 }
]
```

Only return data for users the caller is allowed to see, using the same
hierarchy as `GetReportingMembersByHierarchy`.
