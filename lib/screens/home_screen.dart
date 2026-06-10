import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/challenge_store.dart';
import '../data/lang_store.dart';
import '../data/prefs.dart';
import '../design/spectrum.dart';
import '../models/challenge.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';
import 'builder_screen.dart';
import 'runner_screen.dart';

/// Library of challenges. Tap a card → pick Rehearsal or Live. FAB → build your
/// own. Long-press a parent-made card → edit/delete.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = ChallengeStore.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([store, LangStore.instance]),
      builder: (context, _) {
        final lang = LangStore.instance.lang;
        final all = store.all;
        final items = _query.isEmpty
            ? all
            : all.where((c) =>
                c.titleCs.toLowerCase().contains(_query.toLowerCase()) ||
                c.titleEn.toLowerCase().contains(_query.toLowerCase())).toList();
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openBuilder(context, null),
            backgroundColor: Spectrum.ink,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(lang == 'en' ? 'New challenge' : 'Nová výzva',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Gap.lg, Gap.lg, Gap.sm, Gap.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (r) =>
                                    Spectrum.brand.createShader(r),
                                child: const Text('Spectroom',
                                    style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1,
                                        color: Colors.white)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'en'
                                    ? 'Walk through what\'s coming.'
                                    : 'Klidně si projdi, co nás čeká.',
                                style: const TextStyle(
                                    fontSize: 15, color: Spectrum.inkSoft)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded),
                          color: Spectrum.inkSoft,
                          onPressed: () => _showSettings(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, size: 20,
                          color: Spectrum.inkSoft),
                      hintText: lang == 'en' ? 'Search…' : 'Hledat…',
                      hintStyle: const TextStyle(color: Spectrum.inkSoft),
                      filled: true,
                      fillColor: Spectrum.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, 110),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Breakpoints.gridColumns(
                        MediaQuery.sizeOf(context).width),
                    mainAxisSpacing: Gap.md,
                    crossAxisSpacing: Gap.md,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        _ChallengeCard(challenge: items[i], lang: lang),
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final String lang;
  const _ChallengeCard({required this.challenge, required this.lang});

  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  DateTime? _lastDone;

  @override
  void initState() {
    super.initState();
    _loadLastDone();
    Prefs.lastDoneNotifier.addListener(_loadLastDone);
  }

  @override
  void dispose() {
    Prefs.lastDoneNotifier.removeListener(_loadLastDone);
    super.dispose();
  }

  Future<void> _loadLastDone() async {
    final d = await Prefs.lastDone(widget.challenge.id);
    if (mounted) setState(() => _lastDone = d);
  }

  String _lastDoneLabel() {
    if (_lastDone == null) return '';
    final diff = DateTime.now().difference(_lastDone!).inDays;
    if (diff == 0) return widget.lang == 'en' ? 'Today' : 'Dnes';
    if (diff == 1) return widget.lang == 'en' ? 'Yesterday' : 'Včera';
    if (diff < 7) return widget.lang == 'en' ? '${diff}d ago' : 'Před ${diff}d';
    return widget.lang == 'en' ? '${diff ~/ 7}w ago' : 'Před ${diff ~/ 7}t';
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final lang = widget.lang;
    final accent = Spectrum.accent(challenge.category);
    final tint = Spectrum.accentTint(challenge.category);
    final lastDoneLabel = _lastDoneLabel();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Spectrum.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
              color: Spectrum.ink.withValues(alpha: 0.05),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: () => _pickMode(context, challenge),
          onLongPress: challenge.builtIn
              ? null
              : () => _openBuilder(context, challenge),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: PictogramTile(challenge.cover,
                        size: 112, tint: tint),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  challenge.title(lang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang == 'en'
                          ? '${challenge.steps.length} steps'
                          : '${challenge.steps.length} kroků',
                      style: const TextStyle(
                          fontSize: 12, color: Spectrum.inkSoft)),
                    if (lastDoneLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('·',
                          style: const TextStyle(
                              fontSize: 12, color: Spectrum.inkSoft)),
                      const SizedBox(width: 6),
                      Text(lastDoneLabel,
                          style: TextStyle(
                              fontSize: 12, color: accent)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _pickMode(BuildContext context, Challenge c) {
  final accent = Spectrum.accent(c.category);
  final lang = LangStore.instance.lang;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Spectrum.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PictogramTile(c.cover,
                size: 80, tint: Spectrum.accentTint(c.category)),
            const SizedBox(height: 14),
            Text(c.title(lang),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4)),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                _run(context, c, live: false);
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(lang == 'en' ? 'Preview' : 'Podívat se předem'),
              style: FilledButton.styleFrom(
                  backgroundColor: Spectrum.accentTint(c.category),
                  foregroundColor: Spectrum.ink,
                  minimumSize: const Size.fromHeight(58)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _run(context, c, live: true);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(lang == 'en' ? 'Do it now' : 'Děláme to teď'),
              style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(58)),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Spectrum.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Radii.lg))),
    builder: (_) => const _SettingsSheet(),
  );
}

