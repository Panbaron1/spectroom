import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/spectrum.dart';
import '../models/challenge.dart';
import '../models/pictogram_ref.dart';
import '../theme.dart';
import '../widgets/pictogram_view.dart';

/// Runs a challenge step by step.
///
/// Rehearsal (live=false): calm preview — Next through every step, no timers
/// fire, countdowns shown as a number. "Let's look at what happens."
///
/// Live (live=true): the real thing — countdown steps are tappable (10→1),
/// timer steps run a smooth visual ring and auto-advance. Ends on celebration.
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

  Color get _accent => Palette.of(widget.challenge.category);
  Color get _tint => Palette.tintOf(widget.challenge.category);
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
      backgroundColor:
          Color.alphaBlend(_tint.withValues(alpha: 0.55), Spectrum.bg),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.challenge.titleCs),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Soft step progress as a row of dots
            if (!_atEnd)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: _DotProgress(
                    total: steps.length, current: _index, color: _accent),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _atEnd
                    ? _Celebration(
                        key: const ValueKey('end'),
                        accent: _accent,
                        onDone: () => Navigator.pop(context))
                    : _StepView(
                        key: ValueKey('${widget.live}-$_index'),
                        step: steps[_index],
                        live: widget.live,
                        accent: _accent,
                        onComplete: _next,
                      ),
              ),
            ),
            if (!_atEnd)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _index == 0 ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      iconSize: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            minimumSize: const Size.fromHeight(60)),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Další'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DotProgress extends StatelessWidget {
  final int total, current;
  final Color color;
  const _DotProgress(
      {required this.total, required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 26 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _StepView extends StatelessWidget {
  final ChallengeStep step;
  final bool live;
  final Color accent;
  final VoidCallback onComplete;
  const _StepView(
      {super.key,
      required this.step,
      required this.live,
      required this.accent,
      required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(step.labelCs,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Palette.ink)),
        if (step.labelEn.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(step.labelEn,
                style: const TextStyle(fontSize: 18, color: Palette.inkSoft)),
          ),
      ],
    );

    Widget hero;
    switch (step.kind) {
      case StepKind.info:
        hero = _PictoHero(ref: step.pictogram);
        break;
      case StepKind.countdown:
        hero = live
            ? _CountdownTapper(
                start: step.count ?? 1, accent: accent, onDone: onComplete)
            : _CountdownPreview(count: step.count ?? 1, accent: accent);
        break;
      case StepKind.timer:
        hero = live
            ? _TimerRunner(
                seconds: step.durationSec ?? 30,
                accent: accent,
                onDone: onComplete)
            : _TimerPreview(seconds: step.durationSec ?? 30, accent: accent);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: hero)),
          const SizedBox(height: 24),
          label,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PictoHero extends StatelessWidget {
  final PictogramRef ref;
  const _PictoHero({required this.ref});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: PictogramView(ref, size: 200),
    );
  }
}

// ── Countdown ────────────────────────────────────────────────
class _CountdownTapper extends StatefulWidget {
  final int start;
  final Color accent;
  final VoidCallback onDone;
  const _CountdownTapper(
      {required this.start, required this.accent, required this.onDone});

  @override
  State<_CountdownTapper> createState() => _CountdownTapperState();
}

class _CountdownTapperState extends State<_CountdownTapper>
    with SingleTickerProviderStateMixin {
  late int _n = widget.start;
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));

  void _tap() {
    if (_n <= 0) return;
    setState(() => _n--);
    _pop.forward(from: 0);
    if (_n == 0) {
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _tap,
          child: AnimatedBuilder(
            animation: _pop,
            builder: (context, child) {
              final s = 1 + 0.12 * math.sin(_pop.value * math.pi);
              return Transform.scale(scale: s, child: child);
            },
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.accent.withValues(alpha: 0.85),
                    widget.accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: widget.accent.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                child: Text(
                  _n > 0 ? '$_n' : '★',
                  key: ValueKey(_n),
                  style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _Pips(total: widget.start, remaining: _n, color: widget.accent),
        const SizedBox(height: 8),
        Text('Klepni na kruh', style: TextStyle(color: Palette.inkSoft, fontSize: 15)),
      ],
    );
  }
}

