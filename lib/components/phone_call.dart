import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer for [number], at most once at a time.
///
/// iOS (and some Android dialers) show a "Call …?" confirmation for every
/// `tel:` launch, so repeated taps used to stack up one popup per tap.
/// While a call is being opened, and for [cooldown] afterwards, further taps
/// are ignored.
class PhoneCall {
  PhoneCall._();

  static bool _busy = false;
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  static const cooldown = Duration(seconds: 2);

  /// Returns true when the dialer was opened; false when ignored or failed.
  static Future<bool> dial(String number) async {
    final n = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (n.isEmpty) return false;
    final now = DateTime.now();
    if (_busy || now.difference(_last) < cooldown) return false;
    _busy = true;
    HapticFeedback.selectionClick();
    try {
      return await launchUrl(Uri(scheme: 'tel', path: n));
    } catch (_) {
      return false;
    } finally {
      _busy = false;
      _last = DateTime.now();
    }
  }
}
