import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/ExhibitionModel.dart';
import '../../core/exhibition/demo_templates.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'widget/exhibition_common.dart';
import 'widget/voice_recorder_panel.dart';

/// What the Give Demo flow hands back after a successful send.
class GiveDemoResult {
  final String demoId;
  final int callCount;
  final String visitorName;
  final String? firstVisitorNumber;

  const GiveDemoResult({
    required this.demoId,
    required this.callCount,
    required this.visitorName,
    this.firstVisitorNumber,
  });
}

enum _Voice { template, record }

/// Full-screen flow: 1 Voice → 2 Visitors → 3 Review & Send.
/// POST /api/mobile/exhibitions/:id/demos
class GiveDemoView extends ConsumerStatefulWidget {
  final Exhibition exhibition;

  const GiveDemoView({super.key, required this.exhibition});

  @override
  ConsumerState<GiveDemoView> createState() => _GiveDemoViewState();
}

class _GiveDemoViewState extends ConsumerState<GiveDemoView> {
  int _step = 0;

  // Step 1
  _Voice _voice = _Voice.template;
  DemoTemplate? _template;
  String? _recordingPath;
  Duration _recordingLength = Duration.zero;
  final AudioPlayer _preview = AudioPlayer();
  String? _previewId;
  bool _step1Error = false;

  // Step 2
  final _visitorName = TextEditingController();
  final _numberInput = TextEditingController();
  final _pasteInput = TextEditingController();
  final List<String> _numbers = [];
  bool _pasteOpen = false;
  String? _numberError;
  String? _dupNote;
  bool _step2Error = false;

  // Step 3
  bool _sending = false;
  String _sendPhase = '';
  String? _sendError;

  List<Attendee> get _team => widget.exhibition.attendees;

