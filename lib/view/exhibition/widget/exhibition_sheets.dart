import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../auth/model/ExhibitionModel.dart';
import '../../../viewModel/exhibition_viewmodel.dart';
import 'exhibition_common.dart';
import 'demo_audio.dart';
import 'voice_recorder_panel.dart';

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder, {bool full = false}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      barrierColor: exInk.withValues(alpha: 0.45),
      constraints: const BoxConstraints(maxWidth: 680),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ExTheme(
        child: full
            ? FractionallySizedBox(heightFactor: 0.92, child: builder(ctx))
            : builder(ctx),
      ),
    );

Widget _handle() => Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: exStrongBorder,
        borderRadius: BorderRadius.circular(3),
      ),
    );

// MARK: - Demo sent: success + "capture a lead?"

/// Ink screen with the success tick, and a sheet asking whether to capture
/// a lead. Returns true for "Yes, capture lead"; false for Skip / swipe down.
Future<bool> showDemoSentSheet(
  BuildContext context, {
  required int callCount,
  String exhibitionName = '',
}) async {
  HapticFeedback.mediumImpact();
  final yes = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: exInk,
    elevation: 0,
    builder: (ctx) => ExTheme(
      child: _DemoSentSheet(callCount: callCount, exhibitionName: exhibitionName),
    ),
  );
  return yes == true;
}

