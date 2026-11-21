import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../provider/user_session_provider.dart';
import '../../viewModel/exhibition_viewmodel.dart';
import 'showcase/sc_spotlight.dart';
import 'showcase/showcase_content.dart';
import 'widget/exhibition_common.dart';
import 'widget/demo_audio.dart';
import 'widget/exhibition_sheets.dart';
import 'widget/voice_recorder_panel.dart';

/// What the Give Demo flow hands back after a successful send.
class GiveDemoResult {
  final String demoId;
  final int callCount;
  final String visitorName;
  final String? firstVisitorNumber;
  final List<String> visitorNumbers;

  const GiveDemoResult({
    required this.demoId,
    required this.callCount,
    required this.visitorName,
    this.firstVisitorNumber,
    this.visitorNumbers = const [],
  });
}

enum _Voice { template, record }

/// Full-screen flow: 1 Voice → 2 Visitors → 3 Review & Send.
/// POST /api/mobile/exhibitions/:id/demos
class GiveDemoView extends ConsumerStatefulWidget {
  final Exhibition exhibition;

  /// Opens on a later step (screenshot tests only).
  @visibleForTesting
  final int initialStep;

  /// Send an earlier demo again: its voice, visitor name and numbers are
  /// prefilled and the flow opens on the review step (Back to edit).
  final ExhibitionDemo? resendFrom;

  const GiveDemoView({super.key, required this.exhibition, this.initialStep = 0, this.resendFrom});

  @override
  ConsumerState<GiveDemoView> createState() => _GiveDemoViewState();
}

class _GiveDemoViewState extends ConsumerState<GiveDemoView> {
  late int _step = widget.initialStep;

  static const _stepNames = ['Voice', 'Visitor', 'Review'];

  // Step 1
  _Voice _voice = _Voice.template;
  DemoTemplate? _template;

  /// The earlier demo's voice when it is not one of the stock templates.
  DemoTemplate? _previousVoice;
  String? _recordingPath;
  Duration _recordingLength = Duration.zero;
  final AudioPlayer _preview = AudioPlayer();
  String? _previewId;
  bool _step1Error = false;

