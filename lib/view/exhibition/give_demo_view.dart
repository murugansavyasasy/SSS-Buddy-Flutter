import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../auth/model/ExhibitionModel.dart';
import '../../provider/user_session_provider.dart';
import '../../viewModel/exhibition_viewmodel.dart';
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

  /// Opens on a later step (screenshot tests only).
  @visibleForTesting
  final int initialStep;

  /// Send an earlier demo again: its voice, visitor name and numbers are
  /// prefilled and the flow opens on the review step (Back to edit).
  final ExhibitionDemo? resendFrom;

  const GiveDemoView({
    super.key,
    required this.exhibition,
    this.initialStep = 0,
    this.resendFrom,
  });

  @override
  ConsumerState<GiveDemoView> createState() => _GiveDemoViewState();
}

class _GiveDemoViewState extends ConsumerState<GiveDemoView> {
  late int _step = widget.initialStep;

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
      final templates = ref.read(exhibitionTemplatesProvider).value ?? const <DemoTemplate>[];
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
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: exPageBg,
            body: Column(
              children: [
                _header(wide),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 40 : 16,
                            wide ? 40 : 16,
                            wide ? 40 : 16,
                            24,
                          ),
                          child: wide ? _stepBody(wide) : ExMaxWidth(child: _stepBody(wide)),
                        ),
                      ),
                      if (wide) _summaryPanel(),
                    ],
                  ),
                ),
                _footer(wide),
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

  Widget _header(bool wide) {
    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: exInk, size: 26),
            onPressed: _close,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Give Demo', style: exHeadingMd),
              Text(
                widget.exhibition.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: exBodyMd,
              ),
            ],
          ),
        ),
      ],
    );
    final stepper = _Stepper(
      step: _step,
      wide: wide,
      onTap: (i) {
        if (i < _step && !_sending) setState(() => _step = i);
      },
    );
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: exBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(wide ? 24 : 8, 8, wide ? 24 : 16, wide ? 8 : 12),
          child: wide
              ? SizedBox(
                  height: 72,
                  child: Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: titleBlock,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Center(
                          child: FittedBox(fit: BoxFit.scaleDown, child: stepper),
                        ),
                      ),
                      const SizedBox(width: 120),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.only(left: 8), child: stepper),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _footer(bool wide) {
    final primary = _step < 2
        ? ExPrimaryButton(
            label: 'Continue',
            trailingIcon: wide ? Icons.chevron_right_rounded : null,
            height: 56,
            onPressed: _next,
          )
        : ExPrimaryButton(
            label: 'Send Demo Call',
            height: 56,
            loading: _sending,
            loadingLabel: _sendPhase,
            onPressed: _send,
          );
    final back = SizedBox(
      width: wide ? null : 56,
      height: 56,
      child: wide
          ? ExSecondaryButton(
              label: 'Back',
              icon: Icons.chevron_left_rounded,
              height: 56,
              onPressed: _sending ? null : _back,
            )
          : OutlinedButton(
              onPressed: _sending ? null : _back,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: exStrongBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: exInk, size: 28),
            ),
    );
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x141E2B45), blurRadius: 28, offset: Offset(0, -10))],
      ),
      padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 12, wide ? 40 : 16, 12),
      child: SafeArea(
        top: false,
        child: wide
            ? Row(
                children: [
                  Text(
                    'Step ${_step + 1} of 3',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: exSubtle,
                    ),
                  ),
                  const Spacer(),
                  if (_step > 0) ...[back, const SizedBox(width: 12)],
                  SizedBox(width: 320, child: primary),
                ],
              )
            : Row(
                children: [
                  if (_step > 0) ...[back, const SizedBox(width: 10)],
                  Expanded(child: primary),
                ],
              ),
      ),
    );
  }

  Widget _title(String t, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: exHeadingLg.copyWith(fontSize: 28, height: 36 / 28)),
        const SizedBox(height: 6),
        Text(
          sub,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle),
        ),
      ],
    ),
  );

  Widget _phoneTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(t, style: exHeadingLg),
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

  Widget _voiceStep(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (wide)
        _title('Choose a voice', 'Play a ready-made template or record a message for this visitor.')
      else
        _phoneTitle('Choose a voice'),
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: wide ? 460 : double.infinity,
          child: _Segmented(
            wide: wide,
            selected: _voice == _Voice.template ? 0 : 1,
            onChanged: (i) => _setVoice(i == 0 ? _Voice.template : _Voice.record),
          ),
        ),
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
    final saved = await showAddTemplateSheet(context);
    if (!saved || !mounted) return;
    ref.invalidate(exhibitionTemplatesProvider);
    exToast(context, 'Template added');
  }

  Future<void> _deleteTemplate(DemoTemplate t) async {
    final ok = await showExConfirmDialog(
      context,
      title: 'Delete this template?',
      message: '"${t.title}" will no longer be offered for new demos. Demos already sent are not affected.',
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
    ref.invalidate(exhibitionTemplatesProvider);
    exToast(context, 'Template deleted');
  }

  Widget _templateCards(bool wide) {
    final async = ref.watch(exhibitionTemplatesProvider);
    final addButton = ExSecondaryButton(
      label: 'Add template',
      icon: Icons.add_rounded,
      color: exBrandBold,
      onPressed: _addTemplate,
    );
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
        onAction: () => ref.invalidate(exhibitionTemplatesProvider),
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
      selected: _template != null &&
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
      onDelete: t.id != '__previous__' &&
              user != null &&
              t.isCreatedBy(userId: user.userId, userName: user.employeeName)
          ? () => _deleteTemplate(t)
          : null,
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in list) ...[card(t), const SizedBox(height: 12)],
          addButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < (list.length + 1) ~/ 2; r++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card(list[r * 2])),
                const SizedBox(width: 16),
                Expanded(child: r * 2 + 1 < list.length ? card(list[r * 2 + 1]) : const SizedBox()),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Align(alignment: Alignment.centerLeft, child: SizedBox(width: 260, child: addButton)),
      ],
    );
  }

  // Step 2

  Widget _visitorStep(bool wide) {
    final title = wide
        ? _title('Who is the demo for?', 'Add one or more visitor numbers. Each one gets a call.')
        : _phoneTitle('Who is the demo for?');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExField(
                label: 'Visitor name',
                required: true,
                controller: _visitorName,
                hint: 'e.g. Mrs. Lakshmi, Principal',
                errorText: _nameError ? 'Visitor name is required' : null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (v) => setState(() {
                  if (v.trim().isNotEmpty) _nameError = false;
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Visitor mobile numbers',
                      style: exHeadingSm.copyWith(fontSize: 15),
                    ),
                  ),
                  Text(
                    '${_numbers.length} ${_numbers.length == 1 ? 'number' : 'numbers'}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: exInk),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numberInput,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        const ExAsciiDigitsFormatter(),
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onSubmitted: (v) => _addNumbers([v]),
                      onChanged: (_) {
                        if (_numberError != null) setState(() => _numberError = null);
                      },
                      style: exBodyTouch,
                      decoration: exInputDecoration(
                        hint: '10-digit number',
                        prefixText: '+91',
                        errorText: _numberError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ExSecondaryButton(
                    label: 'Add',
                    onPressed: () {
                      if (_numberInput.text.trim().isEmpty) {
                        setState(() => _numberError = 'Enter a 10-digit mobile number');
                        return;
                      }
                      _addNumbers([_numberInput.text]);
                    },
                  ),
                ],
              ),
              if (_dupNote != null) ...[
                const SizedBox(height: 12),
                ExInlineNote(message: _dupNote!, error: false),
              ],
              if (_numbers.isEmpty) ...[
                const SizedBox(height: 12),
                const _DashedNote(text: 'No numbers added yet.'),
              ],
              if (_numbers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in _numbers)
                      _NumberChip(number: n, onRemove: () => setState(() => _numbers.remove(n))),
                  ],
                ),
              ],
              if (_step2Error) ...[
                const SizedBox(height: 16),
                const ExInlineNote(message: 'Add at least one visitor number to send the demo.'),
              ],
              const SizedBox(height: 24),
              _TeamCard(team: _team),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3

  Widget _reviewStep(bool wide) {
    final title = wide
        ? _title('Review & send', 'Check everything before the calls go out.')
        : _phoneTitle('Review & send');
    final total = _numbers.length + _team.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: exBorder),
                ),
                child: Column(
                  children: [
                    _reviewVoiceRow(),
                    _reviewRow('Visitor', Text(_visitorName.text.trim(), style: _strong)),
                    _reviewRow(
                      'Visitor numbers (${_numbers.length})',
                      _numbers.isEmpty
                          ? const Text('None added', style: exBodyMd)
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final n in _numbers)
                                  _smallChip(formatIndianMobile(n), exPageBg),
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
              if (!wide) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD5DCEC)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF4F6FA), Color(0xFFD9E0F0)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: exInk, size: 26),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$total ${total == 1 ? 'call' : 'calls'}', style: exHeadingXl),
                            Text(
                              '${_numbers.length} ${_numbers.length == 1 ? 'visitor' : 'visitors'}'
                              ' + ${_team.length} ${_team.length == 1 ? 'attendee' : 'attendees'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: exInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                backgroundColor: playing ? exInk : Colors.white,
                side: playing ? null : const BorderSide(color: exStrongBorder),
                shape: const CircleBorder(),
              ),
              icon: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_outlined,
                color: playing ? Colors.white : exInk,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voice', style: exBodyMd),
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
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: f,
                        minHeight: 4,
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

  /// iPad: Call summary panel on the right.
  Widget _summaryPanel() => Container(
    width: 360,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(left: BorderSide(color: exBorder)),
    ),
    padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
    child: SingleChildScrollView(child: _summaryContent()),
  );

  Widget _summaryContent() {
    final total = _numbers.length + _team.length;
    String voice;
    if (_voice == _Voice.template) {
      voice = _template?.title ?? 'Not chosen';
    } else {
      voice = _recordingPath == null ? 'Not chosen' : 'Recording · ${exDuration(_recordingLength)}';
    }
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Call summary', style: exHeadingMd),
        const SizedBox(height: 14),
        row('Voice', voice),
        row('Visitors', '${_numbers.length}'),
        row('Attendees', '${_team.length}'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: exBorder),
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total calls',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exSubtle),
              ),
            ),
            Text('$total', style: exHeadingXl),
          ],
        ),
      ],
    );
  }

  static const _strong = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk);

  Widget _smallChip(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: exInk),
    ),
  );

  Widget _reviewRow(String label, Widget value, {bool last = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: exBorder)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: exBodyMd),
        const SizedBox(height: 8),
        value,
      ],
    ),
  );
}

