import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import 'package:sssbuddy/main.dart';
import 'glass_card.dart';
import '../core/chat/chat_notification_service.dart';
import '../core/followup/followup_reminders.dart';
import '../core/storage/secure_storage.dart';
import '../provider/user_session_provider.dart';
import '../utils/routes/routes_name.dart';

class HeaderToolbar extends ConsumerWidget {
  const HeaderToolbar({super.key});

  String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return "?";
    }

    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words.first.isNotEmpty
          ? words.first[0].toUpperCase()
          : "?";
    }

    return "${words.first[0]}${words.last[0]}".toUpperCase();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void confirmationLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.logout, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                "Logout?",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Finish clearing before the restart, or the splash could
                // still find the saved login and sign the user back in.
                await Future.wait([
                  ChatNotificationService.instance.unregister(),
                  FollowUpReminders.instance.cancelAll(),
                ].map((f) => f.catchError((_) {})));
                await SecureStorage.clearLoginData();
                if (!context.mounted) return;
                AppRoot.restartApp(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
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
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HomeGlass.bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        // Same blue gradient header as the other screens; the content below
        // curves over it.
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        padding: EdgeInsets.only(
          top: topPadding + 14,
          left: 16,
          right: 16,
          bottom: 22,
        ),
        child: userSession.when(
          loading: () => const SizedBox(),

          error: (error, stack) => const SizedBox(),

          data: (user) {
            final name = user?.employeeName ?? "";
            final role = user?.employeerole ?? "";
            final initials = getInitials(name);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6C9BE0), Color(0xFF3B5E9E)],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                      if (role.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(100, 100, 0, 0),
                      // adjust position
                      items: [
                        PopupMenuItem(
                          value: "Change Password",
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_reset_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              const Text("Change Password"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "Logout",
                          child: const Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Logout",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
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

                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
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