  // Step 2
  final _visitorName = TextEditingController();
  final _numberInput = TextEditingController();
  final List<String> _numbers = [];
  String? _numberError;
  String? _dupNote;
  bool _step2Error = false;
  bool _nameError = false;

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
    final r = widget.resendFrom;
    if (r != null) _prefillFrom(r);
    _preview.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        _preview.stop();
        setState(() => _previewId = null);
      }
    });
  }

  void _prefillFrom(ExhibitionDemo d) {
    _visitorName.text = d.visitorName.trim();
    for (final rc in d.recipients) {
      if (rc.isTeam) continue;
      final n = normalizeIndianMobile(rc.number);
      if (isValidIndianMobile(n) && !_numbers.contains(n)) _numbers.add(n);
    }
    if (d.audioUrl.isNotEmpty) {
      _voice = _Voice.template;
      final templates = ref.read(exhibitionTemplatesProvider(widget.exhibition.id)).value ?? const <DemoTemplate>[];
      _template = templates.where((t) => t.audioUrl == d.audioUrl).firstOrNull;
      if (_template == null) {
        _previousVoice = DemoTemplate(
          id: '__previous__',
          title: 'Previous demo voice',
          description: 'The voice used in the earlier demo',
          duration: Duration.zero,
          audioUrl: d.audioUrl,
        );
        _template = _previousVoice;
      }
    }
    // Land on review when everything is in place; otherwise on the first
    // step that still needs input.
    _step = _template == null
        ? 0
        : (_numbers.isEmpty || _visitorName.text.isEmpty)
        ? 1
        : 2;
  }

  @override
  void dispose() {
    _preview.dispose();
    _visitorName.dispose();
    _numberInput.dispose();
    final p = _recordingPath;
    if (p != null) {
      File(p).delete().catchError((_) => File(p));
    }
    super.dispose();
  }

  /// Length read from the template's audio URL (falls back to the listed one).
  Duration _realDuration(DemoTemplate t) =>
      ref.watch(audioDurationProvider(t.audioUrl)).value ?? t.duration;

  /// Plays the cached download when there is one, else streams the URL.
  Future<void> _openVoice(String url) async {
    final local = await ref.read(localAudioProvider(url).future);
    if (local != null) {
      try {
        await _preview.setFilePath(local.path);
        return;
      } catch (_) {}
    }
    await _preview.setUrl(url);
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
      await _openVoice(t.audioUrl);
      await exPreparePlayback();
      _preview.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewId = null);
      exToast(context, 'Could not play the preview', error: true);
    }
  }

  /// Review step: play the chosen voice (template or recording).
  static const _reviewPreviewId = '__review__';

  Future<void> _toggleReviewVoice() async {
    if (_previewId == _reviewPreviewId) {
      await _preview.stop();
      setState(() => _previewId = null);
      return;
    }
    final url = _voice == _Voice.template ? _template?.audioUrl ?? '' : '';
    final path = _voice == _Voice.record ? _recordingPath : null;
    if (url.isEmpty && path == null) return;
    setState(() => _previewId = _reviewPreviewId);
    try {
      await _preview.stop();
      if (path != null) {
        await _preview.setFilePath(path);
      } else {
        await _openVoice(url);
      }
      await exPreparePlayback();
      _preview.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewId = null);
      exToast(context, 'Could not play the voice', error: true);
    }
  }

  // MARK: Numbers

  void _addNumbers(List<String> raw) {
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
      if (bad.isEmpty) {
        _numberInput.clear();
      }
    });
  }

  // MARK: Navigation

  Future<bool> _confirmDiscard() => showExConfirmDialog(
    context,
    title: 'Discard this demo?',
    message: 'The voice and numbers you entered will be lost.',
    cancelLabel: 'Keep editing',
    confirmLabel: 'Discard',
    destructive: true,
  );

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
      // Visitor name is required.
      final noName = _visitorName.text.trim().isEmpty;
      if (noName) setState(() => _nameError = true);
      if (_numberInput.text.trim().isNotEmpty) {
        _addNumbers([_numberInput.text]);
        if (_numberError != null) return;
      }
      if (_numbers.isEmpty) {
        setState(() => _step2Error = true);
        return;
      }
      if (noName) return;
      setState(() {
        _step2Error = false;
        _step = 2;
      });
    }
  }

  void _back() {
    if (_sending || _step == 0) return;
    _preview.stop();
    setState(() {
      _previewId = null;
      _sendError = null;
      _step--;
    });
  }

  // MARK: Send

  Future<void> _send() async {
    if (_sending || _numbers.isEmpty) return;
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
          audioPath: path,
          visitorNumbers: List.of(_numbers),
          visitorName: _visitorName.text.trim(),
          onProgress: (p) {
            if (!mounted) return;
            setState(
              () => _sendPhase = p >= 0.99
                  ? 'Dialling $total numbers…'
                  : 'Uploading recording… ${(p * 100).round()}%',
            );
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
          visitorNumbers: List.of(_numbers),
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
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return PopScope(
      canPop: !_dirty && !_sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: ExTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: exHeaderOverlay,
          child: Scaffold(
            backgroundColor: exHeaderBase,
            body: Column(
              children: [
                _header(wide),
                Expanded(
                  child: ExCurvedBody(
                    child: Column(
                      children: [
                        _stepperBar(wide),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 40 : 20,
                            wide ? 32 : 24,
                            wide ? 40 : 20,
                            24,
                          ),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          // Centred column on iPad so wide screens don't stretch.
                          child: ExMaxWidth(
                            maxWidth: exFormMaxWidth,
                            // Steps slide in from the side they come from.
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Phones: School Chimes banner on top (visitors
                                // won't scroll to find it).
                                if (!wide) ...[
                                  ScSpotlightBanner(spot: scGiveDemoSpotlights[_step]),
                                  const SizedBox(height: 22),
                                ],
                                ExStepSwitcher(step: _step, child: _stepBody(wide)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // iPad: one School Chimes solution beside each step.
                      if (wide)
                        Container(
                          width: 380,
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: exBorder)),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 32, 28, 24),
                            child: ScSpotlightCard(spot: scGiveDemoSpotlights[_step]),
                          ),
                        ),
                    ],
                  ),
                ),
                _footer(wide),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(bool wide) => switch (_step) {
    0 => _voiceStep(wide),
    1 => _visitorStep(wide),
    _ => _reviewStep(wide),
  };

  Widget _header(bool wide) => ExGradientHeader(
        padding: EdgeInsets.fromLTRB(wide ? 24 : 8, 8, wide ? 24 : 16, 18),
        child: Row(
          children: [
            ExHeaderIconButton(icon: Icons.close_rounded, tooltip: 'Close', onTap: _close),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Give Demo',
                      style: exHeadingMd.copyWith(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(
                    widget.exhibition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: exBodyMd.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Progress strip at the top of the curved body.
  Widget _stepperBar(bool wide) => Padding(
        padding: EdgeInsets.fromLTRB(wide ? 40 : 20, 20, wide ? 40 : 20, 0),
        child: ExMaxWidth(
          maxWidth: exFormMaxWidth,
          child: ExStepProgress(
            current: _step,
            total: _stepNames.length,
            label: 'Step ${_step + 1} of ${_stepNames.length} · ${_stepNames[_step]}',
          ),
        ),
      );

  Widget _footer(bool wide) => ExStepBar(
        onBack: _step > 0 ? _back : null,
        nextLabel: _step < 2 ? 'Continue' : 'Initiate Demo Call',
        nextIcon: _step < 2 ? Icons.arrow_forward_rounded : Icons.phone_in_talk_rounded,
        loading: _sending,
        loadingLabel: _sendPhase,
        onNext: _step < 2 ? _next : (_numbers.isEmpty ? null : _send),
      );

  /// Jump to a step from the review's Edit links.
  void _goTo(int step) {
    if (_sending) return;
    _preview.stop();
    setState(() {
      _previewId = null;
      _sendError = null;
      _step = step;
    });
  }

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

  Widget _voiceStep(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ExQuestion(
        icon: Icons.graphic_eq_rounded,
        title: 'Which voice should they hear?',
        subtitle: 'Play a ready-made template or record a message for this visitor.',
      ),
      const SizedBox(height: 24),
      _Segmented(
        wide: wide,
        selected: _voice == _Voice.template ? 0 : 1,
        onChanged: (i) => _setVoice(i == 0 ? _Voice.template : _Voice.record),
      ),
      // Validation sits right under the switch so it is always in view.
      if (_step1Error) ...[
        SizedBox(height: wide ? 20 : 12),
        ExInlineNote(
          message: _voice == _Voice.template
              ? (_template != null && _template!.audioUrl.isEmpty
                    ? 'Audio for this template is not set up yet. Pick another or record a voice.'
                    : 'Choose a template to continue.')
              : 'Record a voice message to continue.',
        ),
      ],
      SizedBox(height: wide ? 24 : 16),
      if (_voice == _Voice.template)
        _templateCards(wide)
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
    ],
  );

  Future<void> _addTemplate() async {
    final saved = await showAddTemplateSheet(context, exhibitionId: widget.exhibition.id);
    if (!saved || !mounted) return;
    ref.invalidate(exhibitionTemplatesProvider(widget.exhibition.id));
    exToast(context, 'Template added');
  }

  Future<void> _deleteTemplate(DemoTemplate t) async {
    final ok = await showExConfirmDialog(
      context,
      title: 'Delete this template?',
      message:
          '"${t.title}" will no longer be offered for new demos. Demo calls already initiated are not affected.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(exhibitionRepositoryProvider).deleteTemplate(t.id);
    } catch (e) {
      if (mounted) exToast(context, e.toString(), error: true);
      return;
    }
    if (!mounted) return;
    if (_previewId == t.id) _preview.stop();
    setState(() {
      if (_template?.id == t.id) _template = null;
      if (_previewId == t.id) _previewId = null;
    });
    ref.invalidate(exhibitionTemplatesProvider(widget.exhibition.id));
    exToast(context, 'Template deleted');
  }

  Widget _templateCards(bool wide) {
    final async = ref.watch(exhibitionTemplatesProvider(widget.exhibition.id));
    final addButton = _AddTemplateTile(onTap: _addTemplate);
    if (async.isLoading && !async.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: exBrandBold)),
      );
    }
    if (async.hasError && !async.hasValue) {
      return ExStateView(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load templates",
        message: 'Check the connection and try again, or record a custom voice.',
        isError: true,
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(exhibitionTemplatesProvider(widget.exhibition.id)),
      );
    }
    final templates = async.value ?? const <DemoTemplate>[];
    final prev = _previousVoice;
    final list = [
      if (prev != null && !templates.any((t) => t.audioUrl == prev.audioUrl)) prev,
      ...templates,
    ];
    if (list.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExStateView(
            icon: Icons.library_music_outlined,
            title: 'No templates yet',
            message: 'Add a template, or record a custom voice.',
          ),
          const SizedBox(height: 12),
          addButton,
        ],
      );
    }
    final user = ref.watch(userSessionProvider).value;
    Widget card(DemoTemplate t) => _TemplateCard(
      template: t.withDuration(_realDuration(t)),
      // A resend's "previous voice" also matches the same template by URL.
      selected:
          _template != null &&
          (_template!.id == t.id ||
              (_template!.id == '__previous__' && _template!.audioUrl == t.audioUrl)),
      playing: _previewId == t.id,
      player: _preview,
      onSelect: () => setState(() {
        _template = t;
        _step1Error = false;
      }),
      onTogglePlay: () => _togglePreview(t),
      // Only the person who added a template can delete it.
      onDelete:
          t.id != '__previous__' &&
              user != null &&
              t.isCreatedBy(userId: user.userId, userName: user.employeeName)
          ? () => _deleteTemplate(t)
          : null,
    );
    // Templates + the "Add template" tile, 1 column on phone, 2 on iPad.
    final tiles = [for (final t in list) card(t), addButton];
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            tiles[i],
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < (tiles.length + 1) ~/ 2; r++) ...[
          if (r > 0) const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[r * 2]),
                const SizedBox(width: 16),
                Expanded(child: r * 2 + 1 < tiles.length ? tiles[r * 2 + 1] : const SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Step 2

  Widget _visitorStep(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExQuestion(
          icon: Icons.person_rounded,
          title: 'Who is the demo for?',
          subtitle: 'Add their name and one or more numbers. Each number gets a call.',
        ),
        const SizedBox(height: 28),
        _fieldLabel('VISITOR NAME'),
        ExBigInput(
          controller: _visitorName,
          icon: Icons.badge_outlined,
          hint: 'e.g. Mrs. Lakshmi',
          errorText: _nameError ? 'Visitor name is required' : null,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (v) => setState(() {
            if (v.trim().isNotEmpty) _nameError = false;
          }),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _fieldLabel('MOBILE NUMBERS')),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExPill(
                label: '${_numbers.length} ${_numbers.length == 1 ? 'number' : 'numbers'}',
                background: _numbers.isEmpty ? exNeutralBg : exTint,
                foreground: _numbers.isEmpty ? exSubtle : exBrandBold,
              ),
            ),
          ],
        ),
        ExBigInput(
          controller: _numberInput,
          icon: Icons.phone_iphone_rounded,
          prefixText: '+91  ',
          hint: '10-digit mobile',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            const ExAsciiDigitsFormatter(),
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          errorText: _numberError,
          onSubmitted: (v) => _addNumbers([v]),
          onChanged: (_) {
            if (_numberError != null) setState(() => _numberError = null);
          },
        ),
        const SizedBox(height: 12),
        ExAppear(
          index: 4,
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                if (_numberInput.text.trim().isEmpty) {
                  setState(() => _numberError = 'Enter a 10-digit mobile number');
                  return;
                }
                _addNumbers([_numberInput.text]);
              },
              style: FilledButton.styleFrom(
                backgroundColor: exTint,
                foregroundColor: exBrandBold,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(exRadiusControl)),
                textStyle:
                    const TextStyle(fontFamily: exFont, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add_call, size: 20),
              label: const Text('Add number'),
            ),
          ),
        ),
        if (_dupNote != null) ...[
          const SizedBox(height: 12),
          ExInlineNote(message: _dupNote!, error: false),
        ],
        const SizedBox(height: 16),
        if (_numbers.isEmpty)
          const _DashedNote(text: 'No numbers added yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in _numbers)
                ExPopIn(
                  key: ValueKey(n),
                  child: _NumberChip(number: n, onRemove: () => setState(() => _numbers.remove(n))),
                ),
            ],
          ),
        if (_step2Error) ...[
          const SizedBox(height: 16),
          const ExInlineNote(message: 'Add at least one visitor number to initiate the demo call.'),
        ],
        const SizedBox(height: 24),
        _TeamCard(team: _team),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text, style: exLabelSm.copyWith(fontSize: 13, color: const Color(0xFF3A4A60))),
      );

  // Step 3

  Widget _reviewStep(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExQuestion(
          icon: Icons.campaign_rounded,
          color: exSuccess,
          background: exSuccessBg,
          title: 'Ready to call?',
          subtitle: 'Check everything, then start the demo calls. Tap Edit to change a part.',
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(exRadiusCard),
                  border: Border.all(color: const Color(0xFFEDF1F6)),
                  boxShadow: exCardShadow,
                ),
                child: Column(
                  children: [
                    _reviewVoiceRow(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: ExSummaryRow(
                        icon: Icons.person_rounded,
                        label: 'Visitor',
                        value: _visitorName.text.trim(),
                        onEdit: _sending ? null : () => _goTo(1),
                      ),
                    ),
                    _reviewRow(
                      'Visitor numbers (${_numbers.length})',
                      onEdit: _sending ? null : () => _goTo(1),
                      _numbers.isEmpty
                          ? Text('None added. Go back to add a visitor number.',
                              style: exBodyMd.copyWith(color: exDanger))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final n in _numbers)
                                  _NumberChip(
                                    number: n,
                                    onRemove: _sending
                                        ? null
                                        : () => setState(() => _numbers.remove(n)),
                                  ),
                              ],
                            ),
                    ),
                    _reviewRow(
                      'Attendees (${_team.length})',
                      _team.isEmpty
                          ? const Text('No attendees', style: exBodyMd)
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [for (final m in _team) _smallChip(m.name, exTint)],
                            ),
                      last: true,
                    ),
                  ],
                ),
              ),
              if (_sendError != null) ...[
                const SizedBox(height: 16),
                ExInlineNote(
                  message: _sendError!,
                  action: TextButton(
                    onPressed: _send,
                    style: TextButton.styleFrom(foregroundColor: exDanger),
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontFamily: exFont, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Voice row with a play button and progress, so the voice can be checked
  /// once more before the calls go out.
  Widget _reviewVoiceRow() {
    final playing = _previewId == _reviewPreviewId;
    final fallback = _voice == _Voice.template
        ? (_template == null ? Duration.zero : _realDuration(_template!))
        : _recordingLength;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFD),
        border: Border(bottom: BorderSide(color: exBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: playing ? 'Stop voice' : 'Play voice',
              onPressed: _toggleReviewVoice,
              style: IconButton.styleFrom(
                backgroundColor: playing ? exInk : exBrandBold,
                shape: const CircleBorder(),
              ),
              icon: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('VOICE', style: exLabelSm.copyWith(fontSize: 11))),
                    if (!_sending)
                      InkWell(
                        onTap: () => _goTo(0),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text('Edit',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: exBrandBold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_voiceLabel, style: _strong),
                const SizedBox(height: 8),
                StreamBuilder<Duration>(
                  stream: _preview.positionStream,
                  builder: (_, snap) {
                    final total = _preview.duration ?? fallback;
                    final p = playing ? (snap.data ?? Duration.zero) : Duration.zero;
                    final f = total.inMilliseconds == 0
                        ? 0.0
                        : (p.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: f,
                        minHeight: 5,
                        backgroundColor: exBorder,
                        color: exBrand,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _voiceLabel {
    if (_voice == _Voice.template) {
      return _template == null
          ? 'Not chosen'
          : _realDuration(_template!) == Duration.zero
          ? _template!.title
          : '${_template!.title} · ${exDuration(_realDuration(_template!))}';
    }
    return _recordingPath == null
        ? 'Not chosen'
        : 'Custom recording · ${exDuration(_recordingLength)}';
  }

  static const _strong = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk);

  Widget _smallChip(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
    ),
  );

  Widget _reviewRow(String label, Widget value, {bool last = false, VoidCallback? onEdit}) =>
      Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: exBorder)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: exLabelSm.copyWith(fontSize: 11))),
            if (onEdit != null)
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Edit',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: exBrandBold)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        value,
      ],
    ),
  );
}

