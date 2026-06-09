import 'dart:async';

import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../widgets/pictogram_view.dart';

/// Runs a challenge step by step.
///
/// Rehearsal (live=false): calm preview — swipe/Next through every step, no
/// timers fire, countdowns shown as a number. "Let's look at what happens."
///
/// Live (live=true): the real thing — countdown steps are tappable (10→1),
/// timer steps run a visual clock and auto-advance. Ends on a celebration.
class RunnerScreen extends StatefulWidget {
  final Challenge challenge;
  final bool live;
  const RunnerScreen(
      {super.key, required this.challenge, required this.live});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> {
  int _index = 0;

  bool get _atEnd => _index >= widget.challenge.steps.length;

  void _next() {
    if (_atEnd) return;
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.challenge.steps;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.titleCs),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _atEnd ? 1 : (_index + 1) / (steps.length + 1),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: _atEnd
            ? _Celebration(onDone: () => Navigator.pop(context))
            : _StepView(
                key: ValueKey('${widget.live}-$_index'),
                step: steps[_index],
                live: widget.live,
                onComplete: _next,
              ),
      ),
      bottomNavigationBar: _atEnd
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _index == 0 ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(widget.live ? 'Další' : 'Další'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(60)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StepView extends StatelessWidget {
  final ChallengeStep step;
  final bool live;
  final VoidCallback onComplete;
  const _StepView(
      {super.key,
      required this.step,
      required this.live,
      required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(step.labelCs,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold)),
        if (step.labelEn.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(step.labelEn,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.black.withValues(alpha: 0.4))),
          ),
      ],
    );

    Widget interactive;
    switch (step.kind) {
      case StepKind.info:
        interactive = PictogramView(step.pictogram, size: 200);
        break;
      case StepKind.countdown:
        interactive = live
            ? _CountdownTapper(
                start: step.count ?? 1, onDone: onComplete)
            : _CountdownPreview(count: step.count ?? 1);
        break;
      case StepKind.timer:
        interactive = live
            ? _TimerRunner(
                seconds: step.durationSec ?? 30, onDone: onComplete)
            : _TimerPreview(seconds: step.durationSec ?? 30);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: interactive)),
          const SizedBox(height: 24),
          label,
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Countdown ────────────────────────────────────────────────
class _CountdownTapper extends StatefulWidget {
  final int start;
  final VoidCallback onDone;
  const _CountdownTapper({required this.start, required this.onDone});

  @override
  State<_CountdownTapper> createState() => _CountdownTapperState();
}

class _CountdownTapperState extends State<_CountdownTapper> {
  late int _n = widget.start;

  void _tap() {
    if (_n <= 0) return;
    setState(() => _n--);
    if (_n == 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _tap,
      child: AnimatedScale(
        scale: _n > 0 ? 1 : 1.2,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _n > 0 ? '$_n' : '🎉',
            style: TextStyle(
                fontSize: _n > 0 ? 120 : 100,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _CountdownPreview extends StatelessWidget {
  final int count;
  const _CountdownPreview({required this.count});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
          color: scheme.primaryContainer, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('$count',
          style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer)),
    );
  }
}

// ── Timer ────────────────────────────────────────────────────
class _TimerRunner extends StatefulWidget {
  final int seconds;
  final VoidCallback onDone;
  const _TimerRunner({required this.seconds, required this.onDone});

  @override
  State<_TimerRunner> createState() => _TimerRunnerState();
}

class _TimerRunnerState extends State<_TimerRunner> {
  late int _remaining = widget.seconds;
  Timer? _timer;
  bool _running = false;

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onDone();
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress =
        widget.seconds == 0 ? 1.0 : _remaining / widget.seconds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              Text(_fmt(_remaining),
                  style: const TextStyle(
                      fontSize: 54, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!_running)
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
      ],
    );
  }
}

class _TimerPreview extends StatelessWidget {
  final int seconds;
  const _TimerPreview({required this.seconds});
  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60, s = seconds % 60;
    final txt = m > 0 ? '$m min${s > 0 ? ' $s s' : ''}' : '$s s';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.timer_outlined, size: 160, color: Colors.black26),
      const SizedBox(height: 12),
      Text(txt, style: const TextStyle(fontSize: 28)),
    ]);
  }
}

// ── Celebration ──────────────────────────────────────────────
class _Celebration extends StatelessWidget {
  final VoidCallback onDone;
  const _Celebration({required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 140)),
          const SizedBox(height: 16),
          const Text('Hotovo!',
              style:
                  TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('All done!',
              style: TextStyle(fontSize: 22, color: Colors.black45)),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: onDone,
            style:
                FilledButton.styleFrom(minimumSize: const Size(200, 60)),
            child: const Text('Zpět'),
          ),
        ],
      ),
    );
  }
}
