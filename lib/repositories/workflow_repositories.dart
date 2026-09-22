import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workflow_models.dart';

abstract interface class LocalRepository {
  Future<CollectorProfile?> loadProfile();
  Future<void> saveProfile(CollectorProfile profile);
  Future<RecyclerProfile?> loadRecyclerProfile();
  Future<void> saveRecyclerProfile(RecyclerProfile profile);
  Future<void> clearProfile();
  Future<List<DigitalLot>> loadLots();
  Future<void> saveLots(List<DigitalLot> lots);
  Future<DateTime?> loadLastSync();
  Future<void> saveLastSync(DateTime value);
}

class SharedPreferencesLocalRepository implements LocalRepository {
  static const profileKey = 'kwc_profile_v2';
  static const recyclerProfileKey = 'kwc_recycler_profile_v2';
  static const lotsKey = 'kwc_lots_v2';
  static const lastSyncKey = 'kwc_last_sync_v2';

  @override
  Future<CollectorProfile?> loadProfile() async {
    final raw = (await SharedPreferences.getInstance()).getString(profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CollectorProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(CollectorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(profileKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<RecyclerProfile?> loadRecyclerProfile() async {
    final raw = (await SharedPreferences.getInstance()).getString(recyclerProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return RecyclerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecyclerProfile(RecyclerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(recyclerProfileKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(profileKey);
    await prefs.remove(recyclerProfileKey);
  }

  @override
  Future<List<DigitalLot>> loadLots() async {
    final raw = (await SharedPreferences.getInstance()).getString(lotsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(DigitalLot.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveLots(List<DigitalLot> lots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        lotsKey, jsonEncode(lots.map((lot) => lot.toJson()).toList()));
  }

  @override
  Future<DateTime?> loadLastSync() async {
    final value =
        (await SharedPreferences.getInstance()).getString(lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> saveLastSync(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSyncKey, value.toIso8601String());
  }
}

abstract interface class RemoteRepository {
  Future<void> uploadLot(DigitalLot lot);
}

class DemoRemoteRepository implements RemoteRepository {
  DemoRemoteRepository({this.shouldFail = false});
  final bool shouldFail;
  final Set<String> uploadedLotIds = {};

  @override
  Future<void> uploadLot(DigitalLot lot) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (shouldFail) throw StateError('Demo sync failure');
    uploadedLotIds.add(lot.lotId);
  }
}
