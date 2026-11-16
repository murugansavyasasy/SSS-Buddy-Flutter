import 'package:flutter/material.dart';

import 'glass_card.dart';

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
    return SizedBox(
      width: 268,
      height: 90,
      child: SoftCard(
        radius: 20,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: homePastel(HomeGlass.blue),
              ),
              child: Icon(Icons.keyboard_voice_rounded, size: 22, color: homeDeep(HomeGlass.blue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DEMO #$demoId",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: HomeGlass.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: HomeGlass.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 12, color: HomeGlass.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "$principalNumber",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: HomeGlass.muted,
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
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: HomeGlass.bg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: HomeGlass.muted),
            ),
          ],
        ),
      ),
    );
  }
}
