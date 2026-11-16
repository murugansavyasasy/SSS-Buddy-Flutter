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
                title: 'Entered today',
                members: status.present,
              ),

            // Members who have NOT entered today.
            if (status.absent.isNotEmpty)
              _EntrySection(
                tone: _Tone.danger,
                icon: Icons.event_busy_rounded,
                title: 'No entry today',
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
          bg: const Color(0xFFF1F8F2),
          border: const Color(0xFFCDE8D1),
          fg: const Color(0xFF2E7D32),
          chipBg: Colors.white,
          chipAvatarBg: const Color(0xFFDCEFDF),
        );
      case _Tone.danger:
        return _ToneColors(
          bg: const Color(0xFFFDF3F3),
          border: const Color(0xFFF3D0D0),
          fg: const Color(0xFFC62828),
          chipBg: Colors.white,
          chipAvatarBg: const Color(0xFFFBE0E0),
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
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.chipAvatarBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: colors.fg),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.fg,
                  ),
                ),
              ),
              // Member count badge
              Container(
                constraints: const BoxConstraints(minWidth: 26),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.fg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${members.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
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
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colors.chipAvatarBg,
            child: Text(
              initial,
              style: TextStyle(
                color: colors.fg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