/// 1 Voice — 2 Visitors — 3 Review & Send.
/// Current: ink circle. Done: brand circle with a tick. Next: outlined.
class _Stepper extends StatelessWidget {
  final int step;
  final bool wide;
  final ValueChanged<int> onTap;

  const _Stepper({required this.step, required this.wide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final labels = ['Voice', 'Visitors', wide ? 'Review & Send' : 'Review'];
    final d = wide ? 36.0 : 28.0;
    final fs = wide ? 17.0 : 15.0;
    Widget line(int i) {
      final l = Container(height: 2, color: i <= step ? exIndicator : exBorder);
      return wide
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(width: 56, child: l),
            )
          : Expanded(
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: l),
            );
    }

    return Row(
      mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) line(i),
          Semantics(
            button: i < step,
            selected: i == step,
            label: 'Step ${i + 1}, ${labels[i]}',
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: d,
                      height: d,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < step
                            ? exBrand
                            : i == step
                            ? exInk
                            : Colors.white,
                        border: i > step ? Border.all(color: exStrongBorder, width: 1.5) : null,
                      ),
                      child: i < step
                          ? Icon(Icons.check_rounded, size: d * 0.5, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: fs - 1,
                                fontWeight: FontWeight.w600,
                                color: i == step ? Colors.white : exSubtle,
                              ),
                            ),
                    ),
                    SizedBox(width: wide ? 12 : 8),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: fs,
                        fontWeight: FontWeight.w600,
                        color: i <= step ? exInk : exSubtle,
                      ),
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

