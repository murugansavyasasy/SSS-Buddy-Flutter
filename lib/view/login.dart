import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Strings/strings_value.dart';
import '../Values/Colors/app_colors.dart';

import '../Components/CustomPasswordField.dart';
import '../Components/CustomButton.dart';
import '../Components/CustomTextField.dart';
import '../Components/header_container.dart';

import '../utils/routes/routes_name.dart';
import '../viewModel/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isRememberMe = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          top: false,
          child: Column(
            children: [

              /// HEADER
              HeaderContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      Strings.welcometoSSSBuddy,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      Strings.logintocontinue,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          /// EMAIL
                          CustomTextField(
                            controller: emailController,
                            labelText: Strings.empIDMobileNumber,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Strings.empIDMobileNumber;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          /// PASSWORD
                          CustomPasswordField(
                            controller: passwordController,
                            labelText: Strings.password,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Strings.enteryourpassword;
                              }
                              if (value.length < 1) {
                                return Strings.passwordmustbeatleastcharacters;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          /// REMEMBER ME
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: isRememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    isRememberMe = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text(
                                Strings.rememberMe,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// BUTTONS
                          Row(
                            children: [

                              /// CLEAR BUTTON
                              Expanded(
                                child: CustomButton(
                                  text: Strings.clear,
                                  isOutlined: true,
                                  onPressed: () {
                                    emailController.clear();
                                    passwordController.clear();

                                    setState(() {
                                      isRememberMe = false;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(width: 16),

                              /// LOGIN BUTTON
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4085EF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),

                                    onPressed: loginState.isLoading
                                        ? null
                                        : () async {

                                      if (_formKey.currentState!.validate()) {

                                        final success = await ref
                                            .read(loginProvider.notifier)
                                            .login(
                                          emailController.text,
                                          passwordController.text,
                                        );

                                        if (success && context.mounted) {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            RoutesName.dashboard,
                                          );
                                        }

                                        if (!success && context.mounted) {
                                          final error = ref.read(loginProvider).error;

                                          if (error != null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(error.toString())),
                                            );
                                          }
                                        }

                                      }

                                    },

                                    child: loginState.isLoading
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      Strings.login,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// FOOTER
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/buddy_logo.png",
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      Strings.poweredbySavyasasy,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}