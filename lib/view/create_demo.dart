import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:sssbuddy/Components/CustomButton.dart';
import 'package:sssbuddy/components/custom_text_field.dart';
import '../Values/Colors/app_colors.dart';
import '../components/toolbar_layout.dart';
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

                      /// Dynamic Parent Number Fields
                      Column(
                        children: List.generate(parentControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: index == 0 ? "Demo Parent Number" : "",
                                    hint: index == 0 ? "Enter Mobile Number" : "",
                                    controller: parentControllers[index],
                                  ),
                                ),

                                /// Remove button (only for extra fields)
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

                      /// Add another number button
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

                      /// Create Demo Button
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Create Demo",
                          onPressed: () {
                            print("Create Demo Clicked");

                            /// Example collecting numbers
                            for (var controller in parentControllers) {
                              print(controller.text);
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