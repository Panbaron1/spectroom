import 'package:flutter/material.dart';

import '../data/prefs.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';
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
      tint: Palette.tealTint,
      accent: Palette.teal,
      title: 'Vítej ve Spectroom',
      body:
          'Klidné vizuální rutiny, které pomáhají dítěti zvládnout těžké chvíle — stříhání nehtů, zubaře, oblékání — krok za krokem, s obrázky.',
    ),
    _Page(
      symbol: 'read',
      tint: Palette.lavenderTint,
      accent: Palette.lavender,
      title: 'Nejdřív se podíváme',
      body:
          'V klidovém režimu si rutinu projdete dopředu. Obrázek po obrázku ukáže, co se bude dít. Žádná překvapení — to pomáhá nejvíc.',
    ),
    _Page(
      symbol: 'clip_nails',
      tint: Palette.peachTint,
      accent: Palette.peach,
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
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(last ? '' : 'Přeskočit',
                    style: const TextStyle(color: Palette.inkSoft)),
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
    );
  }
}

class _Page {
  final String symbol, title, body;
  final Color tint, accent;
  const _Page(
      {required this.symbol,
      required this.title,
      required this.body,
      required this.tint,
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
          PictogramTile(PictogramRef.mulberry(page.symbol),
              size: 180, tint: page.tint),
          const SizedBox(height: 40),
          Text(page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w800, color: Palette.ink)),
          const SizedBox(height: 16),
          Text(page.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17, height: 1.5, color: Palette.inkSoft)),
        ],
      ),
    );
  }
}
