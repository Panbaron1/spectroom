import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/lang_store.dart';
import '../data/prefs.dart';
import '../design/spectrum.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';
import '../widgets/spectrum_mesh.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  // page 0 = language picker; pages 1-3 = intro pages
  static const _introPages = <_Page>[
    _Page(
      symbol: 'star',
      accent: Spectrum.mint,
      titleCs: 'Vítej ve Spectroom',
      titleEn: 'Welcome to Spectroom',
      bodyCs: 'Klidné vizuální rutiny, které pomáhají dítěti zvládnout těžké chvíle — stříhání nehtů, zubaře, oblékání — krok za krokem, s obrázky.',
      bodyEn: 'Calm visual routines that help your child through hard moments — nail clipping, dentist, getting dressed — step by step, with pictures.',
    ),
    _Page(
      symbol: 'magnifying_glass',
      accent: Spectrum.lavender,
      titleCs: 'Nejdřív se podíváme',
      titleEn: 'Preview first',
      bodyCs: 'V klidovém režimu si rutinu projdete dopředu. Obrázek po obrázku ukáže, co se bude dít. Žádná překvapení — to pomáhá nejvíc.',
      bodyEn: 'Walk through the routine ahead of time. Picture by picture shows exactly what will happen. No surprises — that helps most.',
    ),
    _Page(
      symbol: 'clip_nails',
      accent: Spectrum.amber,
      titleCs: 'Pak to zvládneme',
      titleEn: 'Then we do it',
      bodyCs: 'V živém režimu vás appka provede krok za krokem. Odpočítávání a klidný časovač pomůžou dítěti zvládnout to skoro samo.',
      bodyEn: 'In live mode the app guides you step by step. Countdown and calm timer help your child get through it almost on their own.',
    ),
    _Page(
      symbol: 'star',
      accent: Spectrum.sky,
      titleCs: 'Tipy navíc',
      titleEn: 'Pro tips',
      tipsCs: [
        'Předpřipravené výzvy lze upravit — podržte prst na kartě výzvy a otevře se editor. Přizpůsobte je svému dítěti.',
        'Do přípravných kroků přidejte fotku dítěte (klidně i AI obrázek), jak je klidné a spokojené v dané situaci. Když se vidí, jak to zvládá, příprava má největší efekt.',
      ],
      tipsEn: [
        'Built-in challenges can be edited — long-press a challenge card to open the editor and tailor it to your child.',
        'In training steps, add a photo of your child (an AI-generated one works too) looking calm and happy in the hard situation. When they see themselves cope, the preparation has the greatest effect.',
      ],
    ),
  ];

  Future<void> _finish() async {
    await Prefs.setSeen();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _nextOrFinish() {
    if (_page < _introPages.length) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _accent => _page == 0
      ? Spectrum.sky
      : _introPages[_page - 1].accent;

  bool get _isLast => _page == _introPages.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SpectrumMesh(intensity: 0.55)),
          SafeArea(
            child: ContentBox(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => Spectrum.brand.createShader(r),
                          child: const Text('Spectroom',
                              style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: Colors.white)),
                        ),
                        if (_page > 0)
                          TextButton(
                            onPressed: _isLast ? null : _finish,
                            child: Text(_isLast ? '' : 'Přeskočit / Skip',
                                style: const TextStyle(color: Spectrum.inkSoft)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _ctrl,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _page = i),
                      itemCount: _introPages.length + 1,
                      itemBuilder: (_, i) => i == 0
                          ? _LangPickerPage(onPicked: () => setState(() {}))
                          : _PageView(
                              page: _introPages[i - 1],
                              lang: LangStore.instance.lang,
                            ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_introPages.length + 1, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _accent
                              : Palette.inkSoft.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _nextOrFinish,
                        style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            minimumSize: const Size.fromHeight(60)),
                        child: Text(
                          _isLast
                              ? (LangStore.instance.lang == 'en' ? 'Start' : 'Začít')
                              : (LangStore.instance.lang == 'en' ? 'Next' : 'Dál'),
                          style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language picker ──────────────────────────────────────────

class _LangPickerPage extends StatefulWidget {
  final VoidCallback onPicked;
  const _LangPickerPage({required this.onPicked});

  @override
  State<_LangPickerPage> createState() => _LangPickerPageState();
}

class _LangPickerPageState extends State<_LangPickerPage> {
  String _selected = LangStore.instance.lang;

  Future<void> _pick(String lang) async {
    await LangStore.instance.setLang(lang);
    setState(() => _selected = lang);
    widget.onPicked();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spectroom spectrum wordmark as hero
          ShaderMask(
            shaderCallback: (r) => Spectrum.brand.createShader(r),
            child: const Text(
              'Spectroom',
              style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  color: Colors.white),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0),
          const SizedBox(height: 8),
          const Text(
            'Vyber jazyk · Choose language',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Spectrum.inkSoft,
                letterSpacing: 0.1),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 44),
          _LangTile(
            code: 'cs',
            label: 'Čeština',
            sublabel: 'Česky',
            accent: Spectrum.coral,
            selected: _selected == 'cs',
            onTap: () => _pick('cs'),
          ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideX(begin: -0.08, end: 0),
          const SizedBox(height: 14),
          _LangTile(
            code: 'en',
            label: 'English',
            sublabel: 'In English',
            accent: Spectrum.sky,
            selected: _selected == 'en',
            onTap: () => _pick('en'),
          ).animate().fadeIn(delay: 350.ms, duration: 350.ms).slideX(begin: 0.08, end: 0),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String code, label, sublabel;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Spectrum.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: selected ? accent : Spectrum.inkSoft.withValues(alpha: 0.15),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: 0.18)
                  : Spectrum.ink.withValues(alpha: 0.05),
              blurRadius: selected ? 28 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color swatch / code badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? accent : accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: selected ? Colors.white : accent,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: selected ? accent : Spectrum.ink)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Spectrum.inkSoft)),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1.0 : 0.0,
              child: Icon(Icons.check_circle_rounded,
                  color: accent, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Intro page ───────────────────────────────────────────────

class _Page {
  final String symbol, titleCs, titleEn;
  final String? bodyCs, bodyEn;
  final List<String>? tipsCs, tipsEn;
  final Color accent;
  const _Page({
    required this.symbol,
    required this.accent,
    required this.titleCs,
    required this.titleEn,
    this.bodyCs,
    this.bodyEn,
    this.tipsCs,
    this.tipsEn,
  });
}

class _PageView extends StatelessWidget {
  final _Page page;
  final String lang;
  const _PageView({required this.page, required this.lang});

  @override
  Widget build(BuildContext context) {
    final tips = lang == 'en' ? page.tipsEn : page.tipsCs;
    final hasTips = tips != null;
    final heroSize = hasTips ? 132.0 : 200.0;
    final pictoSize = hasTips ? 76.0 : 116.0;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Container(
            width: heroSize,
            height: heroSize,
            decoration: BoxDecoration(
              color: Spectrum.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: page.accent.withValues(alpha: 0.32),
                    blurRadius: 56,
                    offset: const Offset(0, 20)),
              ],
            ),
            child: Center(
              child: PictogramView(PictogramRef.asset(page.symbol), size: pictoSize),
            ),
          ).animate().scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 450.ms,
              curve: Curves.easeOutBack),
          SizedBox(height: hasTips ? 28 : 48),
          Text(lang == 'en' ? page.titleEn : page.titleCs,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Spectrum.ink))
              .animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          if (hasTips)
            ...List.generate(tips.length, (i) => Padding(
                  padding: EdgeInsets.only(bottom: i == tips.length - 1 ? 0 : 14),
                  child: _TipCard(
                    number: i + 1,
                    text: tips[i],
                    accent: page.accent,
                  ).animate().fadeIn(
                      delay: (180 + i * 140).ms, duration: 350.ms)
                      .slideY(begin: 0.12, end: 0),
                ))
          else
            Text(lang == 'en' ? page.bodyEn! : page.bodyCs!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16.5, height: 1.6, color: Spectrum.inkSoft))
                .animate().fadeIn(delay: 200.ms, duration: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final int number;
  final String text;
  final Color accent;
  const _TipCard(
      {required this.number, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Spectrum.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
              color: Spectrum.ink.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$number',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.5, color: Spectrum.inkSoft)),
          ),
        ],
      ),
    );
  }
}
