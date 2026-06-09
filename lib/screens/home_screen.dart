import 'package:flutter/material.dart';

import '../data/challenge_store.dart';
import '../data/lang_store.dart';
import '../data/prefs.dart';
import '../design/spectrum.dart';
import '../models/challenge.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';
import 'builder_screen.dart';
import 'runner_screen.dart';

/// Library of challenges. Tap a card → pick Rehearsal or Live. FAB → build your
/// own. Long-press a parent-made card → edit/delete.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ChallengeStore.instance;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBuilder(context, null),
        backgroundColor: Spectrum.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nová výzva',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([store, LangStore.instance]),
        builder: (context, _) {
          final items = store.all;
          final lang = LangStore.instance.lang;
          return CustomScrollView(
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
                              const Text('Klidně si projdi, co nás čeká.',
                                  style: TextStyle(
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, 110),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: Gap.md,
                    crossAxisSpacing: Gap.md,
                    childAspectRatio: 0.84,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ChallengeCard(challenge: items[i], lang: lang),
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final String lang;
  const _ChallengeCard({required this.challenge, required this.lang});

  @override
  Widget build(BuildContext context) {
    final accent = Spectrum.accent(challenge.category);
    final tint = Spectrum.accentTint(challenge.category);
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
                const SizedBox(height: 12),
                Text(
                  challenge.title(lang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${challenge.steps.length} kroků',
                        style: const TextStyle(
                            fontSize: 13, color: Spectrum.inkSoft)),
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
  late final TextEditingController _nameCtrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    Prefs.kidName().then((n) {
      if (mounted) setState(() { _nameCtrl.text = n; _loaded = true; });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _lang => LangStore.instance.lang;

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }
    return SafeArea(
      child: Padding(
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
                _lang == 'en' ? 'Settings' : 'Nastavení',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
              ),
            ),
            const SizedBox(height: Gap.lg),
            _SheetLabel(_lang == 'en' ? "Child's name" : 'Jméno dítěte'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: _lang == 'en' ? 'E.g. Tom' : 'Např. Tomáš',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.sm)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  borderSide: const BorderSide(
                      color: Spectrum.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  borderSide: BorderSide(
                      color: Spectrum.inkSoft.withValues(alpha: 0.3)),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_rounded),
                  onPressed: () =>
                      Prefs.setKidName(_nameCtrl.text),
                ),
              ),
              onSubmitted: Prefs.setKidName,
            ),
            const SizedBox(height: Gap.lg),
            _SheetLabel(_lang == 'en' ? 'Language' : 'Jazyk'),
            const SizedBox(height: 8),
            AnimatedBuilder(
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
            const SizedBox(height: Gap.md),
            const Divider(),
            _HowItWorksSection(lang: _lang),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline_rounded,
                  color: Spectrum.inkSoft),
              title: Text(
                  _lang == 'en' ? 'About Spectroom' : 'O aplikaci'),
              subtitle: const Text(
                  'v0.4 · Pictograms: Mulberry Symbols (CC BY-SA 4.0)',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
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

class _HowItWorksSection extends StatefulWidget {
  final String lang;
  const _HowItWorksSection({required this.lang});

  @override
  State<_HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<_HowItWorksSection> {
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
            'Ke každému kroku přiřaďte obrázek — klepněte na čtvereček s ikonou fotoaparátu. Fotku lze vyfotit přímo nebo vybrat z galerie.',
            'Krok může být jen obrázek (informace), odpočet čísel (1, 2, 3…) nebo vizuální časovač.',
          ]
        : [
            'Spectroom comes with built-in challenges: dentist, getting dressed, nail clipping, haircut, and a doctor visit.',
            'Any challenge can be previewed step-by-step first — no pressure, just preparation.',
            'In live mode the app guides your child picture by picture, with countdown or visual timer.',
            'Parents can create custom challenges: tap "+" and enter a name, category, and steps.',
            'For each step, assign a picture — tap the tile with the camera icon to take a photo or pick from the gallery.',
            'A step can be a plain picture card, a countdown (1, 2, 3…), or a visual timer.',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.help_outline_rounded,
              color: Spectrum.inkSoft),
          title:
              Text(cs ? 'Jak to funguje' : 'How it works'),
          trailing: Icon(
            _expanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            color: Spectrum.inkSoft,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(0, 0, 0, Gap.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map((b) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  top: 6, right: 8),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: Spectrum.mint,
                                  shape: BoxShape.circle),
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
