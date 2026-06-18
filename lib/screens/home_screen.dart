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
import '../widgets/pin_dialog.dart';
import 'builder_screen.dart';
import 'runner_screen.dart';
import 'schedule_screen.dart';

/// Library of challenges. Tap a card → pick Rehearsal or Live. FAB → build your
/// own. Long-press any card → edit (built-in or custom).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-decode all seed cover icons so first-scroll has no decode stutter.
    for (final c in ChallengeStore.instance.all) {
      final ref = c.cover;
      if (ref.kind == PictogramKind.asset) {
        precacheImage(
          AssetImage('assets/icons/${ref.value}.png'),
          context,
        );
      }
    }
  }

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
            cacheExtent: 900,
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
                          icon: const Icon(Icons.notifications_rounded),
                          color: Spectrum.inkSoft,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScheduleScreen()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline_rounded),
                          color: Spectrum.inkSoft,
                          onPressed: () => _showHelp(context),
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
              color: Spectrum.ink.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: () => _pickMode(context, challenge),
          onLongPress: () => _openBuilder(context, challenge),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = (constraints.maxWidth * 0.62).clamp(80.0, 180.0);
                        return PictogramTile(challenge.cover, size: size, tint: tint);
                      },
                    ),
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
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
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

void _showHelp(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Spectrum.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Radii.lg))),
    builder: (_) => AnimatedBuilder(
      animation: LangStore.instance,
      builder: (_, _) => _HelpSheet(lang: LangStore.instance.lang),
    ),
  );
}

void _run(BuildContext context, Challenge c, {required bool live}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => RunnerScreen(challenge: c, live: live)),
  );
}

Future<void> _openBuilder(BuildContext context, Challenge? existing) async {
  final pin = await Prefs.builderPin();
  if (pin != null) {
    if (!context.mounted) return;
    final ok = await showPinAuth(context, pin);
    if (!ok) return;
  }
  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuilderScreen(existing: existing)),
    );
  }
}

