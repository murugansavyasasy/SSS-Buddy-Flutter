import 'package:flutter/material.dart';
import '../auth/model/Demolist.dart';
import '../utils/routes/routes_name.dart';
import 'package:url_launcher/url_launcher.dart';

class DemoCard extends StatelessWidget {
  final Demolist item;

  const DemoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // soft background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _buildRow("Demo ID", item.demoId.toString()),

          const SizedBox(height: 10),

          _buildRow(
            "School Name",
            item.schoolName,
            isBold: true,
          ),

          const SizedBox(height: 10),

          _buildRow(
            "Principal No",
            item.principalNumber.toString(),
            icon: Icons.phone,
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                      context, RoutesName.recordvoice);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.keyboard_voice,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Record",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> openDialPad(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone.trim());

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("Could not launch $url");
    }
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.bold
            ),
          ),
        ),

        const Text(":  "),

        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.green),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (label == "Principal No") {
                      print("label name  matched");
                      openDialPad(value);
                    } else {
                      print("Value is empty");
                    }
                    },
                  child: Text(
                    value,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}