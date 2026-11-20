# Ticket Raising API

Backend contract for the app's **Tickets** module (`lib/view/ticket/`). Users raise tickets for app issues. **Admin** and **Support** users see every ticket and change its status. When a ticket is marked **Completed**, the person who raised it is notified.

The app runs in **demo mode** (tickets stored on the phone only) until this API is live. To switch it on, set `kTicketsUseApi = true` in `lib/viewModel/ticket_viewmodel.dart`.

- Base URL: VIMS (`AppUrl.vimsUrl`, e.g. `http://score.savyasasy.com/`)
- Every request sends `Authorization: Bearer <login token>` and JSON bodies.
- Errors: `{ "status": "error", "message": "..." }` with HTTP 400 / 401 / 403 / 404 / 500, same as the other mobile APIs. The app shows `message` to the user.
- Who has access is decided **on the server** from the token's role (`roleCode` `Admin` or `Support`). The app also hides the status buttons for other roles, but the server must still enforce it.

## Values

| Field | Allowed values |
|---|---|
| `status` | `Open`, `InProgress`, `Completed` |
| `priority` | `Low`, `Medium`, `High` |
| `app` | The company app with the issue. The app sends one of: `School Chimes`, `Gradit`, `Let's Reach`, `SSS Score`, `Other` |
| `attachments[].type` | `image`, `video` |

Dates are ISO-8601 UTC, e.g. `2026-11-20T07:30:00.000Z`.

## Ticket object

```json
{
  "id": 15,
  "app": "School Chimes",
  "description": "Circular not reaching parents. School: ABC Matric.",
  "priority": "High",
  "status": "InProgress",
  "raisedById": 120,
  "raisedByName": "Ravi",
  "attachments": [
    { "url": "https://<bucket>.s3.amazonaws.com/tickets/score_1763623800000.jpg", "type": "image" },
    { "url": "https://<bucket>.s3.amazonaws.com/tickets/score_1763623805000.mp4", "type": "video" }
  ],
  "platform": "android 14",
  "createdAt": "2026-11-20T07:30:00.000Z",
  "updatedAt": "2026-11-20T09:10:00.000Z",
  "history": [
    { "status": "Open", "note": "", "byName": "Ravi", "at": "2026-11-20T07:30:00.000Z" },
    { "status": "InProgress", "note": "Checking the API", "byName": "Support Team", "at": "2026-11-20T09:10:00.000Z" }
  ]
}
```

`history` is the status timeline, oldest first. The server adds an entry on create and on every status change.

## 1. Tickets: list

`GET api/mobile/tickets?scope=mine|all`

- `scope=mine`: tickets raised by the logged-in user.
- `scope=all`: every ticket. Only Admin / Support may ask for this. For other roles, return only their own tickets (or 403).

Response:

```json
{ "status": "success", "data": [ { ...ticket }, { ...ticket } ] }
```

Newest first is preferred, but the app also sorts by `createdAt`.

## 2. Ticket: raise

`POST api/mobile/tickets`

Any logged-in user. Images and videos (up to 5; video up to 3 min / 50 MB, `video/mp4` or `video/quicktime`) are uploaded by the app to S3 first (same presigned-URL flow as other uploads, folder `tickets/`), and only their URLs are sent. The presigned-URL API must accept these video content types.

```json
{
  "app": "School Chimes",
  "description": "Circular not reaching parents.",
  "priority": "High",
  "attachments": [
    { "url": "https://.../tickets/score_1763623800000.jpg", "type": "image" },
    { "url": "https://.../tickets/score_1763623805000.mp4", "type": "video" }
  ],
  "platform": "android 14",
  "deviceName": "Redmi Note 12",
  "deviceModel": "Android 14"
}
```

`app` and `description` are required. `deviceName` / `deviceModel` are optional, typed by the user (the phone where the issue happened). `platform` is detected automatically. Return all three on ticket objects. The server sets `status = Open`, `raisedById` and `raisedByName` from the token, and the first `history` entry.

Response: `{ "status": "success", "message": "Ticket raised", "data": { ...ticket } }`

Optional: notify Admin / Support of the new ticket (push or email).

## 3. Ticket: change status (Admin / Support)

`PUT api/mobile/tickets/:id/status`

```json
{ "status": "Completed", "note": "Fixed in version 1.0.1" }
```

- `note` is optional. The app shows it to the user in the timeline and in the notification.
- Any status may follow any other (e.g. `Completed` → `Open` reopens).
- 403 if the caller is not Admin / Support.

Response: `{ "status": "success", "message": "Status updated", "data": { ...ticket } }`

**When the new status is `Completed`**, send a push to the ticket's `raisedById` (see 4):

```json
{
  "notification": { "title": "Ticket completed #15", "body": "School Chimes · Circular not reaching parents · Fixed in version 1.0.1" },
  "data": { "type": "ticket", "ticketId": "15" }
}
```

## 3a. Assign a ticket: `PUT api/mobile/tickets/:id/assign`

**Anyone** logged in may assign any ticket to anyone (or unassign).

```json
{ "assignedToId": "45" }
```

`""` unassigns. Response: `{ "status": "success", "message": "Ticket assigned", "data": { ...ticket } }`.

- Store `assignedToId` / `assignedToName` on the ticket and add a history entry `{ "event": "assign", "assignedToName": "Kavin Kumar", "byName": "<caller>", "at": "..." }`. Status-change entries carry `"event": "status"`.
- The **assignee** may also change the status (section 3) in addition to Admin / Support.
- Send the assignee a push: `{ "notification": { "title": "Ticket assigned to you #15", "body": "School Chimes · …" }, "data": { "type": "ticket", "ticketId": "15" } }`.
- `POST api/mobile/tickets` (section 2) accepts an optional `"assignedToId"` too.

## 3b. People to assign: `GET api/mobile/tickets/assignees`

```json
{ "status": "success", "data": [ { "id": 45, "name": "Kavin Kumar" } ] }
```

Who appears is up to the backend (e.g. all active employees). If this API is missing or empty, the app falls back to `GetReportingMembersByHierarchy`.

`GET api/mobile/tickets?scope=mine` must return tickets the user **raised or is assigned to**. Ticket objects carry `"assignedToId"` and `"assignedToName"` (empty when unassigned).

## 4. Device token for push (Firebase FCM, phase 2)

`POST api/mobile/tickets/device-token`

```json
{ "fcmToken": "<FCM registration token>", "platform": "android" }
```

Store the token per user (a user may have several devices) and remove it when FCM reports it as invalid. This endpoint is not used yet: the app has no Firebase setup. Until it has, the app checks the user's tickets whenever it is opened or brought back to the foreground and shows a local notification for any ticket that became Completed since the last check. FCM push adds delivery while the app is closed. The app-side check stays as a fallback.

## App-side summary

| Screen | Call |
|---|---|
| Tickets list (pull to refresh, dashboard badge, completion check) | `GET api/mobile/tickets?scope=...` |
| Raise Ticket → Submit | S3 upload of each image / video → `POST api/mobile/tickets` |
| Ticket detail → Mark In Progress / Completed / Reopen | `PUT api/mobile/tickets/:id/status` |
| Raise form step 5 / Ticket detail → Assign / Change | `GET api/mobile/tickets/assignees` → `PUT api/mobile/tickets/:id/assign` |
| (phase 2) after login | `POST api/mobile/tickets/device-token` |
