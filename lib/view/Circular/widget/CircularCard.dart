import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/model/CircularModel.dart';
import '../../../viewModel/circular_audio_viewmodel.dart';
import 'VoicePlayerDialog.dart';
import 'stat-chip.dart';

class Circularcard extends ConsumerWidget {
  final Circularmodel item;
  const Circularcard({super.key, required this.item});

  String get _messageLabel {
    final raw = item.MessageId;
    final afterDash = raw.contains('--') ? raw.split('--')[1] : raw;
    final beforeTilde = afterDash.contains('~~')
        ? afterDash.split('~~')[0]
        : afterDash;
    return beforeTilde.trim();
  }

  Color get _messageColor {
    switch (_messageLabel.toLowerCase()) {
      case 'management':
        return const Color(0xFF1A3A5C);
      case 'absentees call':
        return Colors.orange.shade700;
      case 'staff call':
        return Colors.teal.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  /// Attended-to-total ratio used by the progress bar (0.0 – 1.0).
  double get _attendRate {
    final total = int.tryParse(item.TotalCalls.trim()) ??
        (item.Connected + item.Missed + item.Requested);
    if (total <= 0) return 0;
    return (item.Connected / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _messageColor;
    final rate = _attendRate;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(0.13),
                  accent.withOpacity(0.03),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.SchoolName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2530),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _messageLabel,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.voiceFile.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _VoicePlayButton(
                    url: item.voiceFile,
                    title: item.SchoolName,
                    color: accent,
                  ),
                ],
              ],
            ),
          ),

          // ── BODY ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MetaChip(
                      icon: Icons.tag_rounded,
                      text: 'ID ${item.SchoolId}',
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _MetaChip(
                        icon: Icons.access_time_rounded,
                        text: item.Time,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Connection-rate progress
                Row(
                  children: [
                    Icon(Icons.call_rounded, size: 14, color: accent),
                    const SizedBox(width: 6),
                    const Text(
                      'Total Calls',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.TotalCalls,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2530),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEEF1F4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.Connected} attended · ${(rate * 100).round()}% reach',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9099A3),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: StatChip(
                        label: 'In Progress',
                        value: item.Requested.toString(),
                        color: Colors.orange.shade600,
                        icon: Icons.pending_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatChip(
                        label: 'Attended',
                        value: item.Connected.toString(),
                        color: Colors.green.shade600,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatChip(
                        label: 'Missed',
                        value: item.Missed.toString(),
                        color: Colors.red.shade400,
                        icon: Icons.call_missed_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _ExpandableMessageId(text: item.MessageId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill showing a piece of metadata (ID, time) with a leading icon.
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7A828C)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoicePlayButton extends ConsumerWidget {
  final String url;
  final String title;
  final Color color;

  const _VoicePlayButton({
    required this.url,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(circularAudioProvider);
    final isActive = audio.currentUrl == url;
    final isLoading = isActive && audio.isLoading;
    final isPlaying = isActive && audio.isPlaying;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await VoicePlayerDialog.show(
            context,
            url: url,
            title: title,
            color: color,
          );
          // Stop playback when the popup is dismissed.
          await ref.read(circularAudioProvider.notifier).pause();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
              const SizedBox(width: 3),
              Text(
                isPlaying ? 'Playing' : 'Play',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableMessageId extends StatefulWidget {
  final String text;
  const _ExpandableMessageId({required this.text});

  @override
  State<_ExpandableMessageId> createState() => _ExpandableMessageIdState();
}

class _ExpandableMessageIdState extends State<_ExpandableMessageId> {
  final GlobalKey _textKey = GlobalKey();
  bool _isOverflowing = false;

  static const TextStyle _style = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
    height: 1.3,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant _ExpandableMessageId oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is RenderParagraph) {
      final exceeded = renderObject.didExceedMaxLines;
      if (exceeded != _isOverflowing && mounted) {
        setState(() => _isOverflowing = exceeded);
      }
    }
  }

  void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Message ID',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(widget.text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E3E7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            key: _textKey,
            style: _style,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (_isOverflowing) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showPopup(context),
              child: const Text(
                'See more',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}