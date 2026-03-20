import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:sssbuddy/Components/CustomButton.dart';
import 'package:sssbuddy/components/custom_text_field.dart';
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
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  List<TextEditingController> parentControllers = [TextEditingController()];

  @override
  Widget build(BuildContext context) {

      return  AnnotatedRegion<SystemUiOverlayStyle>(
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
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: "School Name",
                        hint: "Enter School Name",
                        controller: titleController,
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        label: "Demo Principal Number",
                        hint: "Enter Mobile Number",
                        controller: subjectController,
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        label: "Demo Principal E-Mail ID",
                        hint: "Enter email id",
                        controller: dateController,
                      ),

                      const SizedBox(height: 20),

                      Column(
                        children: List.generate(parentControllers.length, (
                          index,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: index == 0
                                        ? "Demo Parent Number"
                                        : "",
                                    hint: index == 0
                                        ? "Enter Mobile Number"
                                        : "",
                                    controller: parentControllers[index],
                                  ),
                                ),

                                if (index != 0)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        parentControllers.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              parentControllers.add(TextEditingController());
                            });
                          },
                          child: Text(
                            "+ Add another number",
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Create Demo",
                          onPressed: () async {
                            final loginData = ref.read(loginProvider);
                            final loginvalue = loginData.value;

                            final loginId = loginvalue?.SchoolLoginId ?? "";

                            final schoolName = titleController.text;
                            final mobileNo = subjectController.text;
                            final email = dateController.text;

                            final parentNos = parentControllers
                                .map((controller) => controller.text)
                                .where((text) => text.isNotEmpty)
                                .join(",");

                            final success = await ref
                                .read(createdemoProvider.notifier)
                                .createdemo(
                                  loginId,
                                  schoolName,
                                  mobileNo,
                                  email,
                                  parentNos,
                                  "1",
                                );

                            if (!mounted) return;

                            if (success) {
                              final response = ref
                                  .read(createdemoProvider)
                                  .value;
                              if (response?.status == 1) {
                                titleController.clear();
                                subjectController.clear();
                                dateController.clear();
                                parentControllers.clear();

                                CommonDialog.showSuccessDialog(
                                  context,
                                  message: "Demo created successfully",
                                  showRecordButton: true,
                                );
                              } else {
                                CommonDialog.showSuccessDialog(
                                  context,
                                  message: "Demo created successfully",
                                  showRecordButton: false,
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to create demo"),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
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

@Preview()
Widget mySampleText() {
  return const CreateDemo();
}
