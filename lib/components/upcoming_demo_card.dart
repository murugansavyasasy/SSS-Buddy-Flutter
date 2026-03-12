import 'package:flutter/material.dart';

class UpcomingDemoCard extends StatelessWidget {
  const UpcomingDemoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
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
                Icon(
                  Icons.keyboard_voice_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "241362",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Cambridge School",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                Row(children: [const Text("+91 6383904707",style: TextStyle(fontSize: 12),)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
