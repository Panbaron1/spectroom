import 'package:flutter/material.dart';

import '../data/challenge_store.dart';
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
        animation: store,
        builder: (context, _) {
          final items = store.all;
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
                          icon: const Icon(Icons.info_outline_rounded),
                          color: Spectrum.inkSoft,
                          onPressed: () => _showAbout(context),
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
                    (context, i) => _ChallengeCard(challenge: items[i]),
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
  const _ChallengeCard({required this.challenge});

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
                  challenge.titleCs,
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
            Text(c.titleCs,
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
              label: const Text('Podívat se předem'),
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
              label: const Text('Děláme to teď'),
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

void _showAbout(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Spectroom',
    applicationVersion: '0.3',
    children: const [
      SizedBox(height: 8),
      Text(
          'Klidné vizuální rutiny a sociální příběhy — pomáhají projít těžké chvíle krok za krokem.'),
      SizedBox(height: 12),
      Text('Pictograms: Mulberry Symbols (Straight Street), CC BY-SA 4.0.',
          style: TextStyle(fontSize: 12, color: Spectrum.inkSoft)),
    ],
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
