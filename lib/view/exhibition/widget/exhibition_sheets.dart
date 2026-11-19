import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/model/ExhibitionModel.dart';
import '../../../repository/app_url.dart';
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

// MARK: - Demo video on WhatsApp

/// True when a demo video link is configured (`AppUrl.exhibitionDemoVideoUrl`).
bool get exDemoVideoEnabled => AppUrl.exhibitionDemoVideoUrl.trim().isNotEmpty;

/// Opens WhatsApp with [number]'s chat and the demo video link prefilled.
/// Returns true when WhatsApp opened.
Future<bool> sendDemoVideoOnWhatsApp(
  BuildContext context, {
  required String number,
  String visitorName = '',
  String exhibitionName = '',
}) async {
  final uri = demoVideoWhatsAppUri(
    number: number,
    videoUrl: AppUrl.exhibitionDemoVideoUrl,
    visitorName: visitorName,
    exhibitionName: exhibitionName,
  );
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) exToast(context, 'Could not open WhatsApp', error: true);
  return ok;
}

// MARK: - Demo sent: success + "capture a lead?"

/// Ink screen with the success tick, and a sheet asking whether to capture
/// a lead. Returns true for "Yes, capture lead"; false for Skip / swipe down.
Future<bool> showDemoSentSheet(
  BuildContext context, {
  required int callCount,
  String exhibitionName = '',
  String visitorName = '',
  List<String> visitorNumbers = const [],
}) async {
  HapticFeedback.mediumImpact();
  final showWhatsApp =
      exDemoVideoEnabled && visitorNumbers.isNotEmpty && await isWhatsAppInstalled();
  if (!context.mounted) return false;
  final yes = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: exInk,
    elevation: 0,
    builder: (ctx) => ExTheme(
      child: _DemoSentSheet(
        callCount: callCount,
        exhibitionName: exhibitionName,
        visitorName: visitorName,
        visitorNumbers: showWhatsApp ? visitorNumbers : const [],
      ),
    ),
  );
  return yes == true;
}

class _DemoSentSheet extends StatefulWidget {
  final int callCount;
  final String exhibitionName;
  final String visitorName;
  final List<String> visitorNumbers;
  const _DemoSentSheet({
    required this.callCount,
    required this.exhibitionName,
    this.visitorName = '',
    this.visitorNumbers = const [],
  });

  @override
  State<_DemoSentSheet> createState() => _DemoSentSheetState();
}

class _DemoSentSheetState extends State<_DemoSentSheet> {
  /// Numbers whose WhatsApp chat was opened from this sheet.
  final Set<String> _shared = {};

  Future<void> _whatsApp(String number) async {
    final ok = await sendDemoVideoOnWhatsApp(
      context,
      number: number,
      visitorName: widget.visitorName,
      exhibitionName: widget.exhibitionName,
    );
    if (ok && mounted) setState(() => _shared.add(number));
  }

