import 'package:flutter/material.dart';

import '../data/challenge_store.dart';
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
        backgroundColor: Palette.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nová výzva',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final items = store.all;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Palette.bg,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 116,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    onPressed: () => _showAbout(context),
                  ),
                ],
                flexibleSpace: const FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 20, bottom: 14),
                  title: Text('Spectroom',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: Palette.ink)),
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(28),
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 10, right: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Klidně si projdi, co nás čeká.',
                          style:
                              TextStyle(color: Palette.inkSoft, fontSize: 15)),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.86,
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
    final accent = Palette.of(challenge.category);
    final tint = Palette.tintOf(challenge.category);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _pickMode(context, challenge),
        onLongPress:
            challenge.builtIn ? null : () => _openBuilder(context, challenge),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: PictogramTile(challenge.cover, size: 110, tint: tint),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                challenge.titleCs,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('${challenge.steps.length} kroků',
                      style:
                          const TextStyle(fontSize: 13, color: Palette.inkSoft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _pickMode(BuildContext context, Challenge c) {
  final accent = Palette.of(c.category);
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PictogramTile(c.cover, size: 76, tint: Palette.tintOf(c.category)),
            const SizedBox(height: 12),
            Text(c.titleCs,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                _run(context, c, live: false);
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Podívat se předem'),
              style: FilledButton.styleFrom(
                  backgroundColor: Palette.tintOf(c.category),
                  foregroundColor: Palette.ink,
                  minimumSize: const Size.fromHeight(60)),
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
                  minimumSize: const Size.fromHeight(60)),
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
    applicationVersion: '0.1',
    children: const [
      SizedBox(height: 8),
      Text(
          'Klidné vizuální rutiny a sociální příběhy — pomáhají projít těžké chvíle krok za krokem.'),
      SizedBox(height: 12),
      Text('Pictograms: Mulberry Symbols (Straight Street), CC BY-SA 4.0.',
          style: TextStyle(fontSize: 12, color: Palette.inkSoft)),
    ],
  );
}

void _run(BuildContext context, Challenge c, {required bool live}) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => RunnerScreen(challenge: c, live: live)),
  );
}

void _openBuilder(BuildContext context, Challenge? existing) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BuilderScreen(existing: existing)),
  );
}
