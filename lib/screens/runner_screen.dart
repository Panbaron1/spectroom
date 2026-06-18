import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/lang_store.dart';
import '../data/prefs.dart';
import '../design/spectrum.dart';
import '../models/challenge.dart';
import '../models/pictogram_ref.dart';
import '../services/audio_service.dart';
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
  String _kidVocative = '';
  bool _completionRecorded = false;

  Color get _accent => Palette.of(widget.challenge.category);
  Color get _tint => Palette.tintOf(widget.challenge.category);
  bool get _atEnd => _index >= widget.challenge.steps.length;

  @override
  void initState() {
    super.initState();
    if (widget.live) _playStepAudio(0);
    Prefs.kidVocative().then((v) { if (mounted) setState(() => _kidVocative = v); });
  }

  @override
  void dispose() {
    AudioService.instance.stopVoice();
    super.dispose();
  }

  void _playStepAudio(int index) {
    if (index >= widget.challenge.steps.length) return;
    final audio = widget.challenge.steps[index].audioPath;
    if (audio != null && audio.isNotEmpty) {
      AudioService.instance.playVoice(audio);
    } else {
      AudioService.instance.stopVoice();
    }
  }

  void _next() {
    if (_atEnd) return;
    setState(() => _index++);
    if (widget.live) {
      if (!_atEnd) {
        _playStepAudio(_index);
      } else {
        AudioService.instance.stopVoice();
        if (!_completionRecorded) {
          _completionRecorded = true;
          Prefs.setLastDone(widget.challenge.id);
        }
      }
    }
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
    if (widget.live) _playStepAudio(_index);
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.challenge.steps;
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(_tint.withValues(alpha: 0.55), Spectrum.bg),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.challenge.title(LangStore.instance.lang)),
      ),
      body: SafeArea(
        child: ContentBox(
          child: widget.live
            ? Column(
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
                              kidVocative: _kidVocative,
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
                              label: Text(LangStore.instance.lang == 'en' ? 'Next' : 'Další'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : _ScheduleStrip(
                challenge: widget.challenge,
                accent: _accent,
                lang: LangStore.instance.lang,
                onStart: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RunnerScreen(challenge: widget.challenge, live: true),
                  ),
                ),
              ),
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
    final lang = LangStore.instance.lang;
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final screenH = mq.size.height;
    final pictoSize = isLandscape
        ? (screenH * 0.24).clamp(90.0, 200.0)
        : (screenH * 0.32).clamp(160.0, 400.0);
    final ringSize = isLandscape
        ? (screenH * 0.28).clamp(120.0, 200.0)
        : (screenH * 0.26).clamp(150.0, 260.0);
    final countdownSize = isLandscape
        ? (screenH * 0.26).clamp(110.0, 190.0)
        : (screenH * 0.24).clamp(140.0, 230.0);
    final edgePad = isLandscape ? 10.0 : 24.0;
    final label = Text(
      step.label(lang),
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 30, fontWeight: FontWeight.w800, color: Palette.ink),
    );

    Widget hero;
    switch (step.kind) {
      case StepKind.info:
        hero = _PictoHero(ref: step.pictogram, size: pictoSize);
        break;
      case StepKind.countdown:
        hero = live
            ? _CountdownTapper(
                start: step.count ?? 1, accent: accent, onDone: onComplete,
                size: countdownSize)
            : _CountdownPreview(count: step.count ?? 1, accent: accent,
                size: countdownSize);
        break;
      case StepKind.timer:
        final timerPictoSize = (pictoSize * 0.55).clamp(70.0, 110.0);
        final timerWidget = live
            ? _TimerRunner(
                seconds: step.durationSec ?? 30,
                accent: accent,
                onDone: onComplete,
                size: ringSize)
            : _TimerPreview(seconds: step.durationSec ?? 30, accent: accent,
                size: ringSize);
        hero = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PictoHero(ref: step.pictogram, size: timerPictoSize),
            SizedBox(height: isLandscape ? 8 : 20),
            timerWidget,
          ],
        );
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: edgePad, vertical: edgePad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: hero))),
          SizedBox(height: isLandscape ? 8 : 24),
          label,
          SizedBox(height: isLandscape ? 6 : 16),
        ],
      ),
    );
  }
}

class _PictoHero extends StatelessWidget {
  final PictogramRef ref;
  final double size;
  const _PictoHero({required this.ref, this.size = 200});
  @override
  Widget build(BuildContext context) {
    final pad = size * 0.14;
    final radius = size * 0.22;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: PictogramView(ref, size: size),
    );
  }
}

