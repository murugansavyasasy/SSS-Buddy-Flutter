import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/demo_list.dart';
import 'package:sssbuddy/components/custom_text_field.dart';
import '../Components/CustomButton.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/Demolist.dart';
import '../components/toolbar_layout.dart';
import '../provider/user_session_provider.dart';
import '../viewModel/demolist_edit_viewmodel.dart';
import '../viewModel/demolist_view_model.dart';

class DemolistEditView extends ConsumerStatefulWidget {
  final Demolist item;

  const DemolistEditView({super.key, required this.item});

  @override
  ConsumerState<DemolistEditView> createState() => _DemolistEditViewState();
}

class _DemolistEditViewState extends ConsumerState<DemolistEditView> {
  final schoolController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  List<TextEditingController> parentControllers = [];

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
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text("No Data Found"));
                  }

                  final item = data.first;

                  if (schoolController.text.isEmpty) {
                    schoolController.text = item.SchoolName;
                    mobileController.text = item.PrincipalNumber;
                    emailController.text = item.PrincipalEmail;

                    parentControllers = item.ParentNos
                        .map((e) => TextEditingController(text: e))
                        .toList();
                  }

                  return _buildForm();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomTextField(
            label: "School Name",
            hint: "Enter school name",
            controller: schoolController,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            label: "Principal Number",
            hint: "Principal contact number",
            controller: mobileController,
            enabled: false,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            label: "Email",
            hint: "Principal email address",
            controller: emailController,
            enabled: false,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Parent Numbers",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () {
                  setState(() {
                    parentControllers.add(TextEditingController());
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 8),

          Column(
            children: List.generate(parentControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: "Parent ${index + 1}",
                        hint: "Enter parent number",
                        controller: parentControllers[index],
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          parentControllers.removeAt(index);
                        });
                      },
                    )
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Cancel",
                  onPressed: () => Navigator.pop(context),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "Update",
                  onPressed: _onUpdate,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _onUpdate() async {
    final userAsync = ref.read(userSessionProvider);
    final loginId = userAsync.value?.userId.toString() ?? '';

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

    try {
      final success = await ref
          .read(demolistEditProvider.notifier)
          .updateDemo(body);

      if (!mounted) return;

      if (success) {
        ref.invalidate(demoviewProvider);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Demo updated successfully",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString().replaceAll('Exception: ', '')}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}