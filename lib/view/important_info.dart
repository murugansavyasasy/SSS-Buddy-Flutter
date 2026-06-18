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

class AppStoreLink {
  final String appName;
  final String storeName;
  final String storeLabel;
  final String url;
  final bool isApple;

  AppStoreLink({
    required this.appName,
    required this.storeName,
    required this.storeLabel,
    required this.url,
    required this.isApple,
  });
}

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
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (info) {
                    if (info == null)
                      return const Center(child: Text("No data found"));
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

  List<AppStoreLink> _getAppLinks(info) {
    return [
      AppStoreLink(
        appName: "SchoolChimes",
        storeName: "Android",
        storeLabel: "Play Store",
        url: info.playStoreLinkSchoolChimes,
        isApple: false,
      ),
      AppStoreLink(
        appName: "SchoolChimes",
        storeName: "iOS",
        storeLabel: "App Store",
        url: "https://apps.apple.com/in/app/school-chimes-ss/id6758079127",
        isApple: true,
      ),
      AppStoreLink(
        appName: "Gradit",
        storeName: "Android",
        storeLabel: "Play Store",
        url: "https://play.google.com/store/apps/details?id=com.vsca.vsnapvoicecollege",
        isApple: false,
      ),
      AppStoreLink(
        appName: "Gradit",
        storeName: "iOS",
        storeLabel: "App Store",
        url: "https://apps.apple.com/ml/app/gradit/id1574188445",
        isApple: true,
      ),
      AppStoreLink(
        appName: "LetsReach",
        storeName: "Android",
        storeLabel: "Play Store",
        url: "https://play.google.com/store/apps/details?id=vs.ca.letsreach",
        isApple: false,
      ),
    ].where((app) => app.url.isNotEmpty).toList();
  }
  Widget _buildContent(info) {
    final appLinks = _getAppLinks(info);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Support ───────────────────────────────────────────
        const SectionLabel(label: "Support"),
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

        const SectionLabel(label: "Sales"),
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

        if (appLinks.isNotEmpty) ...[
          const SectionLabel(label: "Download App"),
          ..._buildAppSections(appLinks),
        ],

        const SectionLabel(label: "Other"),
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

  List<Widget> _buildAppSections(List<AppStoreLink> apps) {
    final widgets = <Widget>[];

    // App name by group பண்ணு
    final groupedApps = <String, List<AppStoreLink>>{};
    for (final app in apps) {
      groupedApps.putIfAbsent(app.appName, () => []).add(app);
    }

    groupedApps.forEach((appName, storeLinks) {
      // App name label
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            appName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ),
      );

      // Store badges — 2 per row
      for (int i = 0; i < storeLinks.length; i += 2) {
        final hasSecond = i + 1 < storeLinks.length;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: AppBadgeCard(
                    icon: storeLinks[i].isApple
                        ? Icons.apple_rounded
                        : Icons.android_rounded,
                    iconColor: storeLinks[i].isApple
                        ? const Color(0xFF185FA5)
                        : const Color(0xFF3B6D11),
                    iconBg: storeLinks[i].isApple
                        ? const Color(0xFFE6F1FB)
                        : const Color(0xFFEAF3DE),
                    store: storeLinks[i].storeName,
                    name: storeLinks[i].storeLabel,
                    onTap: () => _launch(storeLinks[i].url),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: hasSecond
                      ? AppBadgeCard(
                    icon: storeLinks[i + 1].isApple
                        ? Icons.apple_rounded
                        : Icons.android_rounded,
                    iconColor: storeLinks[i + 1].isApple
                        ? const Color(0xFF185FA5)
                        : const Color(0xFF3B6D11),
                    iconBg: storeLinks[i + 1].isApple
                        ? const Color(0xFFE6F1FB)
                        : const Color(0xFFEAF3DE),
                    store: storeLinks[i + 1].storeName,
                    name: storeLinks[i + 1].storeLabel,
                    onTap: () => _launch(storeLinks[i + 1].url),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }
    });

    return widgets;
  }

  static Future<void> _launch(String url) async {
    final cleanedUrl = url
        .trim()
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '');

    print("Cleaned URL: [$cleanedUrl]");

    final uri = Uri.tryParse(cleanedUrl);

    if (uri == null) {
      print("Invalid URI");
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}