class _Pips extends StatelessWidget {
  final int total, remaining;
  final Color color;
  const _Pips(
      {required this.total, required this.remaining, required this.color});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(total, (i) {
        final done = i >= remaining; // counted-down ones fill
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: done ? color : color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _CountdownPreview extends StatelessWidget {
  final int count;
  final Color accent;
  const _CountdownPreview({required this.count, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.85), accent]),
      ),
      alignment: Alignment.center,
      child: Text('$count',
          style: const TextStyle(
              fontSize: 120, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

// ── Timer (the calming animated ring) ────────────────────────
class _TimerRunner extends StatefulWidget {
  final int seconds;
  final Color accent;
  final VoidCallback onDone;
  const _TimerRunner(
      {required this.seconds, required this.accent, required this.onDone});

  @override
  State<_TimerRunner> createState() => _TimerRunnerState();
}

class _TimerRunnerState extends State<_TimerRunner>
    with TickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: Duration(seconds: widget.seconds));
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat(reverse: true);
  bool _running = false;

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _ring.forward();
    _ring.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onDone();
        });
      }
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    _breath.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_ring, _breath]),
          builder: (context, _) {
            final remaining = _running ? (1 - _ring.value) : 1.0; // 1 → 0
            final secsLeft = (widget.seconds * remaining).ceil();
            final breathe = _running
                ? 1 + 0.015 * math.sin(_breath.value * math.pi * 2)
                : 1.0;
            final rotation = _running ? _ring.value * 0.6 : 0.0;
            return Transform.scale(
              scale: breathe,
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // soft spectrum glow that fades as time drains
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          Spectrum.mint
                              .withValues(alpha: 0.16 * remaining + 0.04),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(280, 280),
                      painter: _SpectrumRingPainter(
                          progress: remaining, rotation: rotation),
                    ),
                    Text(
                      _running ? _fmt(secsLeft) : _fmt(widget.seconds),
                      style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1.5,
                          color: Spectrum.ink),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        if (!_running)
          FilledButton.icon(
            onPressed: _start,
            style: FilledButton.styleFrom(
                backgroundColor: Spectrum.ink,
                minimumSize: const Size(180, 56)),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start'),
          ),
      ],
    );
  }
}

/// The signature: a ring painted with the full Spectroom spectrum. The arc is
/// the time remaining — as it drains, the spectrum recedes. Slow rotation keeps
/// it alive and calm.
class _SpectrumRingPainter extends CustomPainter {
  final double progress; // 1 → 0
  final double rotation;
  _SpectrumRingPainter({required this.progress, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 16;
    const stroke = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // faint neutral track
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Spectrum.ink.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);

    final start = -math.pi / 2 + rotation;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0.001) return;
    final arc = Paint()
      ..shader = SweepGradient(
        colors: Spectrum.sweep,
        transform: GradientRotation(start),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_SpectrumRingPainter old) =>
      old.progress != progress || old.rotation != rotation;
}

class _TimerPreview extends StatelessWidget {
  final int seconds;
  final Color accent;
  const _TimerPreview({required this.seconds, required this.accent});
  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60, s = seconds % 60;
    final txt = m > 0 ? '$m min${s > 0 ? ' $s s' : ''}' : '$s s';
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _SpectrumRingPainter(progress: 1, rotation: 0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  size: 46, color: Spectrum.inkSoft),
              const SizedBox(height: 8),
              Text(txt,
                  style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Spectrum.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Celebration ──────────────────────────────────────────────
class _Celebration extends StatefulWidget {
  final Color accent;
  final VoidCallback onDone;
  const _Celebration({super.key, required this.accent, required this.onDone});

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..forward();
  late final AnimationController _confetti = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward();

  @override
  void dispose() {
    _pop.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _confetti,
          builder: (context, _) =>
              CustomPaint(painter: _ConfettiPainter(_confetti.value)),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: widget.accent.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 4,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: PictogramView(
                      const PictogramRef.asset('star'), size: 120),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (r) => Spectrum.brand.createShader(r),
                child: const Text('Hotovo!',
                    style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(height: 6),
              const Text('All done!',
                  style: TextStyle(fontSize: 22, color: Palette.inkSoft)),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: widget.onDone,
                style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    minimumSize: const Size(200, 60)),
                child: const Text('Zpět'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t; // 0 → 1
  _ConfettiPainter(this.t);

  static final _rnd = math.Random(42);
  static final _particles = List.generate(
    90,
    (i) => (
      angle: _rnd.nextDouble() * 2 * math.pi,
      speed: 0.25 + _rnd.nextDouble() * 0.75,
      delay: _rnd.nextDouble() * 0.12,
      colorIdx: _rnd.nextInt(5),
      size: 5.0 + _rnd.nextDouble() * 10,
      spin: (_rnd.nextDouble() - 0.5) * 8,
    ),
  );

  static const _colors = [
    Spectrum.coral,
    Spectrum.amber,
    Spectrum.mint,
    Spectrum.sky,
    Spectrum.lavender,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = math.sqrt(cx * cx + cy * cy) * 0.95;

    for (final p in _particles) {
      final raw = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (raw <= 0) continue;
      // cubic ease-out: fast burst, settle
      final eased = 1 - math.pow(1 - raw, 3).toDouble();
      final dist = eased * maxDist * p.speed;
      final dx = cx + math.cos(p.angle) * dist;
      final dy = cy + math.sin(p.angle) * dist + eased * 50; // gentle gravity
      // fade out in final 35%
      final alpha = raw < 0.65
          ? 1.0
          : (1 - (raw - 0.65) / 0.35).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * raw);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        Paint()..color = _colors[p.colorIdx].withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
