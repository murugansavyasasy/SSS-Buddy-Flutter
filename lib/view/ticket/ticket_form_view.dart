import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TicketModel.dart';
import '../../components/app_motion.dart';
import '../../components/form_width.dart';
import '../../components/glass_card.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/ticket_viewmodel.dart';
import 'widget/ticket_common.dart';

/// Raise Ticket: app → description → priority → images / videos.
/// Pops with true when the ticket is saved.
class TicketFormView extends ConsumerStatefulWidget {
  const TicketFormView({super.key});

  @override
  ConsumerState<TicketFormView> createState() => _TicketFormViewState();
}

class _TicketFormViewState extends ConsumerState<TicketFormView> {
  static const _maxFiles = 5;
  static const _maxVideoMb = 50;
  static const _maxVideoLength = Duration(minutes: 3);
  static const _maxDescription = 1000;

  final _description = TextEditingController();
  final _deviceName = TextEditingController();
  final _deviceModel = TextEditingController();
  final _picker = ImagePicker();
  String? _app;
  TicketPriority _priority = TicketPriority.medium;
  final List<TicketAttachment> _files = [];
  TicketAssignee? _assignee;
  bool _tried = false;
  bool _saving = false;
  String _savingLabel = 'Submitting…';

  @override
  void dispose() {
    _description.dispose();
    _deviceName.dispose();
    _deviceModel.dispose();
    super.dispose();
  }

  int get _room => _maxFiles - _files.length;

