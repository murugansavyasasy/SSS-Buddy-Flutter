import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../auth/model/SchoolDocuments.dart';
import '../Values/Colors/app_colors.dart';

class SchoolDocumentCard extends StatelessWidget {
  final Schooldocuments item;

  const SchoolDocumentCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(item.DocumentType);
    final icon = _typeIcon(item.DocumentType);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: typeColor, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.DocumentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.DocumentDescription.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.DocumentDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888780),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                item.DocumentType.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (item.DocumentType == 'video') {
      _showVideoBottomSheet(context);
    } else {
      _launchURL(item.DocumentURL);
    }
  }

  void _showVideoBottomSheet(BuildContext context) {
    final List<dynamic> videos = jsonDecode(item.DocumentURL);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Videos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...videos.map<Widget>((v) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Color(0xFF534AB7), size: 20),
                ),
                title: Text(
                  v['VideoName'],
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  v['videolocation'].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(v['VideoLink']);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':   return const Color(0xFFD85A30);
      case 'xls':
      case 'xlsx':  return const Color(0xFF3B6D11);
      case 'docx':  return const Color(0xFF185FA5);
      case 'pptx':  return const Color(0xFFBA7517);
      case 'video': return const Color(0xFF534AB7);
      default:      return const Color(0xFF5F5E5A);
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':   return Icons.picture_as_pdf_rounded;
      case 'xls':
      case 'xlsx':  return Icons.table_chart_rounded;
      case 'docx':  return Icons.description_rounded;
      case 'pptx':  return Icons.slideshow_rounded;
      case 'video': return Icons.play_circle_rounded;
      default:      return Icons.insert_drive_file_rounded;
    }
  }
}