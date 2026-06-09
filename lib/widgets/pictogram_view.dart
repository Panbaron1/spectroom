import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/pictogram_ref.dart';

/// Central renderer for every pictogram. The ONE place that knows how each
/// [PictogramKind] is drawn — swapping the symbol library means editing only
/// this widget, not any content.
class PictogramView extends StatelessWidget {
  final PictogramRef ref;
  final double size;

  const PictogramView(this.ref, {super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    switch (ref.kind) {
      case PictogramKind.emoji:
        return Text(ref.value, style: TextStyle(fontSize: size * 0.8));

      case PictogramKind.mulberry:
        return SvgPicture.asset(
          'assets/pictograms/${ref.value}.svg',
          width: size,
          height: size,
          placeholderBuilder: (_) =>
              _fallback(size, Icons.image_outlined),
        );

      case PictogramKind.photo:
        final f = File(ref.value);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.12),
          child: Image.file(
            f,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) =>
                _fallback(size, Icons.broken_image_outlined),
          ),
        );
    }
  }

  Widget _fallback(double size, IconData icon) =>
      Icon(icon, size: size * 0.7, color: Colors.black26);
}