  String? get _appError => _tried && _app == null ? 'Select the app with the issue' : null;
  String? get _descriptionError =>
      _tried && _description.text.trim().isEmpty ? 'Describe the issue' : null;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addImages(ImageSource source) async {
    if (_room <= 0) return _snack('You can attach up to $_maxFiles files.');
    try {
      final picked = source == ImageSource.camera
          ? [?await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 2000)]
          : await _picker.pickMultiImage(
              imageQuality: 75, maxWidth: 2000, limit: _room > 1 ? _room : null);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        for (final x in picked.take(_room)) {
          _files.add(TicketAttachment(url: x.path, type: TicketAttachmentType.image));
        }
      });
    } catch (_) {
      _snack('Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}');
    }
  }

  Future<void> _addVideo(ImageSource source) async {
    if (_room <= 0) return _snack('You can attach up to $_maxFiles files.');
    try {
      final x = await _picker.pickVideo(source: source, maxDuration: _maxVideoLength);
      if (x == null || !mounted) return;
      final mb = await File(x.path).length() / (1024 * 1024);
      if (mb > _maxVideoMb) {
        return _snack(
            'Video is ${mb.toStringAsFixed(0)} MB. Please pick one under $_maxVideoMb MB.');
      }
      setState(
          () => _files.add(TicketAttachment(url: x.path, type: TicketAttachmentType.video)));
    } catch (_) {
      _snack('Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}');
    }
  }

  /// Gallery / Camera for an image or a video.
  Future<void> _addSheet({required bool video}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(video ? 'Add a video' : 'Add images',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: ticketInk)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _sourceTile(
                      ctx,
                      icon: video ? Icons.video_library_rounded : Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: HomeGlass.blue,
                      source: ImageSource.gallery,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sourceTile(
                      ctx,
                      icon: video ? Icons.videocam_rounded : Icons.photo_camera_rounded,
                      label: video ? 'Record' : 'Camera',
                      color: HomeGlass.orange,
                      source: ImageSource.camera,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    video ? await _addVideo(source) : await _addImages(source);
  }

  Widget _sourceTile(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required ImageSource source,
  }) =>
      PressableScale(
        child: SoftCard(
          radius: 16,
          gradient: homePastelGradient(color),
          borderColor: color.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(vertical: 18),
          onTap: () => Navigator.pop(ctx, source),
          child: Column(
            children: [
              Icon(icon, color: homeDeep(color), size: 30),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: homeDeep(color))),
            ],
          ),
        ),
      );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_app == null || _description.text.trim().isEmpty) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() {
      _saving = true;
      _savingLabel = 'Submitting…';
    });
    try {
      await ref.read(ticketActionsProvider).raise(
            app: _app!,
            description: _description.text.trim(),
            priority: _priority,
            assignee: _assignee,
            deviceName: _deviceName.text,
            deviceModel: _deviceModel.text,
            files: _files.map((f) => f.url).toList(),
            onUploading: (i, n) {
              if (mounted) setState(() => _savingLabel = 'Uploading file $i of $n…');
            },
          );
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _snack(e.toString());
    }
  }

  // ── Sections ──

  Widget _step(int n, String title, {String? trailing, String? error}) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: error != null ? AppColors.danger : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text('$n',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: ticketInk)),
            ),
            if (trailing != null)
              Text(trailing, style: const TextStyle(fontSize: 12, color: ticketSubtle)),
          ],
        ),
      );

  Widget _errorText(String? e) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: e == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Text(e,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger)),
                  ],
                ),
              ),
      );

  Widget _appGrid() {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return LayoutBuilder(builder: (context, box) {
      final cols = wide ? 5 : 3;
      final w = (box.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final a in ticketApps)
            SizedBox(width: w, child: _appTile(a)),
        ],
      );
    });
  }

  Widget _appTile(String app) {
    final on = _app == app;
    final (c, _) = ticketAppStyle(app);
    return PressableScale(
      enabled: !_saving,
      child: GestureDetector(
        onTap: _saving
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _app = app);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: on ? homePastel(c) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? homeDeep(c) : ticketBorder,
              width: on ? 1.6 : 1,
            ),
            boxShadow: on
                ? [BoxShadow(color: c.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))]
                : const [],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  TicketAppAvatar(app: app, size: 40),
                  if (on)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: homeDeep(c),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(app,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    color: on ? homeDeep(c) : ticketInk,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _descriptionBox() => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _descriptionError != null ? AppColors.danger : ticketBorder,
            width: _descriptionError != null ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _description,
              enabled: !_saving,
              minLines: 5,
              maxLines: 10,
              maxLength: _maxDescription,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14.5, color: ticketInk, height: 1.45),
              decoration: const InputDecoration(
                hintText:
                    'What went wrong? Add the school name, which screen, the steps and any error message.',
                hintMaxLines: 3,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 14, 10),
              child: Text('${_description.text.length}/$_maxDescription',
                  style: const TextStyle(fontSize: 11.5, color: ticketSubtle)),
            ),
          ],
        ),
      );

  Widget _priorityRow() => Row(
        children: [
          for (final p in TicketPriority.values) ...[
            if (p != TicketPriority.values.first) const SizedBox(width: 10),
            Expanded(child: _priorityCard(p)),
          ],
        ],
      );

  Widget _priorityCard(TicketPriority p) {
    final on = _priority == p;
    final c = ticketPriorityColor(p);
    return PressableScale(
      enabled: !_saving,
      child: GestureDetector(
        onTap: _saving
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _priority = p);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: on ? c : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? c : ticketBorder),
            boxShadow: on
                ? [BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_rounded, size: 18, color: on ? Colors.white : c),
              const SizedBox(height: 6),
              Text(p.label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: on ? Colors.white : ticketInk)),
              const SizedBox(height: 2),
              Text(ticketPriorityHint(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: on ? Colors.white.withValues(alpha: 0.9) : ticketSubtle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentsBox() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ticketBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_files.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final f in _files)
                    AppEntrance(
                      key: ObjectKey(f),
                      child: TicketAttachmentTile(
                        attachment: f,
                        size: 84,
                        onTap: () => openTicketAttachment(context, f),
                        onRemove: _saving ? null : () => setState(() => _files.remove(f)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_room > 0)
              Row(
                children: [
                  Expanded(
                    child: _addButton(
                      icon: Icons.add_photo_alternate_rounded,
                      label: 'Add image',
                      color: HomeGlass.blue,
                      onTap: () => _addSheet(video: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _addButton(
                      icon: Icons.video_call_rounded,
                      label: 'Add video',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _addSheet(video: true),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: ticketSubtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Up to $_maxFiles files · video up to ${_maxVideoLength.inMinutes} min, $_maxVideoMb MB',
                    style: const TextStyle(fontSize: 11.5, color: ticketSubtle),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Optional phone details where the issue happened.
  Widget _deviceBox() {
    InputDecoration deco(String label, String hint, IconData icon) => InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ticketBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ticketBorder),
          ),
        );
    final name = TextField(
      controller: _deviceName,
      enabled: !_saving,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: deco('Device name', 'e.g. Redmi Note 12', Icons.smartphone_rounded),
    );
    final model = TextField(
      controller: _deviceModel,
      enabled: !_saving,
      textInputAction: TextInputAction.done,
      decoration: deco('Model / OS', 'e.g. Android 14, iPhone 13', Icons.info_outline_rounded),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 520
          ? Row(children: [Expanded(child: name), const SizedBox(width: 10), Expanded(child: model)])
          : Column(children: [name, const SizedBox(height: 10), model]),
    );
  }

  Future<void> _chooseAssignee() async {
    final choice = await pickTicketAssignee(
      context,
      currentId: _assignee?.id ?? '',
    );
    if (choice != null && mounted) setState(() => _assignee = choice.to);
  }

  /// Optional assignee: tap to pick anyone (or clear).
  Widget _assignBox() => PressableScale(
        enabled: !_saving,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _saving ? null : _chooseAssignee,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ticketBorder),
              ),
              child: Row(
                children: [
                  _assignee == null
                      ? Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              size: 19, color: AppColors.accent),
                        )
                      : TicketPersonAvatar(name: _assignee!.name, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _assignee?.name ?? 'Choose who should fix it',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _assignee == null ? FontWeight.w500 : FontWeight.w700,
                        color: _assignee == null ? ticketSubtle : ticketInk,
                      ),
                    ),
                  ),
                  if (_assignee != null)
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: _saving ? null : () => setState(() => _assignee = null),
                      icon: const Icon(Icons.close_rounded, size: 20, color: ticketSubtle),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.chevron_right_rounded, color: ticketSubtle),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _addButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      PressableScale(
        enabled: !_saving,
        child: Material(
          color: homePastel(color),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _saving ? null : onTap,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: homeDeep(color)),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700, color: homeDeep(color))),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _submitBar() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: ticketBorder)),
          boxShadow: [BoxShadow(color: Color(0x0F111827), blurRadius: 16, offset: Offset(0, -4))],
        ),
        padding: EdgeInsets.fromLTRB(
          formSidePadding(context, 16),
          12,
          formSidePadding(context, 16),
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: PressableScale(
          enabled: !_saving,
          pressedScale: 0.97,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.75),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _save,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _saving
                    ? Row(
                        key: const ValueKey('saving'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(_savingLabel),
                        ],
                      )
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Submit Ticket',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pad = formSidePadding(context, 16);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: !_saving,
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              const ToolbarLayout(title: 'Raise Ticket'),
              Expanded(
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: ticketPageBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                          children: [
                            _step(1, 'Which app has the issue?', error: _appError),
                            _appGrid(),
                            _errorText(_appError),
                            _step(2, 'Describe the issue', error: _descriptionError),
                            _descriptionBox(),
                            _errorText(_descriptionError),
                            _step(3, 'Priority'),
                            _priorityRow(),
                            _step(4, 'Images / Videos',
                                trailing:
                                    _files.isEmpty ? 'Optional' : '${_files.length}/$_maxFiles'),
                            _attachmentsBox(),
                            _step(5, 'Device', trailing: 'Optional'),
                            _deviceBox(),
                            _step(6, 'Assign to', trailing: 'Optional'),
                            _assignBox(),
                          ],
                        ),
                      ),
                      _submitBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