  Widget _videoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Send demo video on WhatsApp', style: exHeadingSm),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 176),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.visitorNumbers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = widget.visitorNumbers[i];
                final done = _shared.contains(n);
                return ExSecondaryButton(
                  label: done ? '${formatIndianMobile(n)} · opened' : formatIndianMobile(n),
                  icon: done ? Icons.check_rounded : Icons.ondemand_video_rounded,
                  color: exSuccess,
                  height: 48,
                  onPressed: () => _whatsApp(n),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: exBorder),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final callCount = widget.callCount;
    final sub = [
      '$callCount ${callCount == 1 ? 'call' : 'calls'} queued',
      if (widget.exhibitionName.isNotEmpty) widget.exhibitionName,
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
                  if (widget.visitorNumbers.isNotEmpty) ...[
                    _videoSection(),
                    const SizedBox(height: 18),
                  ],
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
  late String _savingLabel = _editing ? 'Updating…' : 'Saving…';

  /// Already-uploaded files (when editing) and newly picked local files.
  late final List<String> _existing = [...?widget.lead?.attachments];
  final List<_LocalFile> _picked = [];
  /// The API stores one media link per lead (`mediaUrl`).
  static const _maxFiles = 1;
  int get _fileCount => _existing.length + _picked.length;

  @override
  void dispose() {
    for (final c in [_school, _city, _contact, _number, _email, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  // Only school name and city are mandatory; number / email are optional
  // but must be valid when filled in.
  String? get _numberError {
    final n = _number.text.trim();
    if (!_tried || n.isEmpty) return null;
    return isValidIndianMobile(normalizeIndianMobile(n)) ? null : 'Enter a 10-digit mobile number';
  }

  String? get _emailError {
    final e = _email.text.trim();
    if (!_tried || e.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e) ? null : 'Enter a valid email';
  }

  // ── Attachments ──

  void _tooMany() => setState(() => _error = _maxFiles == 1
      ? 'Only one file can be attached. Remove it to add another.'
      : 'You can attach up to $_maxFiles files.');

  Future<void> _addFromCamera() async {
    if (_fileCount >= _maxFiles) return _tooMany();
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 2000);
      if (x == null || !mounted) return;
      setState(() => _picked.add(_LocalFile(x.path, x.name, isPdf: false)));
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open the camera. $e');
    }
  }

  Future<void> _addPhotos() async {
    if (_fileCount >= _maxFiles) return _tooMany();
    try {
      final xs = await ImagePicker()
          .pickMultiImage(imageQuality: 75, maxWidth: 2000, limit: _maxFiles - _fileCount);
      if (xs.isEmpty || !mounted) return;
      setState(() {
        for (final x in xs.take(_maxFiles - _fileCount)) {
          _picked.add(_LocalFile(x.path, x.name, isPdf: false));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open photos. $e');
    }
  }

  Future<void> _addPdfs() async {
    if (_fileCount >= _maxFiles) return _tooMany();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result.isEmpty || !mounted) return;
      setState(() {
        for (final f in result.where((f) => f.path != null).take(_maxFiles - _fileCount)) {
          _picked.add(_LocalFile(f.path!, f.name, isPdf: true));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open files. $e');
    }
  }

  /// Uploads newly picked files to S3; returns all attachment URLs.
  Future<List<String>> _uploadFiles() async {
    final repo = ref.read(exhibitionRepositoryProvider);
    final urls = [..._existing];
    for (var i = 0; i < _picked.length; i++) {
      if (mounted) {
        setState(() => _savingLabel = 'Uploading files ${i + 1}/${_picked.length}…');
      }
      final f = _picked[i];
      urls.add(await repo.uploadLeadFile(
        exhibitionId: widget.exhibitionId,
        path: f.path,
        fileName: f.name,
      ));
    }
    if (mounted) setState(() => _savingLabel = _editing ? 'Updating…' : 'Saving…');
    return urls;
  }

  /// Popup to choose the attachment type (camera, photos or PDF).
  Future<void> _pickAttachment() async {
    if (_fileCount >= _maxFiles) return _tooMany();
    FocusScope.of(context).unfocus();
    final choice = await _showSheet<int>(context, (ctx) {
      Widget option(int value, IconData icon, Color bg, Color fg, String title, String sub) =>
          InkWell(
            onTap: () => Navigator.pop(ctx, value),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Icon(icon, color: fg, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: exBodyTouch.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(sub, style: exBodySm),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: exSubtle),
                ],
              ),
            ),
          );
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _handle()),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Add attachment', style: exHeadingMd),
              ),
              const SizedBox(height: 8),
              option(0, Icons.photo_camera_outlined, exTint, exBrandBold, 'Take photo',
                  'Capture with the camera'),
              option(1, Icons.photo_library_outlined, exSuccessBg, exSuccess, 'Choose photos',
                  'Pick one or more from the gallery'),
              option(2, Icons.picture_as_pdf_outlined, exDangerBg, exDanger, 'PDF document',
                  'Pick a PDF file'),
            ],
          ),
        ),
      );
    });
    if (!mounted) return;
    switch (choice) {
      case 0:
        await _addFromCamera();
      case 1:
        await _addPhotos();
      case 2:
        await _addPdfs();
    }
  }

  Widget _attachmentsSection() {
    final full = _fileCount >= _maxFiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachment', style: exHeadingSm.copyWith(fontSize: 15)),
            const SizedBox(width: 6),
            Expanded(
              child: Text('(optional · photos or PDF)',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: exBodySm),
            ),
            if (_fileCount > 0) Text('$_fileCount/$_maxFiles', style: exBodySm),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ExSecondaryButton(
            label: 'Add attachment',
            icon: Icons.attach_file_rounded,
            height: 48,
            onPressed: _saving || full ? null : _pickAttachment,
          ),
        ),
        if (_fileCount > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final url in _existing)
                ExAttachmentTile(
                  url: url,
                  gallery: _existing,
                  onRemove: _saving ? null : () => setState(() => _existing.remove(url)),
                ),
              for (final f in _picked)
                ExAttachmentTile._local(
                  local: f,
                  onRemove: _saving ? null : () => setState(() => _picked.remove(f)),
                ),
            ],
          ),
        ],
      ],
    );
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
      final attachments = await _uploadFiles();
      final req = CaptureLeadRequest(
        schoolName: _school.text.trim(),
        city: _city.text.trim(),
        contactName: _contact.text.trim(),
        contactNumber: normalizeIndianMobile(_number.text.trim()),
        contactEmail: _email.text.trim(),
        notes: _notes.text.trim(),
        interestLevel: _level,
        attachments: attachments,
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
          _savingLabel = _editing ? 'Updating…' : 'Saving…';
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
                    hint: 'Enter school name',
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
                    hint: 'Enter city',
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
                  hint: 'Enter name',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                pair(
                  ExField(
                    label: 'Contact number',
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
                    controller: _email,
                    hint: 'Enter email address',
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
                  hint: 'Enter notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _attachmentsSection(),
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
                label: _editing ? 'Update Lead' : 'Save Lead',
                loadingLabel: _savingLabel,
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

/// A photo / PDF picked on the device, not uploaded yet.
class _LocalFile {
  final String path;
  final String name;
  final bool isPdf;
  const _LocalFile(this.path, this.name, {required this.isPdf});
}

/// Thumbnail for a lead attachment (local file or uploaded URL), with an
/// optional remove button. Tapping an uploaded photo opens a full-screen
/// viewer; a PDF opens in the system viewer.
class ExAttachmentTile extends StatelessWidget {
  final _LocalFile? local;
  final String? url;
  final VoidCallback? onRemove;
  final double size;

  /// All attachment URLs of the lead, so the viewer can swipe between photos.
  final List<String> gallery;

  const ExAttachmentTile({
    super.key,
    this.url,
    this.onRemove,
    this.size = 84,
    this.gallery = const [],
  }) : local = null;

  const ExAttachmentTile._local({required _LocalFile this.local, this.onRemove})
      : url = null,
        size = 84,
        gallery = const [];

  void _open(BuildContext context) {
    final u = url;
    if (u == null) return;
    if (_isPdf) {
      launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
      return;
    }
    final photos = gallery.where((g) => !isPdfUrl(g)).toList();
    if (!photos.contains(u)) photos.insert(0, u);
    showExPhotoViewer(context, photos, initial: photos.indexOf(u));
  }

  bool get _isPdf => local?.isPdf ?? isPdfUrl(url ?? '');

  String get _name {
    if (local != null) return local!.name;
    final path = Uri.tryParse(url ?? '')?.pathSegments;
    return (path == null || path.isEmpty) ? 'File' : Uri.decodeComponent(path.last);
  }

  @override
  Widget build(BuildContext context) {
    final small = size < 72;
    final Widget content = _isPdf
        ? Container(
            color: exDangerBg,
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: exDanger, size: small ? 24 : 28),
                const SizedBox(height: 4),
                Text(small ? 'PDF' : _name,
                    maxLines: small ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: exInk)),
              ],
            ),
          )
        : local != null
            ? Image.file(File(local!.path), fit: BoxFit.cover, cacheWidth: 240)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: 240,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: exNeutralBg,
                  child: Icon(Icons.image_not_supported_outlined, color: exSubtle),
                ),
              );
    return Semantics(
      label: _isPdf ? 'PDF $_name' : 'Photo $_name',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: exBorder),
                ),
                child: InkWell(
                  onTap: url == null ? null : () => _open(context),
                  child: content,
                ),
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: -8,
                right: -8,
                child: Material(
                  color: exInk,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool isPdfUrl(String url) => url.toLowerCase().split('?').first.endsWith('.pdf');

/// Full-screen, swipeable, pinch-to-zoom photo viewer.
Future<void> showExPhotoViewer(BuildContext context, List<String> urls, {int initial = 0}) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _PhotoViewer(urls: urls, initial: initial),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _PhotoViewer({required this.urls, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.urls[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const CircularProgressIndicator(color: Colors.white),
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                        size: 48),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    if (widget.urls.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text('${_index + 1} / ${widget.urls.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// MARK: - Demo detail (shown inside the expanded demo card)

/// Voice player, recipients with call status, and the capture-lead action of
/// one demo. Lives inside the demo card when it is expanded.
class DemoDetailPanel extends ConsumerStatefulWidget {
  final ExhibitionDemo demo;
  final VoidCallback onCaptureLead;
  final VoidCallback? onSendAgain;

  /// Named in the WhatsApp demo video message.
  final String exhibitionName;

  const DemoDetailPanel({
    super.key,
    required this.demo,
    required this.onCaptureLead,
    this.onSendAgain,
    this.exhibitionName = '',
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
    // Every number dialled with its call status, from the demo detail API.
    final detail = d.id.isEmpty ? null : ref.watch(exhibitionDemoDetailProvider(d.id));
    final fetched = detail?.value?.recipients ?? const <DemoRecipient>[];
    final recipients = fetched.isNotEmpty ? fetched : d.recipients;
    final loadingDetail = detail != null && detail.isLoading && recipients.isEmpty;
    final canWhatsApp =
        exDemoVideoEnabled && (ref.watch(whatsAppInstalledProvider).value ?? false);
    final detailFailed = detail != null && detail.hasError && recipients.isEmpty;
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
        Row(
          children: [
            Expanded(
              child: Text(
                  'Recipients (${recipients.isEmpty ? d.recipientCount : recipients.length})',
                  style: exHeadingSm),
            ),
            if (detail != null)
              SizedBox(
                width: 44,
                height: 44,
                child: detail.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(strokeWidth: 2, color: exBrandBold),
                      )
                    : IconButton(
                        tooltip: 'Refresh call status',
                        onPressed: () => ref.invalidate(exhibitionDemoDetailProvider(d.id)),
                        icon: const Icon(Icons.refresh_rounded, color: exBrandBold),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (loadingDetail)
          const Text('Loading call details…', style: exBodyMd)
        else if (detailFailed)
          Text("Couldn't load call details. Tap refresh to try again.",
              style: exBodyMd.copyWith(color: exDanger))
        else if (recipients.isEmpty)
          const Text('Call details are not available yet.', style: exBodyMd)
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: exBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < recipients.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: exBorder),
                  _RecipientRow(
                    r: recipients[i],
                    onWhatsApp: canWhatsApp && !recipients[i].isTeam && recipients[i].number.isNotEmpty
                        ? () => sendDemoVideoOnWhatsApp(
                              context,
                              number: recipients[i].number,
                              visitorName: d.visitorName,
                              exhibitionName: widget.exhibitionName,
                            )
                        : null,
                  ),
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
                  label: 'Initiate Again',
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

  /// Sends the demo video link to this number on WhatsApp (visitors only).
  final VoidCallback? onWhatsApp;
  const _RecipientRow({required this.r, this.onWhatsApp});

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
                if (r.error.isNotEmpty)
                  Text(r.error, style: exBodySm.copyWith(color: exDanger)),
                if (onWhatsApp != null)
                  TextButton.icon(
                    onPressed: onWhatsApp,
                    style: TextButton.styleFrom(
                      foregroundColor: exSuccess,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                          fontFamily: exFont, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                    label: const Text('Send video on WhatsApp'),
                  ),
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

/// Record a new voice template for [exhibitionId] and upload it. Returns
/// true when saved.
Future<bool> showAddTemplateSheet(BuildContext context, {required String exhibitionId}) async {
  final saved = await _showSheet<bool>(
    context,
    (_) => _AddTemplateSheet(exhibitionId: exhibitionId),
    full: true,
  );
  return saved == true;
}

class _AddTemplateSheet extends ConsumerStatefulWidget {
  final String exhibitionId;
  const _AddTemplateSheet({required this.exhibitionId});

  @override
  ConsumerState<_AddTemplateSheet> createState() => _AddTemplateSheetState();
}

class _AddTemplateSheetState extends ConsumerState<_AddTemplateSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _path;
  Duration _length = Duration.zero;

  /// Offer this template in every exhibition, not just this one.
  bool _common = false;
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
            exhibitionId: widget.exhibitionId,
            name: _title.text.trim(),
            description: _description.text.trim(),
            audioPath: _path!,
            common: _common,
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
                  hint: 'Enter template name',
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
                  hint: 'Enter description',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _common,
                  activeTrackColor: exBrand,
                  onChanged: _saving ? null : (v) => setState(() => _common = v),
                  title: Text('Use in all exhibitions', style: exHeadingSm.copyWith(fontSize: 15)),
                  subtitle: const Text('Off: only this exhibition offers it.', style: exBodySm),
                ),
                const SizedBox(height: 8),
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
