import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';
import 'package:sssbuddy/components/custom_text_field.dart';
import '../Values/Colors/app_colors.dart';
import '../components/toolbar_layout.dart';

class CreateDemo extends ConsumerStatefulWidget {
  const CreateDemo({super.key});

  @override
  ConsumerState<CreateDemo> createState() => _CreateDemoState();
}

class _CreateDemoState extends ConsumerState<CreateDemo> {

  final TextEditingController titleController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

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
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(),

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

                child: Column(
                  children: [

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


                    CustomTextField(
                      label: "Demo Parent Number",
                      hint: "Enter Mobile Number",
                      controller: descriptionController,
                    ),
                  ],
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