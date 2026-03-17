import 'package:flutter/material.dart';
import '../auth/model/Demolist.dart';
import '../utils/routes/routes_name.dart';

class DemoCard extends StatelessWidget {
  final Demolist item;

  const DemoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Demo ID: ${item.demoId}",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      item.principalNumber.toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          InkWell(
            onTap: () {
              Navigator.pushReplacementNamed(context, RoutesName.recordvoice);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.keyboard_voice_sharp,
                size: 16,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
