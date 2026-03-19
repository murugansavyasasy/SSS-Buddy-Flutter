import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../Values/Strings/strings_value.dart';
import '../Components/CustomPasswordField.dart';
import '../Components/CustomButton.dart';
import '../Components/CustomTextField.dart';
import '../Components/header_container.dart';
import '../core/storage/secure_storage.dart';
import '../provider/app_providers.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSavedLogin();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loadSavedLogin() async {

    final rememberMe = await SecureStorage.getRememberMe();

    if (rememberMe) {
      final employeeId = await SecureStorage.getEmployeeId();
      final password = await SecureStorage.getPassword();
      if (employeeId != null && password != null) {
        emailController.text = employeeId;
        passwordController.text = password;
        ref.read(rememberMeProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final rememberMe = ref.watch(rememberMeProvider);

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
                        children: [
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  ref.read(rememberMeProvider.notifier).state =
                                      value!;
                                },
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
                                    ref.read(rememberMeProvider.notifier).state = false;
                                  },
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:  AppColors.secondaryprimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),

                                    onPressed: loginState.isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              final success = await ref
                                                  .read(loginProvider.notifier)
                                                  .login(
                                                    emailController.text,
                                                    passwordController.text,
                                                    rememberMe,
                                                  );

                                              if (success && context.mounted) {
                                                Navigator.pushNamed(
                                                  context,
                                                  RoutesName.dashboard,
                                                );
                                              }

                                              if (!success && context.mounted) {
                                                final error = ref
                                                    .read(loginProvider)
                                                    .error;

                                                if (error != null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        error.toString(),
                                                      ),
                                                    ),
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
                      style: TextStyle(color: Colors.grey, fontSize: 15),
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
