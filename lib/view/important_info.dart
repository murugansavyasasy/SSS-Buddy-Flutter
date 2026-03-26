import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/InfoRowData.dart';
import '../components/AppBadgeCard.dart';
import '../components/InfoCard.dart';
import '../components/SectionLabel.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/important_info_viewmodel.dart';
import 'dashboard.dart';

import 'package:url_launcher/url_launcher.dart';

class ImportantInfoScreen extends ConsumerWidget {
  const ImportantInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(importantinfoviewprovider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: "Important Info",
              navigateTo: const Dashboard(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: infoAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (info) {
                    if (info == null) return const Center(child: Text("No data found"));
                    return _buildContent(info);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(info) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        SectionLabel(label: "Support"),
        InfoCard(items: [
          InfoRowData(
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF185FA5),
            iconBg: const Color(0xFFE6F1FB),
            label: "Helpline number",
            value: info.helplineNumber,
            onTap: () => _launch("tel:${info.helplineNumber}"),
          ),
          InfoRowData(
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF3B6D11),
            iconBg: const Color(0xFFEAF3DE),
            label: "Support email",
            value: info.schoolSupportEmailId,
            onTap: () => _launch("mailto:${info.schoolSupportEmailId}"),
          ),
        ]),

        SectionLabel(label: "Sales"),
        InfoCard(items: [
          InfoRowData(
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF993C1D),
            iconBg: const Color(0xFFFAECE7),
            label: "Sales enquiry number",
            value: info.salesEnquiryNumber,
            onTap: () => _launch("tel:${info.salesEnquiryNumber}"),
          ),
          InfoRowData(
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF854F0B),
            iconBg: const Color(0xFFFAEEDA),
            label: "Sales enquiry email",
            value: info.salesEnquiryEmailId,
            onTap: () => _launch("mailto:${info.salesEnquiryEmailId}"),
          ),
          InfoRowData(
            icon: Icons.slideshow_rounded,
            iconColor: const Color(0xFF534AB7),
            iconBg: const Color(0xFFEEEDFE),
            label: "Product presentation",
            value: "View on Canva",
            isLink: true,
            onTap: () => _launch(info.productPresentation),
          ),
        ]),

        SectionLabel(label: "Download App"),
        Row(
          children: [
            Expanded(
              child: AppBadgeCard(
                icon: Icons.android_rounded,
                iconColor: const Color(0xFF3B6D11),
                iconBg: const Color(0xFFEAF3DE),
                store: "Google",
                name: "Play Store",
                onTap: () => _launch(info.playStoreLinkSchoolChimes),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppBadgeCard(
                icon: Icons.apple_rounded,
                iconColor: const Color(0xFF185FA5),
                iconBg: const Color(0xFFE6F1FB),
                store: "Apple",
                name: "App Store",
                onTap: () => _launch(info.appleStoreLinkSchoolChimes),
              ),
            ),
          ],
        ),

        SectionLabel(label: "Other"),
        InfoCard(items: [
          InfoRowData(
            icon: Icons.call_received_rounded,
            iconColor: const Color(0xFF5F5E5A),
            iconBg: const Color(0xFFF1EFE8),
            label: "Calls received from",
            value: info.callsWillBeReceivedFrom,
          ),
        ]),
      ],
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
