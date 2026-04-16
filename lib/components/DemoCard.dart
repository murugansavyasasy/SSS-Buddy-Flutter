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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF2563EB),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.schoolName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Demo #${item.demoId}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openDialPad(item.principalNumber.toString()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone,
                        size: 13, color: Color(0xFF15803D)),
                    const SizedBox(width: 6),
                    Text(
                      item.principalNumber.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, RoutesName.recordvoice,
                    arguments: item),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mic,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Record',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDialPad(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}