void _run(BuildContext context, Challenge c, {required bool live}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => RunnerScreen(challenge: c, live: live)),
  );
}

void _openBuilder(BuildContext context, Challenge? existing) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BuilderScreen(existing: existing)),
  );
}

// ── Settings bottom sheet ────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  int _timerSec = 300;
  int _countdownN = 10;
  bool _timerDisplayMinSec = true;
  bool _loaded = false;
  bool _exporting = false;
  bool _importing = false;
  late final TextEditingController _vocativeCtrl;

  @override
  void initState() {
    super.initState();
    _vocativeCtrl = TextEditingController();
    Future.wait([
      Prefs.standaloneTimerSec(),
      Prefs.standaloneCountdownN(),
      Prefs.kidVocative(),
      Prefs.timerDisplayMinSec(),
    ]).then((vals) {
      if (mounted) {
        setState(() {
          _timerSec = vals[0] as int;
          _countdownN = vals[1] as int;
          _vocativeCtrl.text = vals[2] as String;
          _timerDisplayMinSec = vals[3] as bool;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _vocativeCtrl.dispose();
    super.dispose();
  }

  String get _lang => LangStore.instance.lang;

  void _adjustTimer(int deltaSec) {
    final v = (_timerSec + deltaSec).clamp(30, 30 * 60);
    setState(() => _timerSec = v);
    Prefs.setStandaloneTimerSec(v);
  }

  void _adjustCountdown(int delta) {
    final v = (_countdownN + delta).clamp(2, 100);
    setState(() => _countdownN = v);
    Prefs.setStandaloneCountdownN(v);
  }

  void _startTimer(BuildContext ctx) {
    final sec = _timerSec;
    final nav = Navigator.of(ctx);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => RunnerScreen(
        live: true,
        challenge: Challenge(
          id: 'standalone.timer',
          titleCs: 'Časovač',
          titleEn: 'Timer',
          category: ChallengeCategory.routine,
          cover: const PictogramRef.asset('finish'),
          steps: [
            ChallengeStep(
              id: 'st.step',
              kind: StepKind.timer,
              pictogram: const PictogramRef.asset('finish'),
              labelCs: 'Jdeme na to',
              labelEn: 'Go',
              durationSec: sec,
            ),
          ],
        ),
      ),
    ));
  }

  void _startCountdown(BuildContext ctx) {
    final n = _countdownN;
    final nav = Navigator.of(ctx);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => RunnerScreen(
        live: true,
        challenge: Challenge(
          id: 'standalone.countdown',
          titleCs: 'Odpočet',
          titleEn: 'Countdown',
          category: ChallengeCategory.hygiene,
          cover: const PictogramRef.asset('star'),
          steps: [
            ChallengeStep(
              id: 'sc.step',
              kind: StepKind.countdown,
              pictogram: const PictogramRef.asset('star'),
              labelCs: 'Odpočítáváme!',
              labelEn: 'Counting down!',
              count: n,
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _doExport(BuildContext ctx) async {
    setState(() => _exporting = true);
    try {
      final json = ChallengeStore.instance.exportJson();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/spectroom_backup.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Spectroom backup',
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _doImport(BuildContext ctx) async {
    final lang = LangStore.instance.lang;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: Text(lang == 'en' ? 'Restore backup' : 'Obnovit zálohu'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Paste JSON here…',
            hintStyle: const TextStyle(color: Spectrum.inkSoft),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(lang == 'en' ? 'Cancel' : 'Zrušit')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(lang == 'en' ? 'Import' : 'Importovat')),
        ],
      ),
    );
    ctrl.dispose();
    if (ok != true || ctrl.text.trim().isEmpty) return;
    setState(() => _importing = true);
    try {
      final count = await ChallengeStore.instance.importJson(ctrl.text.trim());
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(lang == 'en'
              ? 'Imported $count challenge${count == 1 ? '' : 's'}'
              : 'Importováno: $count výzev'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Import failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }
    final lang = _lang;
    final mm = _timerSec ~/ 60;
    final ss = _timerSec % 60;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            Gap.lg,
            0,
            Gap.lg,
            Gap.lg + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                lang == 'en' ? 'Settings' : 'Nastavení',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
              ),
            ),
            const SizedBox(height: Gap.lg),

            // ── Quick tools ──────────────────────────────────────
            _RunnerCard(
              color: Spectrum.mint,
              icon: Icons.timer_rounded,
              title: lang == 'en' ? 'Timer' : 'Časovač',
              display:
                  '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}',
              onMinus: () => _adjustTimer(-60),
              onPlus: () => _adjustTimer(60),
              minusLabel: '−1 min',
              plusLabel: '+1 min',
              onStart: () => _startTimer(context),
              startLabel: lang == 'en' ? 'Start' : 'Spustit',
            ),
            const SizedBox(height: Gap.sm),
            _RunnerCard(
              color: Spectrum.amber,
              icon: Icons.pin_rounded,
              title: lang == 'en' ? 'Countdown' : 'Odpočet',
              display: '$_countdownN',
              onMinus: () => _adjustCountdown(-1),
              onPlus: () => _adjustCountdown(1),
              minusLabel: '−1',
              plusLabel: '+1',
              onStart: () => _startCountdown(context),
              startLabel: lang == 'en' ? 'Start' : 'Spustit',
            ),
            const SizedBox(height: Gap.lg),

            // ── Timer display ────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'TIMER DISPLAY' : 'ZOBRAZENÍ ČASU'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'en'
                          ? 'Show remaining time as'
                          : 'Zobrazit zbývající čas jako',
                      style: const TextStyle(
                          fontSize: 13, color: Spectrum.inkSoft),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleChip(
                            label: '2:30',
                            sublabel: lang == 'en' ? 'min:sec' : 'min:sek',
                            color: Spectrum.mint,
                            selected: _timerDisplayMinSec,
                            onTap: () {
                              setState(() => _timerDisplayMinSec = true);
                              Prefs.setTimerDisplayMinSec(true);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ToggleChip(
                            label: '150',
                            sublabel: lang == 'en' ? 'seconds' : 'sekundy',
                            color: Spectrum.sky,
                            selected: !_timerDisplayMinSec,
                            onTap: () {
                              setState(() => _timerDisplayMinSec = false);
                              Prefs.setTimerDisplayMinSec(false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),

            // ── Language ─────────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'LANGUAGE' : 'JAZYK'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: AnimatedBuilder(
                  animation: LangStore.instance,
                  builder: (context, _) {
                    final cur = LangStore.instance.lang;
                    return Row(
                      children: [
                        Expanded(
                          child: _LangChip(
                            flag: '🇨🇿',
                            label: 'Čeština',
                            selected: cur == 'cs',
                            onTap: () {
                              LangStore.instance.setLang('cs');
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LangChip(
                            flag: '🇬🇧',
                            label: 'English',
                            selected: cur == 'en',
                            onTap: () {
                              LangStore.instance.setLang('en');
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),

            // ── Child ────────────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'CHILD' : 'DÍTĚ'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'en'
                          ? 'Name for celebrations (vocative)'
                          : 'Jak oslovit dítě? (5. pád)',
                      style: const TextStyle(
                          fontSize: 13, color: Spectrum.inkSoft),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _vocativeCtrl,
                      onChanged: (v) => Prefs.setKidVocative(v.trim()),
                      decoration: InputDecoration(
                        hintText: lang == 'en'
                            ? 'e.g. Tommy, Anna…'
                            : 'např. Tomáši, Anno, Kubíčku…',
                        hintStyle:
                            const TextStyle(color: Spectrum.inkSoft),
                        filled: true,
                        fillColor: Spectrum.bg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          borderSide: BorderSide(
                              color:
                                  Spectrum.inkSoft.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          borderSide: BorderSide(
                              color:
                                  Spectrum.inkSoft.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          borderSide: const BorderSide(
                              color: Spectrum.sky, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),

            // ── Data ─────────────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'DATA' : 'DATA'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.upload_rounded,
                    color: Spectrum.mint,
                    title: lang == 'en' ? 'Export backup' : 'Exportovat zálohu',
                    subtitle: lang == 'en'
                        ? 'Share all your challenges as JSON'
                        : 'Sdílet vlastní výzvy jako JSON',
                    loading: _exporting,
                    onTap: () => _doExport(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ActionRow(
                    icon: Icons.download_rounded,
                    color: Spectrum.amber,
                    title: lang == 'en' ? 'Restore backup' : 'Obnovit zálohu',
                    subtitle: lang == 'en'
                        ? 'Import challenges from a JSON file'
                        : 'Importovat výzvy ze souboru JSON',
                    loading: _importing,
                    onTap: () => _doImport(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),

            // ── Help & About ─────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'INFO' : 'INFO'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  _HowItWorksRow(lang: lang),
                  const Divider(height: 1, indent: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.md, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Spectrum.lavender.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              size: 20, color: Spectrum.lavender),
                        ),
                        const SizedBox(width: Gap.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang == 'en' ? 'About Spectroom' : 'O aplikaci',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const Text(
                                'v0.6 · Mulberry Symbols (CC BY-SA 4.0)',
                                style: TextStyle(
                                    fontSize: 11, color: Spectrum.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
          ],
        ),
      ),
    );
  }
}

// ── Runner card (timer / countdown) ─────────────────────────

class _RunnerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String display;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String minusLabel;
  final String plusLabel;
  final VoidCallback onStart;
  final String startLabel;

  const _RunnerCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.display,
    required this.onMinus,
    required this.onPlus,
    required this.minusLabel,
    required this.plusLabel,
    required this.onStart,
    required this.startLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tint = Spectrum.tint(color, 0.84);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Spectrum.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Header stripe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.md, vertical: Gap.sm),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Radii.lg)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Gap.md, Gap.md, Gap.md, Gap.md),
            child: Column(
              children: [
                // Big display
                Text(
                  display,
                  style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -2,
                      color: color,
                      fontFamily: 'Geist'),
                ),
                const SizedBox(height: Gap.sm),
                // − / + row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AdjustBtn(
                        label: minusLabel,
                        color: color,
                        onTap: onMinus),
                    const SizedBox(width: Gap.md),
                    _AdjustBtn(
                        label: plusLabel,
                        color: color,
                        onTap: onPlus),
                  ],
                ),
                const SizedBox(height: Gap.md),
                // Start button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(startLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AdjustBtn(
      {required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.md, vertical: Gap.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color)),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: Spectrum.inkSoft),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Spectrum.inkSoft),
      );
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Spectrum.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
              color: Spectrum.ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: child,
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Spectrum.bg,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: selected ? color : Spectrum.inkSoft.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: selected ? color : Spectrum.inkSoft)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Spectrum.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color))
                  : Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Spectrum.inkSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: Spectrum.inkSoft.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatefulWidget {
  final String lang;
  const _HowItWorksRow({required this.lang});

  @override
  State<_HowItWorksRow> createState() => _HowItWorksRowState();
}

class _HowItWorksRowState extends State<_HowItWorksRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.lang == 'cs';
    final bullets = cs
        ? [
            'Spectroom má předpřipravené výzvy: zubaře, oblékání, stříhání nehtů i vlasů a výlet k doktorovi.',
            'Každou výzvu si lze nejdřív prohlédnout krok za krokem — bez tlaku, jen jako přípravu.',
            'V živém režimu provede dítě celou rutinou: obrázek za obrázkem, s odpočítáváním nebo časovačem.',
            'Rodiče mohou přidávat vlastní výzvy: klepněte na „+" a zadejte název, kategorii a kroky.',
            'Ke každému kroku přiřaďte obrázek — klepněte na čtvereček s ikonou fotoaparátu.',
            'Krok může být jen obrázek (informace), odpočet čísel nebo vizuální časovač.',
          ]
        : [
            'Spectroom comes with built-in challenges: dentist, getting dressed, nail clipping, haircut, and doctor visits.',
            'Any challenge can be previewed step-by-step first — no pressure, just preparation.',
            'In live mode the app guides your child picture by picture, with countdown or visual timer.',
            'Parents can create custom challenges: tap "+" and enter a name, category, and steps.',
            'For each step, assign a picture — take a photo or pick from the gallery.',
            'A step can be a plain picture card, a countdown (1, 2, 3…), or a visual timer.',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Spectrum.sky.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      size: 20, color: Spectrum.sky),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(cs ? 'Jak to funguje' : 'How it works',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: Spectrum.inkSoft.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: Spectrum.mint, shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text(b,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Spectrum.inkSoft)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? Spectrum.sky.withValues(alpha: 0.15)
              : Spectrum.bg,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: selected
                ? Spectrum.sky
                : Spectrum.inkSoft.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Spectrum.sky : Spectrum.inkSoft)),
          ],
        ),
      ),
    );
  }
}
