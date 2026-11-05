import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/model/TrackPointModel.dart';

/// Keeps the GPS points of a day's trip on the phone, so the route survives
/// an app restart and can be uploaded to the server later if the network
/// was down.
///
/// Keys are per user per day:
///   trip_track_<userId>_<yyyy-MM-dd>          → JSON list of points
///   trip_track_uploaded_<userId>_<yyyy-MM-dd> → how many were uploaded
class TripTrackStore {
  static const _prefix = 'trip_track_';
  static const _uploadedPrefix = 'trip_track_uploaded_';
  static const _keepDays = 7;

  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String _pointsKey(int userId, String day) => '$_prefix${userId}_$day';
  static String _uploadedKey(int userId, String day) =>
      '$_uploadedPrefix${userId}_$day';

  static Future<List<TrackPoint>> load(int userId, String day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pointsKey(userId, day));
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TrackPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(
      int userId, String day, List<TrackPoint> points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pointsKey(userId, day),
      jsonEncode(points.map((p) => p.toJson()).toList()),
    );
  }

  static Future<int> uploadedCount(int userId, String day) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_uploadedKey(userId, day)) ?? 0;
  }

  static Future<void> setUploadedCount(int userId, String day, int n) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_uploadedKey(userId, day), n);
  }

  /// Drops stored routes older than [_keepDays] days.
  static Future<void> pruneOld() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: _keepDays));
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final day = key.substring(key.lastIndexOf('_') + 1);
      final date = DateTime.tryParse(day);
      if (date != null && date.isBefore(cutoff)) {
        await prefs.remove(key);
      }
    }
  }
}
