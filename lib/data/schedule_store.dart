import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'challenge_store.dart';
import 'lang_store.dart';
import '../services/notification_service.dart';

class ScheduleEntry {
  final String id;
  final String challengeId;
  final int hour;
  final int minute;
  final bool enabled;

  const ScheduleEntry({
    required this.id,
    required this.challengeId,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  ScheduleEntry copyWith({bool? enabled, int? hour, int? minute}) =>
      ScheduleEntry(
        id: id,
        challengeId: challengeId,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'challengeId': challengeId,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) => ScheduleEntry(
        id: j['id'] as String,
        challengeId: j['challengeId'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        enabled: j['enabled'] as bool? ?? true,
      );
}

class ScheduleStore extends ChangeNotifier {
  static final instance = ScheduleStore._();
  ScheduleStore._();

  static const _key = 'schedule_entries_v1';
  static const _uuid = Uuid();

  List<ScheduleEntry> _entries = [];
  List<ScheduleEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _entries = list
          .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> add({
    required String challengeId,
    required int hour,
    required int minute,
  }) async {
    final entry = ScheduleEntry(
      id: _uuid.v4(),
      challengeId: challengeId,
      hour: hour,
      minute: minute,
    );
    _entries.add(entry);
    await _save();
    notifyListeners();
    await _scheduleEntry(entry);
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
    await NotificationService.instance.cancel(NotificationService.instance.notifId(id));
  }

  Future<void> toggle(String id) async {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final updated = _entries[i].copyWith(enabled: !_entries[i].enabled);
    _entries[i] = updated;
    await _save();
    notifyListeners();
    if (updated.enabled) {
      await _scheduleEntry(updated);
    } else {
      await NotificationService.instance
          .cancel(NotificationService.instance.notifId(id));
    }
  }

  Future<void> rescheduleAll() async {
    for (final e in _entries.where((e) => e.enabled)) {
      await _scheduleEntry(e);
    }
  }

  Future<void> _scheduleEntry(ScheduleEntry e) async {
    try {
      final challenge = ChallengeStore.instance.byId(e.challengeId);
      if (challenge == null) return;
      final lang = LangStore.instance.lang;
      final title = lang == 'en' ? challenge.titleEn : challenge.titleCs;
      final body = lang == 'en' ? 'Time for your routine' : 'Čas na vaši rutinu';
      await NotificationService.instance.scheduleDaily(
        id: NotificationService.instance.notifId(e.id),
        title: title,
        body: body,
        hour: e.hour,
        minute: e.minute,
      );
    } catch (err) {
      debugPrint('scheduleEntry failed for ${e.id}: $err');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }
}
