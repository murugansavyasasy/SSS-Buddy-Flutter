import 'package:flutter/material.dart';
import '../Values/Colors/app_colors.dart';
import '../utils/routes/routes_name.dart';

class CommonDialog {

  static void showSuccessDialog(
      BuildContext context, {
        required String message,
        bool showRecordButton = false,
      }) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Success Icon
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Success",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {

                      if (showRecordButton) {
                        Navigator.pushReplacementNamed(
                          context,
                          RoutesName.recordvoice,
                        );

                      } else {

                        Navigator.pushReplacementNamed(
                          context,
                          RoutesName.dashboard,
                        );

                      }
                    },
                    child: Text(
                      showRecordButton ? "Record Voice" : "Close",
                      style: const TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}