// ── Countdown ────────────────────────────────────────────────
class _CountdownTapper extends StatefulWidget {
  final int start;
  final Color accent;
  final VoidCallback onDone;
  final double size;
  const _CountdownTapper(
      {required this.start, required this.accent, required this.onDone,
      this.size = 230});

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
    HapticFeedback.selectionClick();
    AudioService.instance.playTick();
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
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Spectrum.sweep,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Spectrum.coral.withValues(alpha: 0.35),
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
        Text(
          LangStore.instance.lang == 'en' ? 'Tap the circle' : 'Klepni na kruh',
          style: TextStyle(color: Palette.inkSoft, fontSize: 15),
        ),
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
  final double size;
  const _CountdownPreview({required this.count, required this.accent,
      this.size = 230});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Spectrum.sweep),
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
  final double size;
  const _TimerRunner(
      {required this.seconds, required this.accent, required this.onDone,
      this.size = 280});

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
  bool _displayMinSec = true;

  @override
  void initState() {
    super.initState();
    Prefs.timerDisplayMinSec().then((v) {
      if (mounted) setState(() => _displayMinSec = v);
    });
    _ring.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onDone();
        });
      }
    });
  }

  void _start() {
    if (_running) return;
    HapticFeedback.heavyImpact();
    setState(() => _running = true);
    _ring.forward();
  }

  @override
  void dispose() {
    _ring.dispose();
    _breath.dispose();
    super.dispose();
  }

  String _fmt(int s) => _displayMinSec
      ? '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}'
      : '$s';

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
            final sz = widget.size;
            final innerSz = sz * (240 / 280);
            return Transform.scale(
              scale: breathe,
              child: SizedBox(
                width: sz,
                height: sz,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // soft spectrum glow that fades as time drains
                    Container(
                      width: innerSz,
                      height: innerSz,
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
                      size: Size(sz, sz),
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
  final double size;
  const _TimerPreview({required this.seconds, required this.accent,
      this.size = 280});
  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60, s = seconds % 60;
    final txt = m > 0 ? '$m min${s > 0 ? ' $s s' : ''}' : '$s s';
    return SizedBox(
      width: size,
      height: size,
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
  final String kidVocative;
  const _Celebration({super.key, required this.accent, required this.onDone, this.kidVocative = ''});

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
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    AudioService.instance.playCelebration();
  }

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
          child: SingleChildScrollView(
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
                child: Text(
                    LangStore.instance.lang == 'en' ? 'All done!' : 'Hotovo!',
                    style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              if (widget.kidVocative.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  LangStore.instance.lang == 'en'
                      ? 'Well done, ${widget.kidVocative}!'
                      : 'Výborně, ${widget.kidVocative}!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: widget.accent),
                ),
              ],
              const SizedBox(height: 40),
              FilledButton(
                onPressed: widget.onDone,
                style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    minimumSize: const Size(200, 60)),
                child: Text(LangStore.instance.lang == 'en' ? 'Back' : 'Zpět'),
              ),
            ],
          ),
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

// ── Schedule strip (rehearsal mode) ─────────────────────────
class _ScheduleStrip extends StatelessWidget {
  final Challenge challenge;
  final Color accent;
  final String lang;
  final VoidCallback onStart;
  const _ScheduleStrip({
    required this.challenge,
    required this.accent,
    required this.lang,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final steps = challenge.steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            lang == 'en' ? "Here's what happens:" : 'Co nás čeká:',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: steps.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _StripTile(
              step: steps[i],
              index: i,
              accent: accent,
              lang: lang,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              minimumSize: const Size.fromHeight(60),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              lang == 'en' ? "Let's do it!" : 'Jdeme na to!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _StripTile extends StatelessWidget {
  final ChallengeStep step;
  final int index;
  final Color accent;
  final String lang;
  const _StripTile({
    required this.step,
    required this.index,
    required this.accent,
    required this.lang,
  });

  String _fmtDur(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final r = s % 60;
    return r > 0 ? '${m}m ${r}s' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final (String chipLabel, Color chipColor) = switch (step.kind) {
      StepKind.info => (
          lang == 'en' ? 'Picture' : 'Obrázek',
          Spectrum.sky,
        ),
      StepKind.countdown => (
          '×${step.count ?? '?'}',
          Spectrum.amber,
        ),
      StepKind.timer => (
          step.durationSec != null ? _fmtDur(step.durationSec!) : '⏱',
          Spectrum.mint,
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Spectrum.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PictoHero(ref: step.pictogram, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label(lang),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chipColor,
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
