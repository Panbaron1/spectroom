import 'package:flutter/material.dart';

import '../data/prefs.dart';
import '../design/spectrum.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';
import '../widgets/spectrum_mesh.dart';
import 'home_screen.dart';

/// First-launch intro: what Spectroom is and how the two modes work.
/// Shown once (persisted via Prefs), then never again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = <_Page>[
    _Page(
      symbol: 'star',
      accent: Spectrum.mint,
      title: 'Vítej ve Spectroom',
      body:
          'Klidné vizuální rutiny, které pomáhají dítěti zvládnout těžké chvíle — stříhání nehtů, zubaře, oblékání — krok za krokem, s obrázky.',
    ),
    _Page(
      symbol: 'read',
      accent: Spectrum.lavender,
      title: 'Nejdřív se podíváme',
      body:
          'V klidovém režimu si rutinu projdete dopředu. Obrázek po obrázku ukáže, co se bude dít. Žádná překvapení — to pomáhá nejvíc.',
    ),
    _Page(
      symbol: 'clip_nails',
      accent: Spectrum.amber,
      title: 'Pak to zvládneme',
      body:
          'V živém režimu vás appka provede krok za krokem. Odpočítávání a klidný časovač pomůžou dítěti zvládnout to skoro samo.',
    ),
  ];

  Future<void> _finish() async {
    await Prefs.setSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _nextOrFinish() {
    if (_page < _pages.length - 1) {
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

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SpectrumMesh(intensity: 0.55)),
          SafeArea(
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
                  TextButton(
                    onPressed: _finish,
                    child: Text(last ? '' : 'Přeskočit',
                        style: const TextStyle(color: Spectrum.inkSoft)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? _pages[_page].accent
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
                      backgroundColor: _pages[_page].accent,
                      minimumSize: const Size.fromHeight(60)),
                  child: Text(last ? 'Začít' : 'Dál'),
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

class _Page {
  final String symbol, title, body;
  final Color accent;
  const _Page(
      {required this.symbol,
      required this.title,
      required this.body,
      required this.accent});
}

class _PageView extends StatelessWidget {
  final _Page page;
  const _PageView({required this.page});

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
              child: PictogramView(
                  PictogramRef.mulberry(page.symbol), size: 108),
            ),
          ),
          const SizedBox(height: 44),
          Text(page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Spectrum.ink)),
          const SizedBox(height: 16),
          Text(page.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16.5, height: 1.55, color: Spectrum.inkSoft)),
        ],
      ),
    );
  }
}