  bool get _dirty =>
      _template != null ||
      _recordingPath != null ||
      _numbers.isNotEmpty ||
      _visitorName.text.trim().isNotEmpty ||
      _numberInput.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _preview.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        _preview.stop();
        setState(() => _previewId = null);
      }
    });
  }

  @override
  void dispose() {
    _preview.dispose();
    _visitorName.dispose();
    _numberInput.dispose();
    _pasteInput.dispose();
    final p = _recordingPath;
    if (p != null) {
      File(p).delete().catchError((_) => File(p));
    }
    super.dispose();
  }

  // MARK: Template preview

  Future<void> _togglePreview(DemoTemplate t) async {
    if (_previewId == t.id) {
      await _preview.stop();
      setState(() => _previewId = null);
      return;
    }
    if (t.audioUrl.isEmpty) {
      exToast(context, 'Audio for this template is not set up yet', error: true);
      return;
    }
    setState(() => _previewId = t.id);
    try {
      await _preview.stop();
      await _preview.setUrl(t.audioUrl);
      _preview.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewId = null);
      exToast(context, 'Could not play the preview', error: true);
    }
  }

  // MARK: Numbers

  void _addNumbers(List<String> raw, {required bool fromPaste}) {
    final bad = <String>[];
    var dup = 0;
    for (final r in raw) {
      final t = r.trim();
      if (t.isEmpty) continue;
      final d = normalizeIndianMobile(t);
      if (!isValidIndianMobile(d)) {
        bad.add(t);
      } else if (_numbers.contains(d)) {
        dup++;
      } else {
        _numbers.add(d);
      }
    }
    setState(() {
      _step2Error = false;
      _numberError = bad.isEmpty
          ? null
          : bad.length == 1
              ? '“${bad.first}” is not a valid 10-digit number'
              : '${bad.length} entries are not valid 10-digit numbers: ${bad.join(', ')}';
      _dupNote = dup == 0 ? null : '$dup ${dup == 1 ? 'duplicate' : 'duplicates'} removed';
      if (fromPaste) {
        _pasteInput.text = bad.join('\n');
        if (bad.isEmpty) _pasteOpen = false;
      } else if (bad.isEmpty) {
        _numberInput.clear();
      }
    });
  }

  // MARK: Navigation

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this demo?'),
        content: const Text('The voice and numbers you entered will be lost. No calls have been made.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: exDanger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _close() async {
    if (_sending) return;
    if (!_dirty || await _confirmDiscard()) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      final ok = _voice == _Voice.template
          ? _template != null && _template!.audioUrl.isNotEmpty
          : _recordingPath != null;
      if (!ok) {
        setState(() => _step1Error = true);
        return;
      }
      _preview.stop();
      setState(() {
        _previewId = null;
        _step1Error = false;
        _step = 1;
      });
    } else if (_step == 1) {
      if (_numberInput.text.trim().isNotEmpty) {
        _addNumbers([_numberInput.text], fromPaste: false);
        if (_numberError != null) return;
      }
      if (_numbers.isEmpty) {
        setState(() => _step2Error = true);
        return;
      }
      setState(() {
        _step2Error = false;
        _step = 2;
      });
    }
  }

  void _back() {
    if (_sending || _step == 0) return;
    setState(() {
      _sendError = null;
      _step--;
    });
  }

  // MARK: Send

  Future<void> _send() async {
    if (_sending) return;
    final repo = ref.read(exhibitionRepositoryProvider);
    final total = _numbers.length + _team.length;
    setState(() {
      _sending = true;
      _sendError = null;
      _sendPhase = _voice == _Voice.record ? 'Uploading recording…' : 'Dialling $total numbers…';
    });
    try {
      final String demoId;
      if (_voice == _Voice.template) {
        demoId = await repo.sendTemplateDemo(
          exhibitionId: widget.exhibition.id,
          audioUrl: _template!.audioUrl,
          visitorNumbers: List.of(_numbers),
          visitorName: _visitorName.text.trim(),
        );
      } else {
        final path = _recordingPath!;
        if (!await File(path).exists()) {
          throw Exception('The recording file is missing. Please record again.');
        }
        demoId = await repo.sendRecordedDemo(
          exhibitionId: widget.exhibition.id,
          wavPath: path,
          visitorNumbers: List.of(_numbers),
          visitorName: _visitorName.text.trim(),
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _sendPhase =
                p >= 0.99 ? 'Dialling $total numbers…' : 'Uploading recording… ${(p * 100).round()}%');
          },
        );
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(
        context,
        GiveDemoResult(
          demoId: demoId,
          callCount: total,
          visitorName: _visitorName.text.trim(),
          firstVisitorNumber: _numbers.isEmpty ? null : _numbers.first,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = e.toString();
      });
    }
  }

  // MARK: UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              _header(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: exPageBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                                exIsWide(context) ? 28 : 18, 24, exIsWide(context) ? 28 : 18, 24),
                            child: ExMaxWidth(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.topCenter,
                                  children: [...previous, if (current != null) current],
                                ),
                                child: KeyedSubtree(
                                  key: ValueKey(_step),
                                  child: switch (_step) {
                                    0 => _voiceStep(),
                                    1 => _visitorStep(),
                                    _ => _reviewStep(),
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        _footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final base = AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.black, 0.15)!, base],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: ExMaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: _close,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Give Demo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              )),
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(widget.exhibition.name,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Step ${_step + 1} of 3',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Stepper(
                  step: _step,
                  onTap: (i) {
                    if (i < _step && !_sending) setState(() => _step = i);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6))],
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: ExMaxWidth(
          child: Row(
            children: [
              if (_step > 0) ...[
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: _sending ? null : _back,
                    style: IconButton.styleFrom(
                      backgroundColor: exPageBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, color: exInk),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _step < 2
                    ? ExPrimaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        height: 56,
                        onPressed: _next,
                      )
                    : ExPrimaryButton(
                        label: 'Send Demo Call',
                        icon: Icons.phone_forwarded_rounded,
                        height: 56,
                        loading: _sending,
                        loadingLabel: _sendPhase,
                        onPressed: _send,
                      ),
              ),
            ],
          ),
        ),
      );

  Widget _title(String t, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: exInk,
                )),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 14.5, color: exSubtle)),
          ],
        ),
      );

  // Step 1

  void _setVoice(_Voice v) {
    if (v == _voice) return;
    HapticFeedback.selectionClick();
    _preview.stop();
    setState(() {
      _voice = v;
      _previewId = null;
      _step1Error = false;
    });
  }

  Widget _voiceStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Choose a voice', 'Play a ready-made template or record a message.'),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  icon: Icons.library_music_rounded,
                  title: 'Use Template',
                  subtitle: 'Ready-made voice',
                  selected: _voice == _Voice.template,
                  onTap: () => _setVoice(_Voice.template),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  icon: Icons.mic_rounded,
                  title: 'Record Voice',
                  subtitle: 'Your own message',
                  selected: _voice == _Voice.record,
                  onTap: () => _setVoice(_Voice.record),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_voice == _Voice.template)
            ..._templateCards()
          else
            VoiceRecorderPanel(
              initialPath: _recordingPath,
              initialDuration: _recordingLength,
              onChanged: (path, len) => setState(() {
                _recordingPath = path;
                _recordingLength = len;
                if (path != null) _step1Error = false;
              }),
            ),
          if (_step1Error) ...[
            const SizedBox(height: 14),
            _ErrorBanner(
              message: _voice == _Voice.template
                  ? (_template != null && _template!.audioUrl.isEmpty
                      ? 'Audio for this template is not set up yet. Pick another or record a voice.'
                      : 'Choose a template to continue.')
                  : 'Record a voice message to continue.',
            ),
          ],
        ],
      );

  List<Widget> _templateCards() {
    if (exhibitionDemoTemplates.isEmpty) {
      return const [
        ExStateView(
          icon: Icons.library_music_outlined,
          title: 'No templates yet',
          message: 'Record a custom voice instead.',
        ),
      ];
    }
    return [
      for (final t in exhibitionDemoTemplates) ...[
        _TemplateCard(
          template: t,
          selected: _template?.id == t.id,
          playing: _previewId == t.id,
          player: _preview,
          onSelect: () => setState(() {
            _template = t;
            _step1Error = false;
          }),
          onTogglePlay: () => _togglePreview(t),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  // Step 2

  Widget _visitorStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Who is the demo for?', 'Add one or more visitor numbers. Each one gets a call.'),
          ExField(
            label: 'Visitor name (optional)',
            controller: _visitorName,
            hint: 'e.g. Mrs. Lakshmi, Principal',
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('Visitor mobile numbers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exInk)),
              ),
              ExPill(
                label: '${_numbers.length} ${_numbers.length == 1 ? 'number' : 'numbers'}',
                background: _numbers.isEmpty ? const Color(0xFFEFF1F5) : exTint,
                foreground: exInk,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _numberInput,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) => _addNumbers([v], fromPaste: false),
                  onChanged: (_) {
                    if (_numberError != null) setState(() => _numberError = null);
                  },
                  style: const TextStyle(fontSize: 16, color: exInk),
                  decoration: exInputDecoration(
                    hint: '10-digit mobile number',
                    prefixText: '+91  ',
                    errorText: _numberError,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 54,
                child: ExSecondaryButton(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  height: 54,
                  onPressed: () {
                    if (_numberInput.text.trim().isEmpty) {
                      setState(() => _numberError = 'Type a 10-digit number first');
                      return;
                    }
                    _addNumbers([_numberInput.text], fromPaste: false);
                  },
                ),
              ),
            ],
          ),
          if (_dupNote != null) ...[
            const SizedBox(height: 6),
            Text(_dupNote!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFA3561F))),
          ],
          const SizedBox(height: 10),
          if (_numbers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: exStrongBorder, style: BorderStyle.solid),
                color: Colors.white,
              ),
              child: const Row(
                children: [
                  Icon(Icons.contact_phone_outlined, color: exSubtle),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('No numbers added yet. Type one above and tap Add.',
                        style: TextStyle(color: exSubtle)),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in _numbers)
                  InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.phone_rounded, size: 13, color: Colors.white),
                    ),
                    label: Text(formatIndianMobile(n),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: exInk)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: exBorder),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    deleteButtonTooltipMessage: 'Remove ${formatIndianMobile(n)}',
                    onDeleted: () => setState(() => _numbers.remove(n)),
                  ),
              ],
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _pasteOpen = !_pasteOpen),
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text(_pasteOpen ? 'Hide paste box' : 'Paste multiple numbers'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 48),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_pasteOpen)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _pasteInput,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, color: exInk),
                    decoration: exInputDecoration(hint: 'Separate with commas or new lines'),
                  ),
                  const SizedBox(height: 8),
                  ExSecondaryButton(
                    label: 'Add numbers',
                    icon: Icons.playlist_add_rounded,
                    onPressed: () =>
                        _addNumbers(_pasteInput.text.split(RegExp(r'[\n,;]+')), fromPaste: true),
                  ),
                ],
              ),
            ),
          if (_step2Error) ...[
            const SizedBox(height: 12),
            const _ErrorBanner(message: 'Add at least one visitor number to send the demo.'),
          ],
          const SizedBox(height: 18),
          _TeamCard(team: _team),
        ],
      );

  // Step 3

  Widget _reviewStep() {
    final total = _numbers.length + _team.length;
    final voice = _voice == _Voice.template
        ? '${_template?.title ?? ''} · ${exDuration(_template?.duration ?? Duration.zero)}'
        : 'Custom recording · ${exDuration(_recordingLength)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Review & send', 'Check everything before the calls go out.'),
        _callSummary(total),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: exBorder),
            boxShadow: exCardShadow,
          ),
          child: Column(
            children: [
              _reviewRow('Voice', Text(voice, style: _strong), onEdit: () => setState(() => _step = 0)),
              _reviewRow(
                'Visitor',
                Text(_visitorName.text.trim().isEmpty ? 'Not provided' : _visitorName.text.trim(),
                    style: _strong),
                onEdit: () => setState(() => _step = 1),
              ),
              _reviewRow(
                'Visitor numbers (${_numbers.length})',
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final n in _numbers) _smallChip(formatIndianMobile(n), exPageBg)],
                ),
                onEdit: () => setState(() => _step = 1),
              ),
              _reviewRow(
                'Attenders (${_team.length})',
                _team.isEmpty
                    ? const Text('No attenders', style: TextStyle(color: exSubtle))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in _team)
                            _smallChip('${m.name} · ${formatIndianMobile(m.mobile)}',
                                const Color(0xFFE8ECF5)),
                        ],
                      ),
                last: true,
              ),
            ],
          ),
        ),
        if (_sendError != null) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: _sendError!, onRetry: _send),
        ],
      ],
    );
  }

  Widget _callSummary(int total) {
    final base = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.black, 0.18)!, Color.lerp(base, Colors.white, 0.1)!],
        ),
        boxShadow: [
          BoxShadow(color: base.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total ${total == 1 ? 'call' : 'calls'} will go out',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _summaryPill(Icons.person_rounded,
                        '${_numbers.length} ${_numbers.length == 1 ? 'visitor' : 'visitors'}'),
                    _summaryPill(Icons.groups_rounded,
                        '${_team.length} ${_team.length == 1 ? 'attender' : 'attenders'}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(text,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
          ],
        ),
      );

  static const _strong = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: exInk);

  Widget _smallChip(String text, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: exInk)),
      );

  Widget _reviewRow(String label, Widget value, {VoidCallback? onEdit, bool last = false}) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: exPageBg)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12.5, color: exSubtle)),
                  const SizedBox(height: 4),
                  value,
                ],
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: _sending ? null : onEdit,
                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                child: const Text('Edit'),
              ),
          ],
        ),
      );
}

