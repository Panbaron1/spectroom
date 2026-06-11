import 'package:flutter/material.dart';

import '../data/challenge_store.dart';
import '../data/lang_store.dart';
import '../data/schedule_store.dart';
import '../design/spectrum.dart';
import '../models/challenge.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    // Request once on open — not on every add press.
    NotificationService.instance.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LangStore.instance.lang;
    return Scaffold(
      backgroundColor: Spectrum.bg,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (r) => Spectrum.brand.createShader(r),
          child: Text(
            lang == 'en' ? 'Reminders' : 'Připomínky',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Spectrum.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Spectrum.inkSoft),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFlow(context, lang),
        backgroundColor: Spectrum.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          lang == 'en' ? 'Add reminder' : 'Přidat připomínku',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimatedBuilder(
        animation: ScheduleStore.instance,
        builder: (context, _) {
          final entries = ScheduleStore.instance.entries;
          if (entries.isEmpty) return _EmptyState(lang: lang);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                Gap.md, Gap.md, Gap.md, 100),
            itemCount: entries.length,
            itemBuilder: (ctx, i) =>
                _EntryRow(entry: entries[i], lang: lang),
          );
        },
      ),
    );
  }

  Future<void> _showAddFlow(BuildContext context, String lang) async {
    final challenge = await showModalBottomSheet<Challenge>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Spectrum.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Radii.lg))),
      builder: (_) => _ChallengePickerSheet(lang: lang),
    );
    if (challenge == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: Spectrum.coral,
              onPrimary: Colors.white,
              surface: Spectrum.surface,
              onSurface: Spectrum.ink,
              surfaceContainerHighest: Spectrum.bg,
              onSurfaceVariant: Spectrum.inkSoft,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Spectrum.surface,
              dialBackgroundColor: Spectrum.bg,
              dialHandColor: Spectrum.coral,
              dialTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : Spectrum.ink),
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Spectrum.coral.withValues(alpha: 0.15)
                    : Spectrum.bg),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Spectrum.coral
                    : Spectrum.ink),
              entryModeIconColor: Spectrum.inkSoft,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.lg)),
              hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm)),
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (time == null || !context.mounted) return;

    await ScheduleStore.instance.add(
      challengeId: challenge.id,
      hour: time.hour,
      minute: time.minute,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang == 'en'
            ? 'Reminder set for ${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")} daily'
            : 'Připomínka nastavena na ${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")} každý den'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── Entry row ────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final ScheduleEntry entry;
  final String lang;
  const _EntryRow({required this.entry, required this.lang});

  @override
  Widget build(BuildContext context) {
    final challenge = ChallengeStore.instance.byId(entry.challengeId);
    if (challenge == null) return const SizedBox.shrink();

    final accent = Spectrum.accent(challenge.category);
    final tint = Spectrum.accentTint(challenge.category);
    final h = entry.hour.toString().padLeft(2, '0');
    final m = entry.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Spectrum.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: [
            BoxShadow(
              color: Spectrum.ink.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 10),
          child: Row(
            children: [
              PictogramTile(challenge.cover, size: 44, tint: tint),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title(lang),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13,
                            color: entry.enabled
                                ? accent
                                : Spectrum.inkSoft),
                        const SizedBox(width: 4),
                        Text(
                          '$h:$m · ${lang == "en" ? "daily" : "každý den"}',
                          style: TextStyle(
                              fontSize: 12,
                              color: entry.enabled
                                  ? accent
                                  : Spectrum.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: entry.enabled,
                onChanged: (_) =>
                    ScheduleStore.instance.toggle(entry.id),
                activeColor: accent,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: Spectrum.inkSoft),
                onPressed: () => ScheduleStore.instance.remove(entry.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Spectrum.sky.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 40, color: Spectrum.sky),
            ),
            const SizedBox(height: 20),
            Text(
              lang == 'en' ? 'No reminders yet' : 'Žádné připomínky',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'en'
                  ? 'Tap + to schedule a daily reminder for any challenge'
                  : 'Klepněte na + a nastavte denní připomínku pro výzvu',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Spectrum.inkSoft, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Challenge picker ─────────────────────────────────────────

class _ChallengePickerSheet extends StatelessWidget {
  final String lang;
  const _ChallengePickerSheet({required this.lang});

  @override
  Widget build(BuildContext context) {
    final challenges = ChallengeStore.instance.all;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 4, Gap.lg, 12),
            child: Text(
              lang == 'en' ? 'Choose a challenge' : 'Vyber výzvu',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: challenges.length,
              itemBuilder: (ctx, i) {
                final c = challenges[i];
                final tint = Spectrum.accentTint(c.category);
                final accent = Spectrum.accent(c.category);
                return InkWell(
                  onTap: () => Navigator.pop(ctx, c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.lg, vertical: 10),
                    child: Row(
                      children: [
                        PictogramTile(c.cover, size: 40, tint: tint),
                        const SizedBox(width: Gap.sm),
                        Expanded(
                          child: Text(
                            c.title(lang),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: accent, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
