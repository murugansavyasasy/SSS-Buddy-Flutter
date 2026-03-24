import 'package:flutter/material.dart';

class UpcomingDemoCard extends StatelessWidget {

  final String demoId;
  final String schoolName;
  final int principalNumber;
  final VoidCallback? onTap;


  const UpcomingDemoCard({
    super.key,
    required this.demoId,
    required this.schoolName,
    required this.principalNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
    child:  Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xfff8f6f6),
        borderRadius: BorderRadius.circular(16),

      ),
      child: Row(
        children: [
          Container(
            width: 70,
            decoration: const BoxDecoration(
              color: Color(0xff2E4F7D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_voice_rounded,
                    size: 40,
                    color: Colors.white),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  maxLines: 1,
                  demoId,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                Text(
                  schoolName,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                Text(
                  maxLines: 1,
                  "$principalNumber",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