/// Three progress segments on the blue header. Done steps can be tapped.
class _Stepper extends StatelessWidget {
  final int step;
  final ValueChanged<int> onTap;

  const _Stepper({required this.step, required this.onTap});

  static const _labels = ['Voice', 'Visitors', 'Review & Send'];
  static const _icons = [Icons.graphic_eq_rounded, Icons.people_alt_rounded, Icons.send_rounded];

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: i < step,
              selected: i == step,
              label: 'Step ${i + 1}, ${_labels[i]}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 5, color: Colors.white.withValues(alpha: 0.22)),
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            widthFactor: i <= step ? 1 : 0,
                            child: Container(height: 5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          i < step ? Icons.check_circle_rounded : _icons[i],
                          size: 15,
                          color: i <= step ? Colors.white : Colors.white54,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            narrow && i == 2 ? 'Review' : _labels[i],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: i == step ? FontWeight.w800 : FontWeight.w600,
                              color: i <= step ? Colors.white : Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Big tappable choice between a template and a custom recording.
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? null : Colors.white,
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(base, Colors.black, 0.12)!, Color.lerp(base, Colors.white, 0.12)!],
                  )
                : null,
            border: Border.all(color: selected ? Colors.transparent : exBorder),
            boxShadow: selected
                ? [BoxShadow(color: base.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))]
                : exCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.18) : exTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: selected ? Colors.white : base),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(selected),
                      color: selected ? Colors.white : exStrongBorder,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : exInk,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white70 : exSubtle,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DemoTemplate template;
  final bool selected;
  final bool playing;
  final AudioPlayer player;
  final VoidCallback onSelect;
  final VoidCallback onTogglePlay;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.playing,
    required this.player,
    required this.onSelect,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final t = template;
    return ExCard(
      highlighted: selected,
      padding: EdgeInsets.zero,
      onTap: onSelect,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: IconButton(
                    tooltip: playing ? 'Pause preview of ${t.title}' : 'Play preview of ${t.title}',
                    onPressed: onTogglePlay,
                    style: IconButton.styleFrom(
                      backgroundColor: playing ? AppColors.primary : exTint,
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: playing ? Colors.white : AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: exInk)),
                      const SizedBox(height: 2),
                      Text(t.description, style: const TextStyle(fontSize: 13, color: exSubtle)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: exSubtle),
                          const SizedBox(width: 4),
                          Text(
                            t.audioUrl.isEmpty
                                ? '${exDuration(t.duration)} · Audio not set up yet'
                                : exDuration(t.duration),
                            style: const TextStyle(fontSize: 12, color: exSubtle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : exStrongBorder,
                  size: 26,
                ),
              ],
            ),
          ),
          if (playing)
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snap) {
                final total = player.duration ?? t.duration;
                final p = snap.data ?? Duration.zero;
                final f = total.inMilliseconds == 0
                    ? 0.0
                    : (p.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: LinearProgressIndicator(
                    value: f,
                    minHeight: 4,
                    backgroundColor: Colors.transparent,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final List<Attendee> team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: exBorder),
          boxShadow: exCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.groups_outlined, size: 20, color: exInk),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Attenders will also be called',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: exInk)),
                ),
                Text('Set on the exhibition', style: TextStyle(fontSize: 12, color: exSubtle)),
              ],
            ),
            const SizedBox(height: 10),
            if (team.isEmpty)
              const Text('No attenders on this exhibition.', style: TextStyle(color: exSubtle))
            else
              for (final m in team)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: exTint,
                        child: Text(exInitials(m.name),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: exInk)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(m.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: exInk)),
                      ),
                      Text(formatIndianMobile(m.mobile), style: const TextStyle(color: exSubtle)),
                    ],
                  ),
                ),
          ],
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: exDanger.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: exDanger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: exDanger, fontWeight: FontWeight.w600)),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              ExSecondaryButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry),
            ],
          ],
        ),
      );
}
