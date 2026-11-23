# Team Work API

Backend contract for the app's **Team Work** module (`lib/view/teamwork/`): the team lead (**Admin**) creates projects with modules and milestones, assigns tasks to developers and posts announcements. Developers (`roleCode: "Developer"`) get a Developer Dashboard instead of the sales dashboard. They see the tasks assigned to them, move them forward, and appear on a leaderboard scored by tasks and milestones.

The app runs in **demo mode** (data stored on the phone only) until this API is live. To switch it on, set `kTeamWorkUseApi = true` in `lib/viewModel/teamwork_viewmodel.dart`.

The module only exists on the `Chanthru` branch (`kTeamWorkEnabled` in `lib/core/feature_flags.dart`).

- Base URL: VIMS (`AppUrl.vimsUrl`)
- Every request sends `Authorization: Bearer <login token>` and JSON bodies.
- Errors: `{ "status": "error", "message": "..." }` with HTTP 400 / 401 / 403 / 404 / 500. The app shows `message` to the user.
- **Roles are enforced on the server** from the token:
  - `roleCode` `Admin`: everything.
  - `roleCode` `Developer`: read projects, read and update their own tasks, read announcements.
- **Login:** developer users must come back from `api/mobile/login` with `"roleCode": "Developer"`. That is what sends them to the Developer Dashboard.

## Values

| Field | Allowed values |
|---|---|
| task `status` | `Todo`, `InProgress`, `InReview`, `Done` |
| task `priority` | `Low`, `Medium`, `High` |
| history `event` | `created`, `assign`, `status`, `note` |

Dates are ISO-8601 UTC (`2026-11-23T07:30:00.000Z`). `startDate` / `dueDate` are dates; the app sends midnight local time converted to UTC.

## Objects

### Project
```json
{
  "id": "12",
  "name": "SSS Score App",
  "description": "Field sales app",
  "color": "#2563EB",
  "modules": [ { "id": "31", "name": "Login" }, { "id": "32", "name": "Reports" } ],
  "milestones": [
    { "id": "51", "title": "Beta release", "dueDate": "2026-12-05T00:00:00.000Z", "completedAt": null }
  ],
  "createdAt": "2026-11-23T07:30:00.000Z"
}
```
The **server sets `milestones[].completedAt`** when every task linked to the milestone is `Done`, and clears it when any of them is reopened.

### Task
```json
{
  "id": "905",
  "projectId": "12",
  "moduleId": "31",
  "milestoneId": "51",
  "title": "OTP screen API integration",
  "description": "Use api/mobile/otp; show resend after 30 s",
  "priority": "High",
  "status": "InProgress",
  "assigneeId": "120",
  "assigneeName": "Kavin",
  "assignedById": "7",
  "assignedByName": "Murugan",
  "startDate": "2026-11-23T00:00:00.000Z",
  "dueDate": "2026-11-26T00:00:00.000Z",
  "completedAt": null,
  "createdAt": "2026-11-23T07:30:00.000Z",
  "updatedAt": "2026-11-23T09:10:00.000Z",
  "history": [
    { "event": "created", "status": "Todo", "byName": "Murugan", "at": "2026-11-23T07:30:00.000Z" },
    { "event": "assign", "status": "Todo", "byName": "Murugan", "assignedToName": "Kavin", "at": "2026-11-23T07:30:00.000Z" },
    { "event": "status", "status": "InProgress", "note": "Started", "byName": "Kavin", "at": "2026-11-23T09:10:00.000Z" }
  ]
}
```
`history` is the task timeline, oldest first. The server appends an entry for every create, assign, status change and note. `completedAt` is set when the status becomes `Done` and cleared otherwise.

### Announcement
```json
{ "id": "77", "title": "Release on Friday", "body": "Code freeze at 5 PM.", "important": true, "byName": "Murugan", "createdAt": "2026-11-23T07:30:00.000Z" }
```

## Endpoints

| Method & path | Who | Body | Response |
|---|---|---|---|
| `GET api/mobile/team/projects` | all | — | `{ "status": "success", "projects": [Project] }` |
| `POST api/mobile/team/projects` | Admin | Project without `id` (module/milestone `id` empty for new ones) | `{ "status": "success", "project": Project }` |
| `PUT api/mobile/team/projects/:id` | Admin | Project without `id`; modules/milestones with an `id` are updated, without one are created, missing ones removed | `{ "status": "success", "project": Project }` |
| `GET api/mobile/team/tasks?scope=all\|mine` | `all`: Admin (Developers also call it for the leaderboard; return every task, `history` may be omitted). `mine`: tasks assigned to the caller | — | `{ "status": "success", "tasks": [Task] }` |
| `POST api/mobile/team/tasks` | Admin | `projectId, moduleId, milestoneId?, title, description, priority, assigneeId, assigneeName, startDate, dueDate` | `{ "status": "success", "task": Task }` |
| `PUT api/mobile/team/tasks/:id/status` | assignee: `Todo→InProgress→InReview`; Admin: any (approve `Done`, send back, reopen) | `{ "status": "InReview", "note": "" }` | `{ "status": "success", "task": Task }` |
| `PUT api/mobile/team/tasks/:id/assign` | Admin | `{ "assigneeId": "121", "assigneeName": "Saran" }` | `{ "status": "success", "task": Task }` |
| `POST api/mobile/team/tasks/:id/notes` | Admin, assignee | `{ "note": "API ready on staging" }` | `{ "status": "success", "task": Task }` |
| `GET api/mobile/team/members` | Admin | — | `{ "status": "success", "members": [ { "id": "120", "name": "Kavin" } ] }`: people tasks can be assigned to (developers). If empty, the app falls back to the Admin's reporting members. |
| `GET api/mobile/team/announcements` | all | — | `{ "status": "success", "announcements": [Announcement] }` |
| `POST api/mobile/team/announcements` | Admin | `{ "title", "body", "important" }` | `{ "status": "success", "announcement": Announcement }` |

## Leaderboard (computed in the app)

The app ranks developers itself from `GET tasks?scope=all` and `GET projects`, for This Week / This Month / This Quarter:

- Done task: **High 15, Medium 10, Low 5** points.
- Finished on or before `dueDate`: **+5**. Late: **−3**, never below 2.
- Milestone completed in the period: **+20** to every developer with a task in it.
- Equal points share a rank.

## Notifications

Until push is available, the app shows local notifications when it opens or resumes:
- "Task assigned to you" for new task ids in `scope=mine`
- each new announcement

A later FCM push can reuse the payloads `task:<taskId>` and `announcement:<id>`.
