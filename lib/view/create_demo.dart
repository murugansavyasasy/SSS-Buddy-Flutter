import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:sssbuddy/Components/CustomButton.dart';
import 'package:sssbuddy/auth/model/Demolist.dart';
import 'package:sssbuddy/viewModel/createdemo_view_model.dart';
import '../Values/Colors/app_colors.dart';
import '../components/common_dialog.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/login_view_model.dart';
import 'dashboard.dart';

class CreateDemo extends ConsumerStatefulWidget {
  const CreateDemo({super.key});

  @override
  ConsumerState<CreateDemo> createState() => _CreateDemoState();
}

class _CreateDemoState extends ConsumerState<CreateDemo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController principalController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  List<TextEditingController> parentControllers = [TextEditingController()];

  static final _mobileRegex = RegExp(r'^\d{10}$');
  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    schoolController.dispose();
    principalController.dispose();
    emailController.dispose();
    for (final c in parentControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateMobile(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    if (!_mobileRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateOptionalMobile(String? value) {
    if (value != null &&
        value.trim().isNotEmpty &&
        !_mobileRegex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _addParentNumber() {
    if (parentControllers.last.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the previous parent number first"),
        ),
      );
      return;
    }
    setState(() => parentControllers.add(TextEditingController()));
  }

  void _removeParentNumber(int index) {
    setState(() => parentControllers.removeAt(index).dispose());
  }

  void _resetForm() {
    schoolController.clear();
    principalController.clear();
    emailController.clear();
    setState(() {
      for (final c in parentControllers) {
        c.dispose();
      }
      parentControllers = [TextEditingController()];
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final loginId =
        (ref.read(loginProvider).value?.schoolUserId ?? 0).toString();
    final schoolName = schoolController.text.trim();
    final mobileNo = principalController.text.trim();
    final email = emailController.text.trim();
    final parentNos = parentControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .join(",");

    await ref
        .read(createdemoProvider.notifier)
        .createdemo(loginId, schoolName, mobileNo, email, parentNos, "1");

    if (!mounted) return;
    final response = ref.read(createdemoProvider).value;

    if (response?.status == 1) {
      final demoItem = Demolist(
        schoolName: schoolName,
        principalNumber: int.tryParse(mobileNo) ?? 0,
        demoId: response?.demoId ?? 0,
        DemoID: response?.demoId ?? 0,
      );
      _resetForm();
      CommonDialog.showSuccessDialog(
        context,
        message: "Demo created successfully",
        showRecordButton: true,
        response: demoItem,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response?.message?.isNotEmpty == true
                ? response!.message!
                : "Failed to create demo",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = ref.watch(createdemoProvider).isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(title: "Create Demo", navigateTo: Dashboard()),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: Center(
                          child: ConstrainedBox(
                            // Keeps the form readable on iPad.
                            constraints: const BoxConstraints(maxWidth: 640),
                            // Not a ListView: off-screen fields must stay
                            // built so the form validates all of them.
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionCard(
                                  icon: Icons.account_balance_outlined,
                                  title: "School",
                                  children: [
                                    _field(
                                      controller: schoolController,
                                      label: "School Name",
                                      hint: "Enter school name",
                                      icon: Icons.school_outlined,
                                      required: true,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (v) =>
                                          _validateRequired(v, 'School Name'),
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(100),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _sectionCard(
                                  icon: Icons.person_outline_rounded,
                                  title: "Principal",
                                  children: [
                                    _field(
                                      controller: principalController,
                                      label: "Mobile Number",
                                      hint: "Enter 10-digit mobile number",
                                      icon: Icons.phone_outlined,
                                      required: true,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) => _validateMobile(
                                          v, 'Principal Mobile Number'),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _field(
                                      controller: emailController,
                                      label: "Email ID",
                                      hint: "Enter email address",
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _sectionCard(
                                  icon: Icons.groups_outlined,
                                  title: "Parent Numbers",
                                  trailing: _countBadge(parentControllers.length),
                                  children: [
                                    for (var i = 0;
                                        i < parentControllers.length;
                                        i++) ...[
                                      if (i > 0) const SizedBox(height: 12),
                                      _parentRow(i),
                                    ],
                                    const SizedBox(height: 14),
                                    _addNumberButton(),
                                  ],
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _bottomBar(isCreating),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pieces ──────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count == 1 ? '1 number' : '$count numbers',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
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
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
            ],
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtle,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.subtle.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF9FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _parentRow(int index) {
    return _field(
      controller: parentControllers[index],
      label: index == 0 ? "Parent Number" : "Parent Number ${index + 1}",
      hint: "Enter 10-digit mobile number",
      icon: Icons.phone_iphone_rounded,
      required: index == 0,
      keyboardType: TextInputType.phone,
      validator: index == 0
          ? (v) => _validateMobile(v, 'Parent Mobile Number')
          : _validateOptionalMobile,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      suffix: index == 0
          ? null
          : IconButton(
              tooltip: "Remove number",
              onPressed: () => _removeParentNumber(index),
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
    );
  }

  Widget _addNumberButton() {
    return OutlinedButton.icon(
      onPressed: _addParentNumber,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.tint.withValues(alpha: 0.5),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        "Add another number",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Create button pinned above the keyboard / Android navigation bar.
  Widget _bottomBar(bool isCreating) {
    return Container(
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
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "Create Demo",
                height: 50,
                isLoading: isCreating,
                onPressed: isCreating ? null : _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview()
Widget mySampleText() {
  return const CreateDemo();
}
