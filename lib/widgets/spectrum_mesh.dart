import 'package:flutter/material.dart';

import '../design/spectrum.dart';

/// A soft, calm mesh gradient — blurred spectrum blobs over near-white.
/// The signature brand backdrop. Cheap (CustomPaint + blur mask), no shader pkg.
class SpectrumMesh extends StatelessWidget {
  /// 0..1 — how present the spectrum is. Keep low for calm backdrops.
  final double intensity;
  final bool animate;

  const SpectrumMesh({super.key, this.intensity = 0.5, this.animate = false});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _MeshPainter(intensity),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double intensity;
  _MeshPainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    // base wash
    canvas.drawRect(Offset.zero & size, Paint()..color = Spectrum.bg);

    final blobs = <(Offset, double, Color)>[
      (Offset(size.width * 0.18, size.height * 0.20), size.width * 0.55, Spectrum.coral),
      (Offset(size.width * 0.85, size.height * 0.18), size.width * 0.50, Spectrum.amber),
      (Offset(size.width * 0.80, size.height * 0.62), size.width * 0.60, Spectrum.sky),
      (Offset(size.width * 0.20, size.height * 0.72), size.width * 0.58, Spectrum.mint),
      (Offset(size.width * 0.55, size.height * 0.45), size.width * 0.50, Spectrum.lavender),
    ];

    for (final (center, radius, color) in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.55 * intensity),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.intensity != intensity;
}
