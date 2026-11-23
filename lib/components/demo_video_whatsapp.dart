import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/model/ExhibitionModel.dart';
import '../auth/model/ManagementVideosModel.dart';
import '../repository/app_url.dart';
import 'open_in_browser.dart';
import '../viewModel/exhibition_viewmodel.dart';
import '../viewModel/management_videos_viewmodel.dart';

/// True when a fallback demo video link is configured
/// (`AppUrl.exhibitionDemoVideoUrl`). Empty hides every WhatsApp button.
bool get demoVideoEnabled => AppUrl.exhibitionDemoVideoUrl.trim().isNotEmpty;

/// True when [number] is a usable 10-digit Indian mobile number.
bool canSendDemoVideoTo(String number) =>
    demoVideoEnabled && isValidIndianMobile(normalizeIndianMobile(number));

/// English (`AppUrl.demoVideoEnglishUrl`), then Tamil, Hindi and Kannada
/// videos from the Management Videos module; the single
/// `AppUrl.exhibitionDemoVideoUrl` link when there is none at all.
Future<List<DemoVideoLink>> demoVideoLinks(BuildContext context) async {
  final fixed = {'English': AppUrl.demoVideoEnglishUrl};
  var all = const <Managementvideosmodel>[];
  try {
    all = await ProviderScope.containerOf(context, listen: false)
        .read(managementVideosProvider.future)
        .timeout(const Duration(seconds: 15));
  } catch (_) {
    // Videos didn't load: still send the fixed English link.
  }
  final picked = pickDemoVideoLinks(all, fixed: fixed);
  if (picked.isNotEmpty) return picked;
  return [(label: '', url: AppUrl.exhibitionDemoVideoUrl)];
}

/// Opens [number]'s WhatsApp chat with the demo video links prefilled: in
/// the WhatsApp app when installed, else WhatsApp Web. Returns true when it
/// opened. Shows nothing on failure; callers report errors in their own style.
Future<bool> launchDemoVideoWhatsApp(
  BuildContext context, {
  required String number,
  String visitorName = '',
  String exhibitionName = '',
  String? greeting,
}) async {
  final videos = await demoVideoLinks(context);
  final hasApp = await isWhatsAppInstalled();
  final uri = demoVideoWhatsAppUri(
    number: number,
    videos: videos,
    visitorName: visitorName,
    exhibitionName: exhibitionName,
    greeting: greeting,
    web: !hasApp,
  );
  // No WhatsApp app: WhatsApp Web, in Safari first on iOS, then Chrome.
  if (!hasApp) return openInBrowser(uri);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// School demo: sends the demo videos to the principal's [number].
Future<void> sendSchoolDemoVideoOnWhatsApp(
  BuildContext context, {
  required String number,
  String schoolName = '',
}) async {
  final school = schoolName.trim();
  final ok = await launchDemoVideoWhatsApp(
    context,
    number: number,
    greeting: school.isEmpty
        ? 'Dear Principal,Thank You for your time.'
        : 'Dear Principal,Thank You for your time with $school.',
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: const Text('Could not open WhatsApp'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
