import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iPad Reports layout: `false` = split (filters panel + trips), `true` =
/// full view (one full-width list). Remembered on the device.
class ReportsFullViewNotifier extends Notifier<bool> {
  static const _prefKey = 'reports_ipad_full_view';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKey);
      if (saved != null) state = saved;
    } catch (_) {
      // Preference is a convenience only; keep the default.
    }
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, state);
    } catch (_) {}
  }
}

final reportsFullViewProvider =
    NotifierProvider<ReportsFullViewNotifier, bool>(ReportsFullViewNotifier.new);