class _DemoSentSheet extends StatelessWidget {
  final int callCount;
  final String exhibitionName;
  const _DemoSentSheet({required this.callCount, required this.exhibitionName});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final sub = [
      '$callCount ${callCount == 1 ? 'call' : 'calls'} queued',
      if (exhibitionName.isNotEmpty) exhibitionName,
    ].join(' · ');
    return SizedBox(
      height: h,
      child: Column(
        children: [
          // ── Success on ink ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: exBrand,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 10,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Demo call initiated',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(sub,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      )),
                ],
              ),
            ),
          ),
          // ── Ask for a lead ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, 16 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _handle()),
                  const SizedBox(height: 22),
                  const Text('Did the visitor like the demo?', style: exHeadingLg),
                  const SizedBox(height: 6),
                  const Text('Capture this school as a lead?',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle)),
                  const SizedBox(height: 24),
                  ExPrimaryButton(
                    label: 'Yes, capture lead',
                    height: 56,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 12),
                  ExSecondaryButton(
                    label: 'Skip',
                    height: 56,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(height: 12),
                  const Text('Swipe down to skip', textAlign: TextAlign.center, style: exBodySm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Capture lead

/// Capture Lead form. With [demo] the lead is linked to that demo; without it
/// the lead is standalone for the exhibition. Returns true when saved.
Future<bool> showCaptureLeadSheet(
  BuildContext context, {
  required String exhibitionId,
  ExhibitionDemo? demo,
  String? prefillContact,
  String? prefillNumber,
  ExhibitionLead? lead,
}) async {
  final saved = await _showSheet<bool>(
    context,
    (ctx) => _CaptureLeadSheet(
      exhibitionId: exhibitionId,
      demo: demo,
      lead: lead,
      prefillContact: prefillContact ?? demo?.visitorName,
      prefillNumber: prefillNumber ?? demo?.firstVisitorNumber,
    ),
    full: true,
  );
  return saved == true;
}

class _CaptureLeadSheet extends ConsumerStatefulWidget {
  final String exhibitionId;
  final ExhibitionDemo? demo;
  final String? prefillContact;
  final String? prefillNumber;

  /// Set when editing an existing lead.
  final ExhibitionLead? lead;

  const _CaptureLeadSheet({
    required this.exhibitionId,
    this.demo,
    this.lead,
    this.prefillContact,
    this.prefillNumber,
  });

  @override
  ConsumerState<_CaptureLeadSheet> createState() => _CaptureLeadSheetState();
}

class _CaptureLeadSheetState extends ConsumerState<_CaptureLeadSheet> {
  late final _school = TextEditingController(text: widget.lead?.schoolName ?? '');
  late final _city = TextEditingController(text: widget.lead?.city ?? '');
  late final _contact =
      TextEditingController(text: widget.lead?.contactName ?? widget.prefillContact ?? '');
  late final _number =
      TextEditingController(text: widget.lead?.contactNumber ?? widget.prefillNumber ?? '');
  late final _email = TextEditingController(text: widget.lead?.contactEmail ?? '');
  late final _notes = TextEditingController(text: widget.lead?.notes ?? '');
  late InterestLevel _level = widget.lead?.interestLevel ?? InterestLevel.warm;

  bool get _editing => widget.lead != null;
  bool _tried = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_school, _city, _contact, _number, _email, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _numberError {
    final n = _number.text.trim();
    if (!_tried) return null;
    if (n.isEmpty) return 'Contact number is required';
    return isValidIndianMobile(normalizeIndianMobile(n)) ? null : 'Enter a 10-digit mobile number';
  }

  String? get _emailError {
    final e = _email.text.trim();
    if (!_tried) return null;
    if (e.isEmpty) return 'Contact email is required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e) ? null : 'Enter a valid email';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _error = null;
    });
    if (_school.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _numberError != null ||
        _emailError != null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final req = CaptureLeadRequest(
        schoolName: _school.text.trim(),
        city: _city.text.trim(),
        contactName: _contact.text.trim(),
        contactNumber: normalizeIndianMobile(_number.text.trim()),
        contactEmail: _email.text.trim(),
        notes: _notes.text.trim(),
        interestLevel: _level,
      );
      final repo = ref.read(exhibitionRepositoryProvider);
      if (_editing) {
        await repo.updateLead(widget.lead!.id, req);
      } else {
        await repo.captureLead(
          exhibitionId: widget.exhibitionId,
          demoId: widget.demo?.id,
          req: req,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _levelButton(InterestLevel l) {
    final on = _level == l;
    final (bg, fg) = interestLevelColors(l);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? bg : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _level = l);
          },
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? fg : exStrongBorder, width: on ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(l.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: on ? fg : exInk,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final schoolError = _tried && _school.text.trim().isEmpty ? 'School name is required' : null;
    final cityError = _tried && _city.text.trim().isEmpty ? 'City is required' : null;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    Widget pair(Widget a, Widget b) => wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)],
          )
        : Column(children: [a, const SizedBox(height: 16), b]);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 12, 12),
            child: Column(
              children: [
                _handle(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_editing ? 'Edit lead' : 'Capture lead', style: exHeadingLg),
                          if (!_editing) ...[
                          const SizedBox(height: 8),
                          ExPill(
                            icon: demo == null ? Icons.storefront_outlined : Icons.link_rounded,
                            label: demo == null
                                ? 'Standalone lead'
                                : 'Linked to demo · ${demo.displayName}',
                            background: demo == null ? exNotes : exTint,
                            foreground: demo == null ? exInk : exBrandBold,
                          ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded, color: exInk),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: exBorder),
          // ── Form ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                pair(
                  ExField(
                    label: 'School name',
                    required: true,
                    controller: _school,
                    hint: 'e.g. Green Valley Public School',
                    errorText: schoolError,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_tried) setState(() {});
                    },
                  ),
                  ExField(
                    label: 'City',
                    required: true,
                    controller: _city,
                    hint: 'e.g. Chennai',
                    errorText: cityError,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_tried) setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('Interest level', style: exHeadingSm.copyWith(fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final l in InterestLevel.values) ...[
                      if (l != InterestLevel.values.first) const SizedBox(width: 8),
                      Expanded(child: _levelButton(l)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ExField(
                  label: 'Contact name',
                  controller: _contact,
                  hint: 'Name and role',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                pair(
                  ExField(
                    label: 'Contact number',
                    required: true,
                    controller: _number,
                    hint: 'Enter 10-digit mobile number',
                    prefixText: '+91',
                    keyboardType: TextInputType.phone,
                    errorText: _numberError,
                    onChanged: (_) {
                      if (_tried) setState(() {});
                    },
                    inputFormatters: [
                      const ExAsciiDigitsFormatter(),
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  ExField(
                    label: 'Contact email',
                    required: true,
                    controller: _email,
                    hint: 'name@school.edu.in',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_tried) setState(() {});
                    },
                    textCapitalization: TextCapitalization.none,
                  ),
                ),
                const SizedBox(height: 16),
                ExField(
                  label: 'Notes',
                  controller: _notes,
                  hint: 'e.g. Wants a full product walkthrough',
                  maxLines: 3,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ExInlineNote(message: _error!),
                ],
              ],
            ),
          ),
          // ── Footer ──
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: exBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: SafeArea(
              top: false,
              child: ExPrimaryButton(
                label: _editing ? 'Save Changes' : 'Save Lead',
                loadingLabel: 'Saving…',
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Demo detail (shown inside the expanded demo card)

/// Voice player, recipients with call status, and the capture-lead action of
/// one demo. Lives inside the demo card when it is expanded.
class DemoDetailPanel extends ConsumerStatefulWidget {
  final ExhibitionDemo demo;
  final VoidCallback onCaptureLead;
  final VoidCallback? onSendAgain;

  const DemoDetailPanel({
    super.key,
    required this.demo,
    required this.onCaptureLead,
    this.onSendAgain,
  });

  @override
  ConsumerState<DemoDetailPanel> createState() => _DemoDetailPanelState();
}

class _DemoDetailPanelState extends ConsumerState<DemoDetailPanel> {
  final AudioPlayer _player = AudioPlayer();

  /// Preload of the voice URL (gives the total length before play).
  Future<Duration?>? _load;
  bool _loadFailed = false;
  bool _playWhenReady = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Uses the copy downloaded when the demo list loaded (instant), else
  /// streams the URL. The duration then shows without pressing play.
  Future<Duration?> _prepare() {
    final url = widget.demo.audioUrl;
    if (url.isEmpty) return Future.value(null);
    _loadFailed = false;
    Future<Duration?> open() async {
      final local = await ref.read(localAudioProvider(url).future);
      if (local != null) {
        try {
          return await _player.setFilePath(local.path);
        } catch (_) {}
      }
      return _player.setUrl(url).timeout(const Duration(seconds: 30));
    }

    final f = open();
    _load = f;
    f.then((_) {
      if (!mounted) return;
      setState(() {});
      if (_playWhenReady) {
        _playWhenReady = false;
        _play();
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _playWhenReady = false;
        _load = null;
      });
    });
    return f;
  }

  bool get _ready =>
      _player.audioSource != null &&
      _player.processingState != ProcessingState.idle &&
      _player.processingState != ProcessingState.loading;

  Future<void> _play() async {
    try {
      await exPreparePlayback();
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      unawaited(_player.play());
    } catch (_) {
      if (mounted) exToast(context, 'Could not play audio', error: true);
    }
  }

  Future<void> _toggle() async {
    if (widget.demo.audioUrl.isEmpty) {
      exToast(context, 'No audio available for this demo', error: true);
      return;
    }
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (_loadFailed || _load == null) {
      // Retry a failed load, then play.
      setState(() => _playWhenReady = true);
      _prepare();
      return;
    }
    if (!_ready) {
      // Still loading: start as soon as it is ready.
      setState(() => _playWhenReady = true);
      return;
    }
    await _play();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: exPageBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (_, snap) {
              final state = snap.data;
              final completed = state?.processingState == ProcessingState.completed;
              final playing = (state?.playing ?? false) && !completed;
              final buffering = d.audioUrl.isNotEmpty &&
                  !_loadFailed &&
                  (_playWhenReady ||
                      (playing && state?.processingState == ProcessingState.buffering));
              return Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: exInk),
                      tooltip: playing ? 'Pause' : 'Play voice',
                      onPressed: _toggle,
                      icon: buffering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : completed
                                      ? Icons.replay_rounded
                                      : Icons.play_arrow_rounded,
                              color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (_, durSnap) => StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (_, pos) {
                          final total = durSnap.data ?? _player.duration;
                          var p = pos.data ?? Duration.zero;
                          if (total != null && p > total) p = total;
                          final f = total == null || total.inMilliseconds == 0
                              ? 0.0
                              : (p.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                          final String timeText;
                          if (d.audioUrl.isEmpty) {
                            timeText = 'No audio';
                          } else if (_loadFailed) {
                            timeText = "Couldn't load audio · tap play to retry";
                          } else if (total == null) {
                            timeText = 'Loading…';
                          } else {
                            timeText = '${exDuration(p)} / ${exDuration(total)}';
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Demo voice', style: exHeadingSm),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: f,
                                  minHeight: 4,
                                  backgroundColor: exBorder,
                                  color: exBrand,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(timeText,
                                  style: _loadFailed
                                      ? exBodySm.copyWith(color: exDanger)
                                      : exBodySm),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text('Recipients (${d.recipients.isEmpty ? d.recipientCount : d.recipients.length})',
            style: exHeadingSm),
        const SizedBox(height: 8),
        if (d.recipients.isEmpty)
          const Text('Call details are not available yet.', style: exBodyMd)
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: exBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < d.recipients.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: exBorder),
                  _RecipientRow(r: d.recipients[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        if (d.hasLead)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: exSuccessBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: exSuccess),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Lead captured',
                      style: TextStyle(
                          fontSize: 15, color: exSuccess, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        if (d.hasLead && widget.onSendAgain != null) const SizedBox(height: 10),
        // Actions side by side so the expanded card stays short.
        Row(
          children: [
            if (!d.hasLead)
              Expanded(
                child: ExPrimaryButton(
                  label: 'Capture Lead',
                  height: 48,
                  onPressed: widget.onCaptureLead,
                ),
              ),
            if (!d.hasLead && widget.onSendAgain != null) const SizedBox(width: 10),
            if (widget.onSendAgain != null)
              Expanded(
                child: ExSecondaryButton(
                  label: 'Send again',
                  color: exBrandBold,
                  height: 48,
                  onPressed: () {
                    _player.stop();
                    widget.onSendAgain!();
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecipientRow extends StatelessWidget {
  final DemoRecipient r;
  const _RecipientRow({required this.r});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = callStatusColors(r.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatIndianMobile(r.number), style: exHeadingSm.copyWith(fontSize: 15)),
                if (r.name.isNotEmpty) Text(r.name, style: exBodySm),
              ],
            ),
          ),
          ExPill(
            label: r.isTeam ? 'Attendee' : 'Visitor',
            background: r.isTeam ? exTint : exVisitorBg,
            foreground: exInk,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Center(child: ExPill(label: r.status.label, background: bg, foreground: fg)),
          ),
        ],
      ),
    );
  }
}

// MARK: - Add voice template

/// Record a new voice template and upload it. Returns true when saved.
Future<bool> showAddTemplateSheet(BuildContext context) async {
  final saved = await _showSheet<bool>(context, (_) => const _AddTemplateSheet(), full: true);
  return saved == true;
}

class _AddTemplateSheet extends ConsumerStatefulWidget {
  const _AddTemplateSheet();

  @override
  ConsumerState<_AddTemplateSheet> createState() => _AddTemplateSheetState();
}

class _AddTemplateSheetState extends ConsumerState<_AddTemplateSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _path;
  Duration _length = Duration.zero;
  bool _tried = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    final p = _path;
    if (p != null) File(p).delete().catchError((_) => File(p));
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _error = null;
    });
    if (_title.text.trim().isEmpty || _path == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(exhibitionRepositoryProvider).createTemplate(
            title: _title.text.trim(),
            description: _description.text.trim(),
            wavPath: _path!,
            duration: _length,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 12, 12),
            child: Column(
              children: [
                _handle(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Add voice template', style: exHeadingLg)),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded, color: exInk),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: exBorder),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                ExField(
                  label: 'Template name',
                  required: true,
                  controller: _title,
                  hint: 'e.g. Product Intro (Tamil)',
                  errorText: _tried && _title.text.trim().isEmpty ? 'Template name is required' : null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_tried) setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                ExField(
                  label: 'Description',
                  controller: _description,
                  hint: 'e.g. Short overview for principals',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                Text('Voice', style: exHeadingSm.copyWith(fontSize: 15)),
                const SizedBox(height: 8),
                VoiceRecorderPanel(
                  initialPath: _path,
                  initialDuration: _length,
                  onChanged: (path, len) => setState(() {
                    _path = path;
                    _length = len;
                  }),
                ),
                if (_tried && _path == null) ...[
                  const SizedBox(height: 12),
                  const ExInlineNote(message: 'Record the voice to save the template.'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ExInlineNote(message: _error!),
                ],
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: exBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: SafeArea(
              top: false,
              child: ExPrimaryButton(
                label: 'Save Template',
                loadingLabel: 'Uploading…',
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
