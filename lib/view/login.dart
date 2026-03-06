import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sssbuddy/Values/Strings/strings_value.dart';
import 'package:sssbuddy/Components/CustomPasswordField.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import '../Values/Colors/app_colors.dart';
import '../Components//CustomButton.dart';
import '../Components/CustomTextField.dart';
import '../Components/header_container.dart';

class MyLogin extends StatelessWidget {
  const MyLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isRememberMe = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
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
                      style: TextStyle(fontSize: 16, color: Colors.white70),
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
                          CustomTextField(
                            controller: emailController,
                            labelText: Strings.empIDMobileNumber,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Strings.enterIdMobileNumber;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomPasswordField(
                            controller: passwordController,
                            labelText: Strings.password,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return Strings.enteryourpassword;
                              }
                              if (value.length < 6) {
                                return Strings.passwordmustbeatleastcharacters;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
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
                          Row(
                            children: [
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
                              Expanded(
                                child: CustomButton(
                                  text: Strings.login,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            Strings.loginSuccessful,
                                          ),
                                        ),
                                      );
                                    }
                                    Navigator.pushNamed(context, RoutesName.dashboard);
                                  },
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
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/buddy_logo.png",
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        Strings.poweredbySavyasasy,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
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