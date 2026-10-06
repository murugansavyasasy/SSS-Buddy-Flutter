import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/ReportingMembersModel.dart';
import '../viewModel/today_absentees_viewmodel.dart';

/// Shown at the top of the Reports screen: two horizontally scrolling chip rows
/// naming the members who HAVE an entry for the current day (green) and those
/// who have NOT (red).
class TodayEntryBar extends ConsumerWidget {
  const TodayEntryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(todayEntryStatusProvider);

    return statusAsync.when(
      loading: () => const _Shell(
        tone: _Tone.neutral,
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Checking today\'s entries…',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            // Members who HAVE entered today.
            if (status.present.isNotEmpty)
              _EntrySection(
                tone: _Tone.success,
                icon: Icons.check_circle_rounded,
                title: 'Entered today (${status.present.length})',
                members: status.present,
              ),

            // Members who have NOT entered today.
            if (status.absent.isNotEmpty)
              _EntrySection(
                tone: _Tone.danger,
                icon: Icons.event_busy_rounded,
                title: 'No entry today (${status.absent.length})',
                members: status.absent,
              ),
          ],
        );
      },
    );
  }
}

enum _Tone { success, danger, neutral }

class _ToneColors {
  final Color bg;
  final Color border;
  final Color fg;
  final Color chipBg;
  final Color chipAvatarBg;

  const _ToneColors({
    required this.bg,
    required this.border,
    required this.fg,
    required this.chipBg,
    required this.chipAvatarBg,
  });

  static _ToneColors of(_Tone tone) {
    switch (tone) {
      case _Tone.success:
        return _ToneColors(
          bg: const Color(0xFFE8F5E9),
          border: const Color(0xFFA5D6A7),
          fg: const Color(0xFF2E7D32),
          chipBg: Colors.white,
          chipAvatarBg: const Color(0xFFC8E6C9),
        );
      case _Tone.danger:
        return _ToneColors(
          bg: const Color(0xFFFFEBEE),
          border: const Color(0xFFEF9A9A),
          fg: const Color(0xFFC62828),
          chipBg: Colors.white,
          chipAvatarBg: const Color(0xFFFFCDD2),
        );
      case _Tone.neutral:
        return _ToneColors(
          bg: const Color(0xFFF5F5F5),
          border: const Color(0xFFE0E0E0),
          fg: const Color(0xFF616161),
          chipBg: Colors.white,
          chipAvatarBg: const Color(0xFFEEEEEE),
        );
    }
  }
}

/// A titled section with a scrolling row of member chips.
class _EntrySection extends StatelessWidget {
  final _Tone tone;
  final IconData icon;
  final String title;
  final List<Reportingmembersmodel> members;

  const _EntrySection({
    required this.tone,
    required this.icon,
    required this.title,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ToneColors.of(tone);

    return _Shell(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.fg),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in members)
                  _MemberChip(member: m, colors: colors),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared container styling for each section / the loading row.
class _Shell extends StatelessWidget {
  final Widget child;
  final _Tone tone;

  const _Shell({required this.child, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = _ToneColors.of(tone);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 3, 16, 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class _MemberChip extends StatelessWidget {
  final Reportingmembersmodel member;
  final _ToneColors colors;

  const _MemberChip({required this.member, required this.colors});

  @override
  Widget build(BuildContext context) {
    final name = member.membername;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: colors.chipAvatarBg,
            child: Text(
              initial,
              style: TextStyle(
                color: colors.fg,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.fg,
            ),
          ),
        ],
      ),
    );
  }
}
