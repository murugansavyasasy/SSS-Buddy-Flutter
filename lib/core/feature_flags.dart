import '../auth/model/TeamWorkModel.dart';
import '../utils/routes/routes_name.dart';

/// Team Work (Developer Dashboard, tasks, projects, announcements, developer
/// leaderboard). Lives on the Chanthru branch only: keep this false on
/// Development (set it in the merge commit), which also hides menu id 25.
const bool kTeamWorkEnabled = true;

/// Home screen after login / session restore: developers get the Team Work
/// Developer Dashboard (only while [kTeamWorkEnabled]); everyone else the
/// normal dashboard.
String homeRouteFor(String? roleCode) =>
    kTeamWorkEnabled && isDeveloperRole(roleCode ?? '') ? RoutesName.devDashboard : RoutesName.dashboard;
