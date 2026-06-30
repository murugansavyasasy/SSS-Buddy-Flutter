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
      child: Container(
        width: 260,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xfff8f6f6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left Icon Block
            Container(
              width: 70,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xff2E4F7D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.keyboard_voice_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Text Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Demo ID
                    Text(
                      demoId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // ✅ dots
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // School Name
                    Text(
                      schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // ✅ dots
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Principal Number
                    Text(
                      "$principalNumber",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // ✅ dots
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow Icon
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}