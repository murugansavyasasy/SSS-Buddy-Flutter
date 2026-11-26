import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/model/ExhibitionModel.dart';
import '../../../components/demo_video_whatsapp.dart';
import '../../../core/aws/s3_upload_service.dart';
import '../../../viewModel/exhibition_viewmodel.dart';
import '../showcase/sc_spotlight.dart';
import '../showcase/showcase_content.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => ExTheme(
        child: full
            ? FractionallySizedBox(heightFactor: 0.92, child: builder(ctx))
            : builder(ctx),
      ),
    );

Widget _handle() => Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: exStrongBorder,
        borderRadius: BorderRadius.circular(3),
      ),
    );

/// Sheet header: grab handle, gradient icon bubble, title, optional
/// subtitle / extra line and a round close button.
class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final VoidCallback? onClose;

  const _SheetHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.extra,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 14),
        child: Column(
          children: [
            _handle(),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: exHeroGradient,
                    borderRadius: BorderRadius.circular(exRadiusControl + 2),
                    boxShadow: exBrandGlow,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: exHeadingLg.copyWith(
                              fontSize: 22, height: 1.25, fontWeight: FontWeight.w700)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: exBodyMd),
                      ],
                      if (extra != null) ...[const SizedBox(height: 8), extra!],
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    style: IconButton.styleFrom(backgroundColor: exPageBg),
                    icon: const Icon(Icons.close_rounded, color: exInk, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// MARK: - Demo video on WhatsApp

/// True when a fallback demo video link is configured
/// (`AppUrl.exhibitionDemoVideoUrl`).
bool get exDemoVideoEnabled => demoVideoEnabled;

/// Opens [number]'s chat with the demo video links prefilled: in the
/// WhatsApp app when installed, else in WhatsApp Web (browser; the user must
/// be signed in there). Returns true when it opened.
Future<bool> sendDemoVideoOnWhatsApp(
  BuildContext context, {
  required String number,
  String visitorName = '',
  String exhibitionName = '',
}) async {
  final ok = await launchDemoVideoWhatsApp(
    context,
    number: number,
    visitorName: visitorName,
    exhibitionName: exhibitionName,
  );
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
  final showWhatsApp = exDemoVideoEnabled && visitorNumbers.isNotEmpty;
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
          const ExSectionTitle(title: 'Send demo video on WhatsApp'),
          const SizedBox(height: 12),
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

  /// Frosted chip on the ink backdrop ("2 calls queued").
  Widget _successChip(IconData icon, String text) => Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: exIndicator),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final callCount = widget.callCount;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          // ── Success on ink ──
          // Scales down on short phones so the lead card below always fits.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 8, bottom: 8),
              child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    // Tick inside layered success rings.
                    child: Container(
                      width: 168,
                      height: 168,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: exBrand.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 132,
                        height: 132,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: exBrand.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [exBrand, Color(0xFF22D3EE)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: exBrand.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Demo call initiated',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(height: 14),
                  // Summary chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _successChip(Icons.phone_in_talk_rounded,
                            '$callCount ${callCount == 1 ? 'call' : 'calls'} queued'),
                        if (widget.visitorName.trim().isNotEmpty)
                          _successChip(Icons.person_rounded, widget.visitorName.trim()),
                        if (widget.exhibitionName.isNotEmpty)
                          _successChip(Icons.storefront_rounded, widget.exhibitionName),
                      ],
                    ),
                  ),
                ],
              ),
              ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: exAccentLeadBg,
                          borderRadius: BorderRadius.circular(exRadiusControl + 2),
                        ),
                        child: const Icon(Icons.star_rounded, color: exAccentLead, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Did the visitor like the demo?',
                                style: TextStyle(
                                    fontSize: 21,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: exInk)),
                            SizedBox(height: 4),
                            Text('Capture this school as a lead?',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500, color: exSubtle)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ExPrimaryButton(
                    label: 'Yes, capture lead',
                    icon: Icons.star_rounded,
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

/// Capture Lead form. The lead is saved against the exhibition
/// ([exhibitionId]); [demo] only prefills the visitor. Returns true when saved.
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
  late final _designation = TextEditingController(text: widget.lead?.contactDesignation ?? '');
  late final _notes = TextEditingController(text: widget.lead?.notes ?? '');
  /// New leads start at Excellent; edits keep the saved level.
  late InterestLevel _level = widget.lead?.interestLevel ?? InterestLevel.excellent;

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
    for (final c in [_school, _city, _contact, _designation, _number, _email, _notes]) {
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

  /// Popup to choose the attachment source (camera or photos).
  Future<void> _pickAttachment() async {
    if (_fileCount >= _maxFiles) return _tooMany();
    FocusScope.of(context).unfocus();
    final choice = await _showSheet<int>(context, (ctx) {
      Widget option(int value, IconData icon, Color bg, Color fg, String title, String sub) =>
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ExCard(
            onTap: () => Navigator.pop(ctx, value),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(exRadiusControl)),
                    child: Icon(icon, color: fg, size: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('Add attachment',
                    style: exHeadingMd.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              option(0, Icons.photo_camera_outlined, exTint, exBrandBold, 'Take photo',
                  'Capture with the camera'),
              option(1, Icons.photo_library_outlined, exSuccessBg, exSuccess, 'Choose photos',
                  'Pick one or more from the gallery'),
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
    }
  }

  Widget _attachmentsSection() {
    final full = _fileCount >= _maxFiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachment', style: exHeadingSm.copyWith(fontSize: 14, color: const Color(0xFF3A4A60))),
            const SizedBox(width: 6),
            Expanded(
              child: Text('(optional · photo)',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: exBodySm),
            ),
            if (_fileCount > 0)
              ExPill(
                label: '$_fileCount/$_maxFiles',
                background: exTint,
                foreground: exBrandBold,
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ExSecondaryButton(
            label: 'Add attachment',
            icon: Icons.add_photo_alternate_outlined,
            color: exBrandBold,
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
    // Jump back to the step that needs fixing.
    if (_school.text.trim().isEmpty || _city.text.trim().isEmpty) {
      setState(() => _step = 0);
      return;
    }
    if (_numberError != null || _emailError != null) {
      setState(() => _step = 2);
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
        contactDesignation: _designation.text.trim(),
        notes: _notes.text.trim(),
        interestLevel: _level,
        attachments: attachments,
        // Keep the demo link when editing too (the PUT replaces the lead).
        demoId: widget.demo?.id ?? widget.lead?.demoId ?? '',
      );
      final repo = ref.read(exhibitionRepositoryProvider);
      if (_editing) {
        await repo.updateLead(widget.lead!.id, req);
      } else {
        await repo.captureLead(exhibitionId: widget.exhibitionId, req: req);
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

  // ── Step flow: School → Interest → Contact → Notes & photo → Review ──

  static const _reviewStep = 4;

  /// New leads start at the first question; edits open on the summary.
  late int _step = _editing ? _reviewStep : 0;

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _step = step;
    });
  }

  /// Validates the current step (same rules as before) and moves on.
  void _next() {
    switch (_step) {
      case 0:
        if (_school.text.trim().isEmpty || _city.text.trim().isEmpty) {
          setState(() => _tried = true);
          return;
        }
      case 2:
        final wasTried = _tried;
        _tried = true;
        if (_numberError != null || _emailError != null) {
          setState(() {});
          return;
        }
        _tried = wasTried;
      case _reviewStep:
        _save();
        return;
    }
    _goTo(_step + 1);
  }

  bool get _contactEmpty =>
      _contact.text.trim().isEmpty &&
      _designation.text.trim().isEmpty &&
      _number.text.trim().isEmpty &&
      _email.text.trim().isEmpty;

  String get _nextLabel => switch (_step) {
        _reviewStep => _editing ? 'Update Lead' : 'Save Lead',
        3 => _notes.text.trim().isEmpty && _fileCount == 0 ? 'Skip to review' : 'Review',
        2 => _contactEmpty ? 'Skip' : 'Next',
        _ => 'Next',
      };

  ({String sub, IconData icon}) _levelInfo(InterestLevel l) => switch (l) {
        InterestLevel.excellent => (
            sub: 'Ready to move forward',
            icon: Icons.local_fire_department_rounded
          ),
        InterestLevel.good => (sub: 'Interested, needs a follow-up', icon: Icons.thumb_up_alt_rounded),
        InterestLevel.average => (sub: 'Just exploring for now', icon: Icons.trending_flat_rounded),
      };

  void _rebuildIfTried(String _) {
    if (_tried) setState(() {});
  }

  Widget _schoolStep() {
    final schoolError = _tried && _school.text.trim().isEmpty ? 'School name is required' : null;
    final cityError = _tried && _city.text.trim().isEmpty ? 'City is required' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExQuestion(
          icon: Icons.school_rounded,
          title: 'Which school is interested?',
          subtitle: 'Tell us the school and the city it is in.',
        ),
        const SizedBox(height: 24),
        ExBigInput(
          controller: _school,
          hint: 'School name',
          icon: Icons.apartment_rounded,
          errorText: schoolError,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: _rebuildIfTried,
        ),
        const SizedBox(height: 14),
        ExBigInput(
          controller: _city,
          hint: 'City',
          icon: Icons.location_on_rounded,
          errorText: cityError,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: _rebuildIfTried,
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }

  Widget _interestStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExQuestion(
            icon: Icons.favorite_rounded,
            title: 'How interested are they?',
            subtitle: _school.text.trim().isEmpty
                ? 'Pick the one that fits best.'
                : 'Pick the one that fits ${_school.text.trim()} best.',
            color: exAccentLead,
            background: exAccentLeadBg,
          ),
          const SizedBox(height: 24),
          for (final (i, l) in InterestLevel.values.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            Builder(builder: (_) {
              final (bg, fg) = interestLevelColors(l);
              final info = _levelInfo(l);
              return ExAppear(
                index: 3 + i,
                child: ExChoiceCard(
                  icon: info.icon,
                  title: l.label,
                  subtitle: info.sub,
                  color: fg,
                  background: bg,
                  selected: _level == l,
                  onTap: () => setState(() => _level = l),
                ),
              );
            }),
          ],
        ],
      );

  Widget _contactStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExQuestion(
            icon: Icons.person_rounded,
            title: 'Who should we talk to?',
            subtitle: 'The person to follow up with. You can skip this.',
            optional: true,
            color: exAccentTeam,
            background: exAccentTeamBg,
          ),
          const SizedBox(height: 24),
          ExBigInput(
            controller: _contact,
            hint: 'Contact name',
            icon: Icons.badge_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          ExBigInput(
            controller: _designation,
            hint: 'Designation (e.g. Principal)',
            icon: Icons.work_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          ExBigInput(
            controller: _number,
            hint: '10-digit mobile',
            prefixText: '+91  ',
            keyboardType: TextInputType.phone,
            errorText: _numberError,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            inputFormatters: [
              const ExAsciiDigitsFormatter(),
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 14),
          ExBigInput(
            controller: _email,
            hint: 'Email address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _next(),
          ),
        ],
      );

  Widget _notesStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExQuestion(
            icon: Icons.edit_note_rounded,
            title: 'Anything to remember?',
            subtitle: 'Add a note or a photo (e.g. a visiting card). Optional.',
            optional: true,
          ),
          const SizedBox(height: 24),
          ExBigInput(
            controller: _notes,
            hint: 'What did they ask about?',
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          ExAppear(
            index: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(exRadiusCard),
                boxShadow: exCardShadow,
              ),
              child: _attachmentsSection(),
            ),
          ),
        ],
      );

  Widget _reviewStepView() {
    final (bg, fg) = interestLevelColors(_level);
    final contact = [
      [_contact.text.trim(), _designation.text.trim()].where((s) => s.isNotEmpty).join(', '),
      if (_number.text.trim().isNotEmpty) formatIndianMobile(_number.text.trim()),
      _email.text.trim(),
    ].where((s) => s.isNotEmpty).join(' · ');
    final school = [_school.text.trim(), _city.text.trim()].where((s) => s.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExQuestion(
          icon: Icons.fact_check_rounded,
          title: _editing ? 'Review and update' : 'Looks good?',
          subtitle: 'Tap any line to change it.',
          color: exSuccess,
          background: exSuccessBg,
        ),
        const SizedBox(height: 20),
        ExAppear(
          index: 3,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(exRadiusCard),
              boxShadow: exCardShadow,
            ),
            child: Column(
              children: [
                ExSummaryRow(
                  icon: Icons.school_rounded,
                  label: 'School',
                  value: school,
                  onEdit: _saving ? null : () => _goTo(0),
                ),
                const Divider(height: 1, color: exBorder),
                ExSummaryRow(
                  icon: _levelInfo(_level).icon,
                  label: 'Interest',
                  value: _level.label,
                  color: fg,
                  background: bg,
                  onEdit: _saving ? null : () => _goTo(1),
                ),
                const Divider(height: 1, color: exBorder),
                ExSummaryRow(
                  icon: Icons.person_rounded,
                  label: 'Contact',
                  value: contact.isEmpty ? 'Not added' : contact,
                  color: exAccentTeam,
                  background: exAccentTeamBg,
                  onEdit: _saving ? null : () => _goTo(2),
                ),
                const Divider(height: 1, color: exBorder),
                ExSummaryRow(
                  icon: Icons.edit_note_rounded,
                  label: 'Notes & photo',
                  value: [
                    _notes.text.trim().isEmpty ? 'No notes' : _notes.text.trim(),
                    if (_fileCount > 0) '$_fileCount photo',
                  ].join(' · '),
                  color: exAccentLead,
                  background: exAccentLeadBg,
                  onEdit: _saving ? null : () => _goTo(3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final body = switch (_step) {
      0 => _schoolStep(),
      1 => _interestStep(),
      2 => _contactStep(),
      3 => _notesStep(),
      _ => _reviewStepView(),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ColoredBox(
        color: exPageBg,
        child: Column(
          children: [
            // ── Header: title, source pill, progress ──
            ColoredBox(
              color: Colors.white,
              child: Column(
                children: [
                  _SheetHeader(
                    icon: _editing ? Icons.edit_note_rounded : Icons.star_rounded,
                    title: _editing ? 'Edit lead' : 'Capture lead',
                    onClose: _saving ? null : () => Navigator.pop(context, false),
                    extra: _editing
                        ? null
                        : Align(
                            alignment: Alignment.centerLeft,
                            // Long visitor names end in "…" (ExPill).
                            child: ExPill(
                                icon: demo == null
                                    ? Icons.storefront_outlined
                                    : Icons.person_outline_rounded,
                                label: demo == null
                                    ? 'Exhibition lead'
                                    : 'From demo · ${demo.displayName}',
                                background: demo == null ? exNotes : exTint,
                                foreground: demo == null ? exInk : exBrandBold,
                              ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: ExStepProgress(
                      current: _step,
                      total: _reviewStep + 1,
                      label: _step == _reviewStep
                          ? 'Review'
                          : 'Step ${_step + 1} of $_reviewStep',
                    ),
                  ),
                ],
              ),
            ),
            // ── One question at a time ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A School Chimes solution on top for the visitor to read
                    // while their details are entered (not when editing).
                    if (!_editing) ...[
                      ScSpotlightBanner(
                        spot: scCaptureLeadSpotlights[_step.clamp(0, scCaptureLeadSpotlights.length - 1)],
                      ),
                      const SizedBox(height: 22),
                    ],
                    ExStepSwitcher(step: _step, child: body),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      ExInlineNote(message: _error!),
                    ],
                  ],
                ),
              ),
            ),
            ExStepBar(
              onBack: _step == 0 ? null : () => _goTo(_step - 1),
              nextLabel: _nextLabel,
              nextIcon: _step == _reviewStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
              loading: _saving,
              loadingLabel: _savingLabel,
              onNext: _next,
            ),
          ],
        ),
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
      _showPdfActions(context, u);
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
                  borderRadius: BorderRadius.circular(exRadiusControl),
                  side: const BorderSide(color: exBorder),
                ),
                elevation: 1,
                shadowColor: const Color(0x2214243B),
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
                  color: exDanger,
                  elevation: 2,
                  shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
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

// MARK: - Attachment download / share

/// File name of an attachment link (last path segment).
String attachmentFileName(String url) {
  final segs = Uri.tryParse(url)?.pathSegments ?? const <String>[];
  final last = segs.isEmpty ? '' : Uri.decodeComponent(segs.last).trim();
  return last.isEmpty ? 'attachment' : last;
}

/// Downloads the attachment and opens the system "Save to…" dialog
/// (Files / Downloads). Returns when saved, cancelled or failed.
Future<void> downloadAttachment(BuildContext context, String url) async {
  final repo = ProviderScope.containerOf(context, listen: false).read(exhibitionRepositoryProvider);
  try {
    final bytes = await repo.downloadAttachment(url);
    final saved = await FilePicker.saveFile(
      fileName: attachmentFileName(url),
      bytes: bytes,
      mimeType: S3UploadService.contentTypeFor(url.split('?').first),
    );
    if (saved != null && context.mounted) exToast(context, 'Downloaded');
  } catch (e) {
    if (context.mounted) exToast(context, e.toString(), error: true);
  }
}

/// Downloads the attachment to a temp file and opens the share sheet.
Future<void> shareAttachment(BuildContext context, String url) async {
  final repo = ProviderScope.containerOf(context, listen: false).read(exhibitionRepositoryProvider);
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  try {
    final bytes = await repo.downloadAttachment(url);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${attachmentFileName(url)}');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: S3UploadService.contentTypeFor(file.path))],
      sharePositionOrigin: origin,
    ));
  } catch (e) {
    if (context.mounted) exToast(context, e.toString(), error: true);
  }
}

/// PDF tile: Open / Download / Share.
Future<void> _showPdfActions(BuildContext context, String url) => _showSheet<void>(
      context,
      (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: exDangerBg, borderRadius: BorderRadius.circular(exRadiusControl)),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: exDanger),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(attachmentFileName(url),
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: exHeadingSm),
                    ),
                  ],
                ),
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(exRadiusControl)),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: exTint, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.open_in_new_rounded, color: exBrandBold, size: 22),
                ),
                title: const Text('Open', style: exHeadingSm),
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(exRadiusControl)),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: exTint, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.download_rounded, color: exBrandBold, size: 22),
                ),
                title: const Text('Download', style: exHeadingSm),
                onTap: () {
                  Navigator.pop(ctx);
                  downloadAttachment(context, url);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(exRadiusControl)),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: exTint, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.ios_share_rounded, color: exBrandBold, size: 22),
                ),
                title: const Text('Share', style: exHeadingSm),
                onTap: () {
                  Navigator.pop(ctx);
                  shareAttachment(context, url);
                },
              ),
            ],
          ),
        ),
      ),
    );

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

  /// 'download' / 'share' while that action runs.
  String? _busy;

  Future<void> _run(String action, BuildContext anchor) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    final url = widget.urls[_index];
    if (action == 'download') {
      await downloadAttachment(anchor, url);
    } else {
      await shareAttachment(anchor, url);
    }
    if (mounted) setState(() => _busy = null);
  }

  Widget _action(String action, IconData icon, String tooltip) => Builder(
        builder: (anchor) => IconButton(
          tooltip: tooltip,
          onPressed: _busy == null ? () => _run(action, anchor) : null,
          icon: _busy == action
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, color: Colors.white, size: 26),
        ),
      );

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
                    _action('download', Icons.download_rounded, 'Download'),
                    _action('share', Icons.ios_share_rounded, 'Share'),
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
    final canWhatsApp = exDemoVideoEnabled;
    final detailFailed = detail != null && detail.hasError && recipients.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [exTint, Color(0xFFF3F8FF)],
            ),
            borderRadius: BorderRadius.circular(exRadiusControl + 2),
            border: Border.all(color: exIndicator.withValues(alpha: 0.5)),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: exHeroGradient,
                      boxShadow: exBrandGlow,
                    ),
                    child: IconButton(
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
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: f,
                                  minHeight: 6,
                                  backgroundColor: Colors.white,
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
              child: ExSectionTitle(
                title: 'Recipients',
                caption: '${recipients.isEmpty ? d.recipientCount : recipients.length}',
              ),
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
                        style: IconButton.styleFrom(backgroundColor: exTint),
                        icon: const Icon(Icons.refresh_rounded, color: exBrandBold, size: 20),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(exRadiusControl + 2),
              border: Border.all(color: exBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < recipients.length; i++) ...[
                  ExAppear(
                    index: i,
                    offset: 8,
                    child: _RecipientRow(
                    first: i == 0,
                    last: i == recipients.length - 1,
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
              borderRadius: BorderRadius.circular(exRadiusControl),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: exSuccess),
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
                  icon: Icons.star_rounded,
                  height: 48,
                  onPressed: widget.onCaptureLead,
                ),
              ),
            if (!d.hasLead && widget.onSendAgain != null) const SizedBox(width: 10),
            if (widget.onSendAgain != null)
              Expanded(
                child: ExSecondaryButton(
                  label: 'Initiate Again',
                  icon: Icons.replay_rounded,
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
  final bool first;
  final bool last;

  /// Sends the demo video link to this number on WhatsApp (visitors only).
  final VoidCallback? onWhatsApp;
  const _RecipientRow({required this.r, this.onWhatsApp, this.first = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = callStatusColors(r.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail with a status-coloured node.
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 16,
                  color: first ? Colors.transparent : exBorder,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: fg,
                    shape: BoxShape.circle,
                    border: Border.all(color: bg, width: 3),
                  ),
                ),
                Expanded(
                  child: Container(width: 2, color: last ? Colors.transparent : exBorder),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatIndianMobile(r.number),
                            style: exHeadingSm.copyWith(fontSize: 15)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ExPill(
                              label: r.isTeam ? 'Attendee' : 'Visitor',
                              icon: r.isTeam ? Icons.badge_rounded : Icons.person_rounded,
                              background: r.isTeam ? exTint : exVisitorBg,
                              foreground: exInk,
                            ),
                            if (r.name.isNotEmpty)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(r.name,
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: exBodySm),
                              ),
                          ],
                        ),
                        if (r.error.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r.error, style: exBodySm.copyWith(color: exDanger)),
                        ],
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
                            label: const Text('Send demo video on WhatsApp'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExPill(label: r.status.label, background: bg, foreground: fg, dot: true),
                ],
              ),
            ),
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
  String _savingLabel = 'Uploading voice…';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    final p = _path;
    // On Web the voice is a blob:/data: URL, not a file on disk.
    if (p != null && !kIsWeb) File(p).delete().catchError((_) => File(p));
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _error = null;
    });
    if (_title.text.trim().isEmpty || _path == null) return;
    setState(() {
      _saving = true;
      _savingLabel = 'Uploading voice…';
    });
    try {
      await ref.read(exhibitionRepositoryProvider).createTemplate(
            exhibitionId: widget.exhibitionId,
            name: _title.text.trim(),
            description: _description.text.trim(),
            audioPath: _path!,
            common: _common,
            onProgress: (f) {
              if (!mounted) return;
              setState(() => _savingLabel =
                  f >= 0.99 ? 'Saving template…' : 'Uploading voice… ${(f * 100).round()}%');
            },
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
          _SheetHeader(
            icon: Icons.graphic_eq_rounded,
            title: 'Add voice template',
            subtitle: 'Record once, play at every demo',
            onClose: _saving ? null : () => Navigator.pop(context, false),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tileColor: exPageBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(exRadiusControl)),
                  value: _common,
                  activeTrackColor: exBrand,
                  onChanged: _saving ? null : (v) => setState(() => _common = v),
                  title: Text('Use this template in all exhibitions',
                      style: exHeadingSm.copyWith(fontSize: 15)),
                  subtitle: const Text('Off: only this exhibition offers it.', style: exBodySm),
                ),
                const SizedBox(height: 18),
                const ExSectionTitle(title: 'Voice'),
                const SizedBox(height: 10),
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
              boxShadow: [BoxShadow(color: Color(0x1414243B), blurRadius: 16, offset: Offset(0, -4))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SafeArea(
              top: false,
              child: ExPrimaryButton(
                label: 'Save Template',
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
