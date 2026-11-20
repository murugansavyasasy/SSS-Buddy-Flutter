import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/model/Demolist.dart';
import '../auth/model/ExhibitionModel.dart' show formatIndianMobile;
import '../auth/model/FollowUpModel.dart';
import '../utils/routes/routes_name.dart';
import 'app_motion.dart';
import 'demo_video_whatsapp.dart';
import 'glass_card.dart';

/// One demo in the Demo List: school, principal number (tap to call) and a
/// compact action row — Record voice, WhatsApp demo video, Edit.
class DemoCard extends StatelessWidget {
  /// Follow-ups are hidden app-wide for now; flip to bring the button back.
  static const bool _showFollowUp = false;

  final Demolist item;
  const DemoCard({super.key, required this.item});

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF16A34A),
  ];

  /// Same school, same colour.
  Color get _tone => _palette[item.schoolName.hashCode.abs() % _palette.length];

  String get _initials {
    final words = item.schoolName
        .replaceAll(RegExp(r"[^A-Za-z0-9 ]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String get _number => item.principalNumber == 0 ? '' : item.principalNumber.toString();

  Future<void> _call() async {
    if (_number.isEmpty) return;
    HapticFeedback.selectionClick();
    await launchUrl(Uri(scheme: 'tel', path: _number));
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── School ──
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: homePastelGradient(tone),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tone.withValues(alpha: 0.15)),
                ),
                child: Text(_initials,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: homeDeep(tone))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.schoolName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: HomeGlass.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DEMO #${item.demoId}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: HomeGlass.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Principal (tap to call) ──
          if (_number.isNotEmpty)
            Material(
              color: homePastel(HomeGlass.green),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _call,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.call_rounded, size: 16, color: homeDeep(HomeGlass.green)),
                      const SizedBox(width: 8),
                      Text('Principal',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: homeDeep(HomeGlass.green).withValues(alpha: 0.8))),
                      const Spacer(),
                      Text(
                        formatIndianMobile(_number),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: homeDeep(HomeGlass.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.mic_rounded,
                  label: 'Record',
                  filled: true,
                  color: HomeGlass.navy,
                  onTap: () => Navigator.pushNamed(context, RoutesName.recordvoice, arguments: item),
                ),
              ),
              if (canSendDemoVideoTo(_number)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.ondemand_video_rounded,
                    label: 'Video',
                    color: HomeGlass.green,
                    onTap: () => sendSchoolDemoVideoOnWhatsApp(
                      context,
                      number: _number,
                      schoolName: item.schoolName,
                    ),
                  ),
                ),
              ],
              if (_showFollowUp) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.event_note_rounded,
                    label: 'Follow-up',
                    color: HomeGlass.orange,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RoutesName.followupform,
                      arguments: FollowUpFormArgs(
                        schoolName: item.schoolName,
                        contactPhone: _number,
                        demoId: item.demoId.toString(),
                        type: FollowUpType.call,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: HomeGlass.blue,
                  onTap: () => Navigator.pushNamed(context, RoutesName.demoedit, arguments: item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : homeDeep(color);
    return PressableScale(
      pressedScale: 0.94,
      child: Material(
        color: filled ? color : homePastel(color),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
