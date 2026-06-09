import 'package:flutter/material.dart';

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
      symbol: 'read',
      accent: Spectrum.lavender,
      titleCs: 'Nejdřív se podíváme',
      titleEn: 'First, let\'s look',
      bodyCs: 'V klidovém režimu si rutinu projdete dopředu. Obrázek po obrázku ukáže, co se bude dít. Žádná překvapení — to pomáhá nejvíc.',
      bodyEn: 'In preview mode, you walk through the routine ahead of time. Picture by picture shows what will happen. No surprises — that helps most.',
    ),
    _Page(
      symbol: 'clip_nails',
      accent: Spectrum.amber,
      titleCs: 'Pak to zvládneme',
      titleEn: 'Then we do it',
      bodyCs: 'V živém režimu vás appka provede krok za krokem. Odpočítávání a klidný časovač pomůžou dítěti zvládnout to skoro samo.',
      bodyEn: 'In live mode, the app guides you step by step. Countdown and calm timer help your child get through it almost on their own.',
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
                              style:
                                  const TextStyle(color: Spectrum.inkSoft)),
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
                      child: Text(_isLast
                          ? (LangStore.instance.lang == 'en'
                              ? 'Start'
                              : 'Začít')
                          : (LangStore.instance.lang == 'en' ? 'Next' : 'Dál')),
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Spectrum.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Spectrum.sky.withValues(alpha: 0.28),
                    blurRadius: 48,
                    offset: const Offset(0, 18)),
              ],
            ),
            child: const Center(
              child: Text('🌍', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 40),
          const Text('Vyber jazyk / Choose language',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: Spectrum.ink)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _LangButton(code: 'cs', flag: '🇨🇿', label: 'Čeština', selected: _selected == 'cs', onTap: () => _pick('cs'))),
              const SizedBox(width: 16),
              Expanded(child: _LangButton(code: 'en', flag: '🇬🇧', label: 'English', selected: _selected == 'en', onTap: () => _pick('en'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String code, flag, label;
  final bool selected;
  final VoidCallback onTap;
  const _LangButton({required this.code, required this.flag, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? Spectrum.sky.withValues(alpha: 0.18) : Spectrum.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: selected ? Spectrum.sky : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
                color: Spectrum.ink.withValues(alpha: selected ? 0.08 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: selected ? Spectrum.sky : Spectrum.ink)),
          ],
        ),
      ),
    );
  }
}

class _Page {
  final String symbol, titleCs, titleEn, bodyCs, bodyEn;
  final Color accent;
  const _Page({
    required this.symbol,
    required this.accent,
    required this.titleCs,
    required this.titleEn,
    required this.bodyCs,
    required this.bodyEn,
  });
}

class _PageView extends StatelessWidget {
  final _Page page;
  final String lang;
  const _PageView({required this.page, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              color: Spectrum.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: page.accent.withValues(alpha: 0.28),
                    blurRadius: 48,
                    offset: const Offset(0, 18)),
              ],
            ),
            child: Center(
              child: PictogramView(PictogramRef.asset(page.symbol), size: 108),
            ),
          ),
          const SizedBox(height: 44),
          Text(lang == 'en' ? page.titleEn : page.titleCs,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Spectrum.ink)),
          const SizedBox(height: 16),
          Text(lang == 'en' ? page.bodyEn : page.bodyCs,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16.5, height: 1.55, color: Spectrum.inkSoft)),
        ],
      ),
    );
  }
}
