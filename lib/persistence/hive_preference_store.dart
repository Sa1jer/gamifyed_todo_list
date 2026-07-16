import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/tutorial_progress.dart';
import 'legacy_storage_codec.dart';

/// Owns device-local preferences stored outside committed domain snapshots.
class HivePreferenceStore {
  const HivePreferenceStore({required this.meta, required this.codec});

  final Box<String> meta;
  final LegacyStorageCodec codec;

  Future<bool?> loadBool(String key) async {
    final raw = meta.get(key);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> saveBool(String key, bool value) =>
      meta.put(key, value ? 'true' : 'false');

  Future<int?> loadInt(String key) async {
    final raw = meta.get(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> saveInt(String key, int value) => meta.put(key, '$value');

  Future<TutorialProgress?> loadTutorialProgress(String key) async {
    final raw = meta.get(key);
    if (raw == null) return null;
    final data = codec.decodeOrNull(raw, codec.decodeMap);
    if (data == null) return const TutorialProgress.empty();
    return TutorialProgress.fromJson(data);
  }

  Future<void> saveTutorialProgress(String key, TutorialProgress progress) =>
      meta.put(key, jsonEncode(progress.toJson()));
}
