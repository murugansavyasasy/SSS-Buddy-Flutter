import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/components/app_states.dart';
import 'package:sssbuddy/view/demo_list.dart';

import '../Components/CustomButton.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/Demolist.dart';
import '../auth/model/ExhibitionModel.dart' show formatIndianMobile;
import '../components/app_motion.dart';
import '../components/form_width.dart';
import '../components/glass_card.dart';
import '../components/toolbar_layout.dart';
import '../provider/user_session_provider.dart';
import '../viewModel/demolist_edit_viewmodel.dart';
import '../viewModel/demolist_view_model.dart';

/// Edit a demo: school name and parent numbers (the principal number is
/// fixed once the demo is created). Same look as Create Demo.
class DemolistEditView extends ConsumerStatefulWidget {
  final Demolist item;

  const DemolistEditView({super.key, required this.item});

  @override
  ConsumerState<DemolistEditView> createState() => _DemolistEditViewState();
}

class _DemolistEditViewState extends ConsumerState<DemolistEditView> {
  static final _mobileRegex = RegExp(r'^\d{10}$');

  final _formKey = GlobalKey<FormState>();
  final schoolController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  List<TextEditingController> parentControllers = [];
  bool _isBound = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(demolistEditProvider.notifier)
          .getdemolisteditdetails(widget.item.demoId.toString());
    });
  }

  @override
  void dispose() {
    schoolController.dispose();
    mobileController.dispose();
    emailController.dispose();
    for (var c in parentControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demolistEditProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          const ToolbarLayout(
            title: "Edit Demo",
            navigateTo: DemoListView(),
          ),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: HomeGlass.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: state.when(
                loading: () => const AppListSkeleton(count: 3),
                error: (e, _) => AppErrorView(
                  error: e,
                  onRetry: () => ref
                      .read(demolistEditProvider.notifier)
                      .getdemolisteditdetails(widget.item.demoId.toString()),
                ),
                data: (data) {
                  if (!_isBound) {
                    _isBound = true;
                    // Fall back to the selected list item when the details
                    // API has no record for this demo.
                    final item = data.isNotEmpty ? data.first : null;
                    schoolController.text = item?.SchoolName ?? widget.item.schoolName;
                    mobileController.text =
                        item?.PrincipalNumber ?? widget.item.principalNumber.toString();
                    emailController.text = item?.PrincipalEmail ?? '';

                    for (var c in parentControllers) {
                      c.dispose();
                    }
                    parentControllers = (item?.ParentNos ?? const <String>[])
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .map((e) => TextEditingController(text: e))
                        .toList();
                    if (parentControllers.isEmpty) {
                      parentControllers.add(TextEditingController());
                    }
                  }
                  return Column(
                    children: [
                      Expanded(child: _buildForm()),
                      _bottomBar(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ──

  Widget _buildForm() {
    final pad = formSidePadding(context, 16);
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
        children: [
          AppEntrance(child: _schoolHeader()),
          const SizedBox(height: 14),
          AppEntrance(
            index: 1,
            child: _section(
              icon: Icons.school_rounded,
              title: "School",
              children: [
                _field(
                  controller: schoolController,
                  label: "School Name",
                  hint: "Enter school name",
                  icon: Icons.apartment_rounded,
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Please enter school name' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppEntrance(
            index: 2,
            child: _section(
              icon: Icons.person_rounded,
              title: "Principal",
              children: [_principalNumber()],
            ),
          ),
          const SizedBox(height: 14),
          AppEntrance(
            index: 3,
            child: _section(
              icon: Icons.groups_rounded,
              title: "Parent Numbers",
              trailing: _countBadge(parentControllers.length),
              children: [
                for (var i = 0; i < parentControllers.length; i++) ...[
                  _parentRow(i),
                  const SizedBox(height: 12),
                ],
                _addNumberButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// School initials, name and demo number at the top.
  Widget _schoolHeader() {
    final name = schoolController.text.trim().isEmpty
        ? widget.item.schoolName
        : schoolController.text.trim();
    final words = name
        .replaceAll(RegExp(r"[^A-Za-z0-9 ]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : words.length == 1
            ? words.first[0].toUpperCase()
            : (words[0][0] + words[1][0]).toUpperCase();
    return SoftCard(
      radius: 20,
      gradient: homePastelGradient(AppColors.accent),
      borderColor: AppColors.accent.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6D8BE0), AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEMO #${widget.item.demoId}',
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtle)),
                const SizedBox(height: 4),
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      );

  Widget _countBadge(int count) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Container(
          key: ValueKey(count),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count == 1 ? '1 number' : '$count numbers',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      );

  /// Read-only: shown as a locked field.
  Widget _principalNumber() {
    final n = mobileController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mobile Number',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_rounded, size: 20, color: AppColors.subtle),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  n.isEmpty ? '—' : formatIndianMobile(n),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              const Icon(Icons.lock_rounded, size: 16, color: AppColors.subtle),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text("The principal's number can't be changed after the demo is created.",
            style: TextStyle(fontSize: 11.5, color: AppColors.subtle)),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(text: label, children: [
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
          ]),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtle),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_saving,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: AppColors.subtle.withValues(alpha: 0.7)),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF9FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary, 1.5),
            errorBorder: border(AppColors.danger),
            focusedErrorBorder: border(AppColors.danger, 1.5),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  String? _validateParent(String? v, int index) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null; // optional when editing
    if (!_mobileRegex.hasMatch(t)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  Widget _parentRow(int index) => _field(
        controller: parentControllers[index],
        label: index == 0 ? "Parent Number" : "Parent Number ${index + 1}",
        hint: "Enter 10-digit mobile number",
        icon: Icons.phone_iphone_rounded,
        keyboardType: TextInputType.phone,
        validator: (v) => _validateParent(v, index),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        suffix: index == 0
            ? null
            : IconButton(
                tooltip: "Remove number",
                onPressed: _saving
                    ? null
                    : () => setState(() => parentControllers.removeAt(index).dispose()),
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: AppColors.danger, size: 22),
              ),
      );

  Widget _addNumberButton() => PressableScale(
        enabled: !_saving,
        child: OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() => parentControllers.add(TextEditingController()));
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.tint.withValues(alpha: 0.5),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text("Add another number",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _bottomBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Cancel",
                      height: 50,
                      isOutlined: true,
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: "Update Demo",
                      height: 50,
                      isLoading: _saving,
                      onPressed: _saving ? null : _onUpdate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  // ── Save ──

  Future<void> _onUpdate() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.mediumImpact();
      return;
    }
    final userAsync = ref.read(userSessionProvider);
    final loginId = userAsync.value?.schoolUserId.toString() ?? '';

    if (loginId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );
      return;
    }

    final parentNos = parentControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .join(',');

    final body = {
      "LoginID": loginId,
      "SchoolName": schoolController.text.trim(),
      "MobileNo": mobileController.text.trim(),
      "Email": emailController.text.trim(),
      "ParentNos": parentNos,
      "RequestType": "2",
      "Demoid": widget.item.demoId.toString(),
    };

    setState(() => _saving = true);
    try {
      final success = await ref.read(demolistEditProvider.notifier).updateDemo(body);
      if (!mounted) return;
      if (success) {
        ref.invalidate(demoviewProvider);
        HapticFeedback.lightImpact();
        await _showSuccess();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccess() => showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: homePastelGradient(AppColors.success),
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Demo updated',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 6),
                Text(
                  '${schoolController.text.trim()} · ${parentControllers.where((c) => c.text.trim().isNotEmpty).length} parent numbers',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.subtle),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Done",
                    height: 50,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