// ── Settings bottom sheet ────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _timerDisplayMinSec = true;
  bool _loaded = false;
  bool _exporting = false;
  bool _importing = false;
  String? _builderPin;
  late final TextEditingController _vocativeCtrl;

  @override
  void initState() {
    super.initState();
    _vocativeCtrl = TextEditingController();
    Future.wait([
      Prefs.kidVocative(),
      Prefs.timerDisplayMinSec(),
      Prefs.builderPin(),
    ]).then((vals) {
      if (mounted) {
        setState(() {
          _vocativeCtrl.text = vals[0] as String;
          _timerDisplayMinSec = vals[1] as bool;
          _builderPin = vals[2] as String?;
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

  Future<void> _setPin(BuildContext ctx) async {
    final newPin = await showPinSetup(ctx);
    if (newPin == null) return;
    await Prefs.setBuilderPin(newPin);
    if (mounted) setState(() => _builderPin = newPin);
  }

  Future<void> _removePin(BuildContext ctx) async {
    // Ask the current PIN before removing
    if (_builderPin != null) {
      final ok = await showPinAuth(ctx, _builderPin!);
      if (!ok) return;
    }
    await Prefs.setBuilderPin(null);
    if (mounted) setState(() => _builderPin = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }
    final lang = _lang;
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

            // ── Language ─────────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'LANGUAGE' : 'JAZYK'),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: LangStore.instance,
              builder: (context, _) {
                final cur = LangStore.instance.lang;
                return Column(
                  children: [
                    _SettingsLangTile(
                      code: 'CS',
                      label: 'Čeština',
                      sublabel: 'Česky',
                      accent: Spectrum.coral,
                      selected: cur == 'cs',
                      onTap: () {
                        LangStore.instance.setLang('cs');
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _SettingsLangTile(
                      code: 'EN',
                      label: 'English',
                      sublabel: 'In English',
                      accent: Spectrum.sky,
                      selected: cur == 'en',
                      onTap: () {
                        LangStore.instance.setLang('en');
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
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

            // ── Builder lock ─────────────────────────────────────
            _SectionLabel(lang == 'en' ? 'BUILDER LOCK' : 'ZÁMEK EDITORU'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  if (_builderPin == null)
                    _ActionRow(
                      icon: Icons.lock_open_rounded,
                      color: Spectrum.coral,
                      title: lang == 'en' ? 'Set PIN' : 'Nastavit PIN',
                      subtitle: lang == 'en'
                          ? 'Protect the challenge builder with a 4-digit PIN'
                          : 'Chraňte editor výzev 4místným PINem',
                      loading: false,
                      onTap: () => _setPin(context),
                    )
                  else ...[
                    _ActionRow(
                      icon: Icons.lock_rounded,
                      color: Spectrum.coral,
                      title: lang == 'en' ? 'Change PIN' : 'Změnit PIN',
                      subtitle: lang == 'en'
                          ? 'Builder is locked — tap to set a new PIN'
                          : 'Editor je zamčený — klepněte pro nový PIN',
                      loading: false,
                      onTap: () => _setPin(context),
                    ),
                    _ActionRow(
                      icon: Icons.no_encryption_rounded,
                      color: Spectrum.inkSoft,
                      title: lang == 'en' ? 'Remove PIN' : 'Odebrat PIN',
                      subtitle: lang == 'en'
                          ? 'Unlock the builder (enter current PIN first)'
                          : 'Odemknout editor (nejprve zadejte aktuální PIN)',
                      loading: false,
                      onTap: () => _removePin(context),
                    ),
                  ],
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
                                'v1.3 · Mulberry Symbols (CC BY-SA 4.0)\nsymbols.straight-street.com',
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

class _HelpSheet extends StatelessWidget {
  final String lang;
  const _HelpSheet({required this.lang});

  @override
  Widget build(BuildContext context) {
    final cs = lang == 'cs';
    final description = cs
        ? 'Aplikace pro vizuální přípravu dětí na rutiny a nové situace.'
        : 'Visual preparation app for children facing routines and new situations.';
    final bullets = cs
        ? [
            'Obsahuje 16 předpřipravených výzev: zuby, oblékání, koupání, snídaně, spánek, hřiště, doktor, očkování, kadeřník, nehty, zklidnění, léky a další.',
            'Předpřipravené výzvy lze upravit — podržte prst na kartě výzvy a otevře se editor.',
            'Každou výzvu si lze nejdřív prohlédnout krok za krokem — bez stresu, jen jako přípravu.',
            'V živém režimu provede dítě celou rutinou obrázek za obrázkem, se zvukem a animací.',
            'Kroky mohou být: obrázková karta (informace), odpočet čísel nebo vizuální časovač s kruhovým průběhem.',
            'Ráno, před spaním nebo při zklidňování — kroky s časovačem dítěti ukáží, jak dlouho daná věc trvá.',
            'Rodiče vytvářejí vlastní výzvy klepnutím na „+" — název, kategorie, kroky s vlastními fotkami.',
            'Ke každému kroku lze nahrát hlas rodiče — dítě uslyší známý hlas přímo v aplikaci.',
            'Záloha a obnova: výzvy lze exportovat jako JSON a kdykoli obnovit.',
            'Zobrazení časovače: přepínač mezi formátem 2:30 (min:sek) nebo 150 (sekundy).',
            'Zámek editoru: editor výzev lze chránit 4místným PINem, aby ho dítě náhodou nepřepsalo.',
            'Jazyk aplikace: čeština nebo angličtina, přepínač v nastavení.',
            'Jméno dítěte (5. pád): aplikace oslovuje dítě jménem při oslavě splněné výzvy.',
            'Denní připomínky: nastavte čas, vyberte výzvu a aplikace vám každý den pošle upozornění — ikona zvonku v hlavní obrazovce.',
          ]
        : [
            'Includes 16 built-in challenges: teeth, getting dressed, bath, breakfast, bedtime, playground, doctor, vaccination, haircut, nails, calm-down, medicine, and more.',
            'Built-in challenges can be edited — long-press a challenge card to open the editor.',
            'Any challenge can be previewed step-by-step first — no pressure, just calm preparation.',
            'In live mode the app guides your child picture by picture, with sound and animation.',
            'Steps can be: picture card (information), number countdown, or a visual timer with circular progress.',
            'Morning routine, bedtime, or calming down — timer steps show the child exactly how long something takes.',
            'Parents create custom challenges with the "+" button — name, category, steps with your own photos.',
            'Record your voice for any step — your child hears your voice playing directly in the app.',
            'Backup & restore: export all challenges as JSON and import them back anytime.',
            'Timer display: toggle between 2:30 (min:sec) format or plain seconds (150).',
            'Builder lock: protect the challenge editor with a 4-digit PIN so the child can\'t accidentally edit.',
            'Language: Czech or English, switchable in settings.',
            'Child\'s name: the app addresses your child by name when celebrating a completed challenge.',
            'Daily reminders: set a time, pick a challenge, and the app sends a notification every day — bell icon in the home screen.',
          ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                cs ? 'Jak to funguje' : 'How it works',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(description,
                style: const TextStyle(
                    fontSize: 14, height: 1.4, color: Spectrum.inkSoft)),
            const SizedBox(height: Gap.lg),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: Spectrum.mint, shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text(b,
                            style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: Spectrum.inkSoft)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SettingsLangTile extends StatelessWidget {
  final String code, label, sublabel;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsLangTile({
    required this.code,
    required this.label,
    required this.sublabel,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : Spectrum.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: selected ? accent : Spectrum.inkSoft.withValues(alpha: 0.15),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: 0.14)
                  : Spectrum.ink.withValues(alpha: 0.04),
              blurRadius: selected ? 20 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? accent : accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: selected ? Colors.white : accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: selected ? accent : Spectrum.ink)),
                  const SizedBox(height: 1),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 12, color: Spectrum.inkSoft)),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1.0 : 0.0,
              child: Icon(Icons.check_circle_rounded, color: accent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