/// "Use Template | Record Custom Voice" segmented control.
/// Voice source tabs (Template / Record). A white pill slides under the
/// active tab, so it reads as tabs rather than two options to pick.
class _Segmented extends StatelessWidget {
  final bool wide;
  final int selected;
  final ValueChanged<int> onChanged;

  const _Segmented({required this.wide, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final height = wide ? 56.0 : 50.0;
    Widget tab(int i, String label, IconData icon) {
      final on = selected == i;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: '$label tab',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (on) return;
              HapticFeedback.selectionClick();
              onChanged(i);
            },
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: wide ? 22 : 20, color: on ? exBrandBold : exSubtle),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: exFont,
                        fontSize: wide ? 17 : 15,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                        color: on ? exInk : exSubtle,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: exNeutralBg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          // Sliding indicator under the active tab.
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: selected == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A1E2B45), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              tab(0, wide ? 'Use Template' : 'Template', Icons.library_music_outlined),
              tab(1, wide ? 'Record Custom Voice' : 'Record Voice', Icons.mic_none_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashed "Add template" tile shown after the template cards.
class _AddTemplateTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTemplateTile({required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add template',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedRRectPainter(radius: 16, color: exIndicator),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: exBrandBold, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Add template',
                      style: TextStyle(
                        fontFamily: exFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: exBrandBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TemplateCard extends StatelessWidget {
  final DemoTemplate template;
  final bool selected;
  final bool playing;
  final AudioPlayer player;
  final VoidCallback onSelect;
  final VoidCallback onTogglePlay;
  final VoidCallback? onDelete;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.playing,
    required this.player,
    required this.onSelect,
    required this.onTogglePlay,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = template;
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(exRadiusCard),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x1F1D4ED8), blurRadius: 16, offset: Offset(0, 6))]
              : const [BoxShadow(color: Color(0x0A1E2B45), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Material(
          color: selected ? exTint : Colors.white,
          borderRadius: BorderRadius.circular(exRadiusCard),
          child: InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(exRadiusCard),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(exRadiusCard),
                border: Border.all(color: selected ? exBrand : exBorder, width: selected ? 2 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: IconButton(
                            tooltip: playing
                                ? 'Pause preview of ${t.title}'
                                : 'Play preview of ${t.title}',
                            onPressed: onTogglePlay,
                            style: IconButton.styleFrom(
                              backgroundColor: playing
                                  ? exBrand
                                  : (selected ? Colors.white : exTint),
                              shape: const CircleBorder(),
                            ),
                            icon: Icon(
                              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: playing ? Colors.white : exBrandBold,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: exHeadingMd,
                              ),
                              if (t.duration > Duration.zero) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.white : exPageBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 13, color: exSubtle),
                                      const SizedBox(width: 4),
                                      Text(
                                        exDuration(t.duration),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: exSubtle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (t.description.isNotEmpty) const SizedBox(height: 4),
                              if (t.description.isNotEmpty)
                                Text(
                                  t.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: exSubtle,
                                  ),
                                ),
                              if (t.audioUrl.isEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Audio not set up yet',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: exSubtle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (onDelete != null)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              tooltip: 'Delete ${t.title}',
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: exDanger,
                                size: 22,
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: selected ? exHeroGradient : null,
                            color: selected ? null : Colors.white,
                            border: selected ? null : Border.all(color: exStrongBorder, width: 2),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                              : null,
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
                        return LinearProgressIndicator(
                          value: f,
                          minHeight: 3,
                          backgroundColor: Colors.transparent,
                          color: exBrand,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed placeholder box ("No numbers added yet.").
class _DashedNote extends StatelessWidget {
  final String text;
  const _DashedNote({required this.text});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _DashedRRectPainter(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle),
      ),
    ),
  );
}

class _DashedRRectPainter extends CustomPainter {
  final double radius;
  final Color color;
  const _DashedRRectPainter({this.radius = exRadiusControl, this.color = exStrongBorder});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.6));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "+91 98765 43210 ×" chip.
class _NumberChip extends StatelessWidget {
  final String number;
  final VoidCallback? onRemove;
  const _NumberChip({required this.number, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.only(left: 14),
    decoration: BoxDecoration(
      color: exTint,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFCFE0FF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.phone_rounded, size: 16, color: exBrandBold),
        const SizedBox(width: 6),
        Text(
          formatIndianMobile(number),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
        ),
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: 'Remove ${formatIndianMobile(number)}',
            onPressed: onRemove,
            icon: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Color(0xFFCFE0FF), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 14, color: exInk),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Attendees who are called on every demo.
class _TeamCard extends StatelessWidget {
  final List<Attendee> team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(exRadiusCard),
      border: Border.all(color: const Color(0xFFEDF1F6)),
      boxShadow: exCardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: exAccentTeamBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, size: 20, color: exAccentTeam),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Attendees will also be called', style: exHeadingSm)),
          ],
        ),
        const SizedBox(height: 10),
        if (team.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('No attendees on this exhibition.', style: exBodyMd),
          )
        else
          for (final m in team)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(gradient: exHeroGradient, shape: BoxShape.circle),
                    child: Text(
                      exInitials(m.name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: exHeadingSm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatIndianMobile(m.mobile),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: exSubtle,
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}
