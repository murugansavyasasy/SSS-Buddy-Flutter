import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/ReportingMembersModel.dart';
import '../auth/model/TrackPointModel.dart';
import '../components/MemberDropdown.dart';
import '../components/TripRouteMap.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/login_view_model.dart';
import '../viewModel/reporting_members_dd_viewmodel.dart';
import '../viewModel/root_tracker_viewmodel.dart';
import '../viewModel/today_visit_viewmodal.dart';
import 'dashboard.dart';

/// Root Tracker: the route a member travelled after tapping START in
/// Today Visit — a pin on every lat/long and the path between them —
/// with the km covered.
class RootTrackerScreen extends ConsumerStatefulWidget {
  /// Optional: open straight on a member/date (e.g. from Status Report).
  final Reportingmembersmodel? initialMember;
  final DateTime? initialDate;

  const RootTrackerScreen({super.key, this.initialMember, this.initialDate});

  @override
  ConsumerState<RootTrackerScreen> createState() => _RootTrackerScreenState();
}

class _RootTrackerScreenState extends ConsumerState<RootTrackerScreen> {
  static const Color _green = Color(0xFF188038);
  static const Color _red = Color(0xFFEA4335);
  static const Color _ink = Color(0xFF1A1F36);
  static const Color _muted = Color(0xFF8A94A6);

  final GlobalKey<TripRouteMapState> _mapKey = GlobalKey();
  Reportingmembersmodel? _member;
  late DateTime _date = widget.initialDate ?? DateTime.now();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final first = widget.initialMember ?? _self();
      if (first != null && _member == null) _select(first);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Reportingmembersmodel? _self() {
    final login = ref.read(loginProvider).value;
    if (login == null) return null;
    return Reportingmembersmodel(
      idmember: login.userId,
      membername: "${login.name} (Me)",
      usertype: login.roleId,
    );
  }

  bool get _isToday => DateUtils.isSameDay(_date, DateTime.now());

  void _select(Reportingmembersmodel member, {DateTime? date}) {
    setState(() {
      _member = member;
      if (date != null) _date = date;
    });
    _load();
    _refreshTimer?.cancel();
    // Today's route keeps growing – poll the server every 30 s.
    if (_isToday) {
      _refreshTimer = Timer.periodic(
          const Duration(seconds: 30), (_) => _load(silent: true));
    }
  }

  Future<void> _load({bool silent = false}) async {
    final m = _member;
    if (m == null) return;
    await ref
        .read(rootTrackerProvider.notifier)
        .load(memberId: m.idmember, date: _date, silent: silent);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && _member != null) _select(_member!, date: picked);
  }

  List<Reportingmembersmodel> _members() {
    final team = ref.watch(reportingmembersProvider).value ?? const [];
    final me = _self();
    final list = <Reportingmembersmodel>[
      if (me != null) me,
      ...team.where((m) => m.idmember != me?.idmember),
    ];
    // Member opened from Status Report but not in the list yet.
    final init = widget.initialMember;
    if (init != null && !list.any((m) => m.idmember == init.idmember)) {
      list.add(init);
    }
    return list;
  }

  /// For your own live trip, use the in-memory log so the line grows with
  /// every GPS fix instead of waiting for the 30 s refresh.
  List<TrackPoint> _pointsFor(RootTrackerData data) {
    if (data.isSelf && data.isToday) {
      final live = ref.read(todayVisitProvider.notifier).trackLog;
      if (live.length >= data.points.length) return live;
    }
    return data.points;
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(rootTrackerProvider);
    ref.watch(todayVisitProvider); // rebuild on each live GPS fix
    final members = _members();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: "Root Tracker",
              navigateTo: widget.initialMember == null ? const Dashboard() : null,
              onBackPressed: widget.initialMember == null
                  ? null
                  : () => Navigator.pop(context),
              onRefresh: () => _load(),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFilters(members),
                    Expanded(
                      child: async.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _buildError(e),
                        data: (data) => data == null
                            ? const Center(child: CircularProgressIndicator())
                            : _buildMapArea(data),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(List<Reportingmembersmodel> members) {
    final selected =
        members.where((m) => m.idmember == _member?.idmember).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: members.length <= 1
                ? _pill(Icons.person_rounded, _member?.membername ?? "Me")
                : MemberDropdown(
                    members: members,
                    selected: selected,
                    onChanged: (m) {
                      if (m != null) _select(m);
                    },
                  ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _pickDate,
            child: _pill(
              Icons.calendar_today_rounded,
              _isToday ? "Today" : DateFormat('dd MMM yyyy').format(_date),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44, color: _muted),
            const SizedBox(height: 12),
            Text("Couldn't load the route\n$e",
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea(RootTrackerData data) {
    final points = _pointsFor(data);
    final live = data.isToday && data.tripRunning;
    final noTrip = !data.hasTrip && points.isEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: TripRouteMap(
            key: _mapKey,
            trips: data.trips,
            track: points,
            live: live,
            fitPadding: const EdgeInsets.fromLTRB(50, 60, 60, 230),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _mapButton(Icons.add, () => _mapKey.currentState?.zoomBy(1)),
              const SizedBox(height: 6),
              _mapButton(Icons.remove, () => _mapKey.currentState?.zoomBy(-1)),
              const SizedBox(height: 6),
              _mapButton(Icons.center_focus_strong_rounded,
                  () => _mapKey.currentState?.fit()),
            ],
          ),
        ),
        if (noTrip)
          _banner(Icons.info_outline_rounded,
              "No trip on this day. Tap START in Today Visit to begin tracking."),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildStats(data, points, live),
        ),
      ],
    );
  }

  Widget _banner(IconData icon, String text) {
    return Positioned(
      top: 12,
      left: 12,
      right: 64,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _muted),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 12, color: _ink))),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(
      RootTrackerData data, List<TrackPoint> points, bool live) {
    // Real GPS line when we have one; otherwise the Status Report estimate.
    final usingGps = points.length >= 2;
    final km = usingGps ? TrackPoint.totalKm(points) : data.reportKm;

    final startTime = points.isNotEmpty ? points.first.time : data.firstStart;
    final lastTime = points.isNotEmpty ? points.last.time : null;
    final fmt = DateFormat('hh:mm a');

    String duration = "--";
    if (startTime != null && (live || lastTime != null)) {
      final until = live ? DateTime.now() : lastTime!;
      final d = until.difference(startTime);
      if (!d.isNegative) {
        duration =
            "${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m";
      }
    }

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(km.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(usingGps ? "km travelled (GPS)" : "km (approx.)",
                    style: const TextStyle(fontSize: 13, color: _muted)),
              ),
              const Spacer(),
              _statusChip(live, data.hasTrip || points.isNotEmpty),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat("Started",
                  startTime == null ? "--" : fmt.format(startTime)),
              _stat(live ? "Last update" : "Last point",
                  lastTime == null ? "--" : fmt.format(lastTime)),
              _stat("Duration", duration),
              _stat("Visits", "${data.visitCount}"),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _Legend(color: _green, label: "S  Start"),
              SizedBox(width: 14),
              _Legend(color: _red, label: "1 2 3  Visits"),
              SizedBox(width: 14),
              _Legend(color: Color(0xFF3C4043), label: "E  End"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool live, bool hasTrip) {
    final label = live ? "LIVE" : (hasTrip ? "ENDED" : "NO TRIP");
    final color = live ? _green : (hasTrip ? _muted : _red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: color)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
            width: 40, height: 40, child: Icon(icon, size: 20, color: _ink)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6))),
      ],
    );
  }
}
