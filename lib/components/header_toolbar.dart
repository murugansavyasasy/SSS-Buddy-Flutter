import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import 'package:sssbuddy/main.dart';
import '../View/login.dart';
import '../core/storage/secure_storage.dart';
import '../provider/user_session_provider.dart';
import '../utils/routes/routes_name.dart';

class HeaderToolbar extends ConsumerWidget {
  const HeaderToolbar({super.key});

  String getInitials(String name) {
    final words = name.trim().split(" ");
    if (words.length >= 2) {
      return (words.first[0] + words.last[0]).toUpperCase();
    }
    return words.first[0].toUpperCase();
  }

  void confirmationLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent outside tap
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 50, color: Colors.red),

                const SizedBox(height: 10),

                const Text(
                  "Logout?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text("Are you sure you want to logout?"),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 5,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("No"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 5,
                        ),
                      ),
                      onPressed: () {
                        SecureStorage.clearLoginData();
                        AppRoot.restartApp(context);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(userSessionProvider);

    final double topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: AppColors.primary,
        padding: EdgeInsets.only(
          top: topPadding + 20,
          left: 16,
          right: 16,
          bottom: 20,
        ),
        child: userSession.when(
          loading: () => const SizedBox(),

          error: (error, stack) => const SizedBox(),

          data: (user) {
            final name = user?.employeeName ?? "";
            final role = user?.employeerole ?? "";
            final initials = getInitials(name);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(100, 100, 0, 0),
                      // adjust position
                      items: [
                        PopupMenuItem(
                          value: "Change Password",
                          child: Text("Change Password"),
                        ),
                        PopupMenuItem(
                          value: "Logout",
                          child: Text(
                            "Logout",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ).then((value) async {
                      if (value != null) {
                        print("Selected: $value");
                        if (value == "Change Password") {
                          Navigator.pushNamed(
                            context,
                            RoutesName.changepassword,
                          );
                        } else if (value == "Logout") {
                          confirmationLogout(context);
                        }
                      }
                    });
                  },

                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
