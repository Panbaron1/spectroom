import 'package:flutter/material.dart';

import '../data/challenge_store.dart';
import '../models/challenge.dart';
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
      appBar: AppBar(title: const Text('Spectroom')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBuilder(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nová'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final items = store.all;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.92,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) =>
                _ChallengeCard(challenge: items[i]),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _pickMode(context, challenge),
        onLongPress: challenge.builtIn
            ? null
            : () => _openBuilder(context, challenge),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Center(
                  child: PictogramView(challenge.cover, size: 88))),
              const SizedBox(height: 8),
              Text(
                challenge.titleCs,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                '${challenge.steps.length} kroků',
                style: TextStyle(
                    fontSize: 13, color: Colors.black.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _pickMode(BuildContext context, Challenge c) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.titleCs,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                _run(context, c, live: false);
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Podívat se předem (nácvik)'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _run(context, c, live: true);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Děláme to teď'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60)),
            ),
          ],
        ),
      ),
    ),
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
    MaterialPageRoute(
        builder: (_) => BuilderScreen(existing: existing)),
  );
}
