import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/model/FollowUpModel.dart';

/// Storage for follow-ups. Only [LocalFollowUpRepository] exists today; when
/// the backend decision is made (REST API or Firebase), add another
/// implementation and swap it in `followUpRepositoryProvider` — the
/// view model and screens stay the same.
abstract class FollowUpRepository {
  Future<List<FollowUp>> fetchAll(String ownerId);

  /// Returns the stored follow-up with its new id.
  Future<FollowUp> create(FollowUp f);

  Future<void> update(FollowUp f);

  Future<void> delete(String ownerId, String id);
}

/// Device-only storage (shared_preferences), one JSON list per logged-in user.
/// Data stays on this phone: it is not visible to managers and is lost if the
/// app is uninstalled.
class LocalFollowUpRepository implements FollowUpRepository {
  static const _keyPrefix = 'followups_v1_';
  final _random = Random();

  String _key(String ownerId) => '$_keyPrefix$ownerId';

  Future<List<FollowUp>> _read(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(ownerId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FollowUp.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String ownerId, List<FollowUp> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(ownerId),
      jsonEncode(items.map((f) => f.toJson()).toList()),
    );
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 20)}';

  @override
  Future<List<FollowUp>> fetchAll(String ownerId) => _read(ownerId);

  @override
  Future<FollowUp> create(FollowUp f) async {
    final items = await _read(f.ownerId);
    final stored = f.withId(_newId());
    items.add(stored);
    await _write(f.ownerId, items);
    return stored;
  }

  @override
  Future<void> update(FollowUp f) async {
    final items = await _read(f.ownerId);
    final i = items.indexWhere((x) => x.id == f.id);
    if (i < 0) return;
    items[i] = f;
    await _write(f.ownerId, items);
  }

  @override
  Future<void> delete(String ownerId, String id) async {
    final items = await _read(ownerId);
    items.removeWhere((x) => x.id == id);
    await _write(ownerId, items);
  }
}