/// "Use Template | Record Custom Voice" segmented control.
class _Segmented extends StatelessWidget {
  final bool wide;
  final int selected;
  final ValueChanged<int> onChanged;

  const _Segmented({required this.wide, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(int i, String label, IconData icon) {
      final on = selected == i;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: on
                    ? const [
                        BoxShadow(color: Color(0x1A1E2B45), blurRadius: 6, offset: Offset(0, 2)),
                      ]
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: on ? exInk : exSubtle),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: wide ? 17 : 16,
                        fontWeight: FontWeight.w600,
                        color: on ? exInk : exSubtle,
                      ),
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
      height: wide ? 60 : 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E7EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          seg(0, wide ? 'Use Template' : 'Template', Icons.description_outlined),
          seg(1, wide ? 'Record Custom Voice' : 'Record voice', Icons.mic_none_rounded),
        ],
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
      child: Material(
        color: selected ? exTint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                            backgroundColor: playing ? exInk : Colors.white,
                            side: playing ? null : const BorderSide(color: exStrongBorder),
                            shape: const CircleBorder(),
                          ),
                          icon: Icon(
                            playing ? Icons.pause_rounded : Icons.play_arrow_outlined,
                            color: playing ? Colors.white : exInk,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: t.title,
                                children: [
                                  if (t.duration > Duration.zero)
                                    TextSpan(
                                      text: '  ${exDuration(t.duration)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: exSubtle,
                                      ),
                                    ),
                                ],
                              ),
                              style: exHeadingMd,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.description,
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
                            icon: const Icon(Icons.delete_outline_rounded, color: exDanger, size: 22),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? exBrand : Colors.white,
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
    );
  }
}

/// Dashed placeholder box ("No numbers added yet.").
class _DashedNote extends StatelessWidget {
  final String text;
  const _DashedNote({required this.text});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRectPainter(),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = exStrongBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)).deflate(0.6),
      );
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
  final VoidCallback onRemove;
  const _NumberChip({required this.number, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.only(left: 14),
    decoration: BoxDecoration(
      color: exTint,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFD5DCEC)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatIndianMobile(number),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: exInk),
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
              decoration: const BoxDecoration(color: Color(0xFFD5DCEC), shape: BoxShape.circle),
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
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: exBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attendees will also be called', style: exHeadingSm),
        const SizedBox(height: 8),
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Text(
                      exInitials(m.name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: exInk,
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
