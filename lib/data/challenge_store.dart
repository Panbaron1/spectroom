import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/challenge.dart';
import 'seeds.dart';

/// On-device challenge store. Built-in seeds are always present and read-only;
/// parent-created challenges persist to a single JSON file in the app docs dir.
/// No network, no accounts — GDPR-friendly and a trust feature.
class ChallengeStore extends ChangeNotifier {
  ChallengeStore._();
  static final ChallengeStore instance = ChallengeStore._();

  final List<Challenge> _custom = [];
  bool _loaded = false;

  /// Seeds in fixed order; custom version overrides seed when IDs match
  /// (so voice recordings saved on a built-in are preserved). Pure custom
  /// challenges appended after seeds.
  List<Challenge> get all {
    final customById = Map.fromEntries(_custom.map((c) => MapEntry(c.id, c)));
    return [
      ...seedChallenges.map((s) {
        final c = customById[s.id];
        if (c == null) return s;
        // Heal: builder bug wrote titleEn = titleCs; restore seed's English title
        var healed = (c.titleEn == c.titleCs && s.titleEn != s.titleCs)
            ? c.copyWith(titleEn: s.titleEn)
            : c;
        // Heal seed steps: iterate STORED steps (preserves user edits —
        // additions, deletions, reorder), fix corrupt labelEn, then append
        // any new seed steps that didn't exist in the stored version.
        final seedStepsById = Map.fromEntries(s.steps.map((st) => MapEntry(st.id, st)));
        final healedSteps = healed.steps.map((st) {
          final seedSt = seedStepsById[st.id];
          if (seedSt == null) return st; // user-added step, keep as-is
          final corrupt = st.labelEn.isEmpty ||
              (st.labelEn == st.labelCs && seedSt.labelEn != seedSt.labelCs);
          return corrupt ? st.copyWith(labelEn: seedSt.labelEn) : st;
        }).toList();
        final storedIds = {for (final st in healed.steps) st.id};
        final newSeedSteps = s.steps.where((st) => !storedIds.contains(st.id)).toList();
        return healed.copyWith(steps: [...healedSteps, ...newSeedSteps]);
      }),
      ..._custom.where((c) => !seedChallenges.any((s) => s.id == c.id)),
    ];
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/spectroom_challenges.json');
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString()) as List;
        _custom
          ..clear()
          ..addAll(raw.map(
              (e) => Challenge.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint('ChallengeStore load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final f = await _file();
    await f.writeAsString(
        jsonEncode(_custom.map((c) => c.toJson()).toList()));
  }

  Future<void> upsert(Challenge c) async {
    final i = _custom.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      _custom[i] = c;
    } else {
      _custom.add(c);
    }
    await _persist();
    notifyListeners();
  }

  Challenge? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    _custom.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  /// Serialises all custom data (seed overrides + new challenges) to JSON.
  String exportJson() =>
      jsonEncode(_custom.map((c) => c.toJson()).toList());

  /// Merges challenges from a JSON string. Skips malformed entries.
  /// Returns number of challenges imported.
  Future<int> importJson(String rawJson) async {
    final list = jsonDecode(rawJson) as List<dynamic>;
    int count = 0;
    for (final e in list) {
      try {
        final c = Challenge.fromJson(e as Map<String, dynamic>);
        await upsert(c);
        count++;
      } catch (_) {}
    }
    return count;
  }
}
