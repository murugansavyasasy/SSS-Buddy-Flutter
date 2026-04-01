import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAddressBox extends StatelessWidget {
  final String tag;
  final String address;

  const AppAddressBox({
    super.key,
    required this.tag,
    required this.address,
  });

  bool isUrl(String text) {
    return text.startsWith("http://") || text.startsWith("https://");
  }
  Future<void> openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw "Error";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = address.isEmpty ? '-' : address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          isUrl(displayText)
              ? GestureDetector(
            onTap: () => openUrl(context, displayText),
            child: Text(
              displayText,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              : Text(displayText),
        ],
      ),
    );
  }
}