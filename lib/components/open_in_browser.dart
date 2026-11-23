import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Browser URLs to try for [web], in order. iOS: Safari first
/// (`x-safari-https`, iOS 17+), then Chrome (`googlechromes`), then the
/// default browser. Elsewhere: the default browser (Chrome on most Android).
List<Uri> browserCandidates(Uri web, {required bool isIOS}) {
  if (!isIOS || (web.scheme != 'https' && web.scheme != 'http')) return [web];
  final rest = web.toString().substring(web.scheme.length); // "://host/…"
  final secure = web.scheme == 'https';
  return [
    Uri.parse('${secure ? 'x-safari-https' : 'x-safari-http'}$rest'),
    Uri.parse('${secure ? 'googlechromes' : 'googlechrome'}$rest'),
    web,
  ];
}

/// Opens [web] in a browser: Safari first on iOS, then Chrome, then the
/// default browser. Returns true when one of them opened it.
Future<bool> openInBrowser(Uri web) async {
  for (final uri in browserCandidates(web, isIOS: Platform.isIOS)) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
    } catch (_) {
      // Browser not installed / scheme not supported: try the next one.
    }
  }
  return false;
}
