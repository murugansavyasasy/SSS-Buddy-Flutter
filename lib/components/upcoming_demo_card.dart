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

  static const Color _navy = Color(0xFF2E4F7D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 268,
        height: 90,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF1)),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Left icon panel ──────────────────────────────
            Container(
              width: 62,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A6098), _navy],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.keyboard_voice_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DEMO #$demoId",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF9099A3),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2530),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 12,
                        color: Color(0xFF7A828C),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "$principalNumber",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Action button ────────────────────────────────
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: _navy,
              ),
            ),

            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
