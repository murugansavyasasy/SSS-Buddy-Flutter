import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Values/Colors/app_colors.dart';

class MyLogin extends StatelessWidget {
  const MyLogin ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home : LoginScreen(),
    );
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
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).viewPadding.top + 60,
                  24,
                  40,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome to SSS Buddy",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Login to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
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
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Emp ID / Mobile Number",
                              labelStyle: TextStyle(
                                color: AppColors.grey,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter Id (or) Mobile Number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: isPasswordHidden,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(
                                color: AppColors.grey,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordHidden
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordHidden = !isPasswordHidden;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter your password";
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
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
                                "Remember Me",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      emailController.clear();
                                      passwordController.clear();
                                      setState(() {
                                        isRememberMe = false;
                                      });
                                    },
                                    child: Text(
                                      "Clear",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Login Successful"),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      "Login",
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
            ],
          ),
        ),
      ),
    );
  }
}