// ============================================================
// features/super_map/presentation/painters/grid_painter.dart
// ------------------------------------------------------------
// The dot-grid backdrop. A faint 24px radial-dot lattice that tracks the view
// transform (scales + pans with the canvas) so the user keeps a clear sense of
// depth and distance. Painted in screen space.
// ============================================================

import 'package:flutter/widgets.dart';

class GridPainter extends CustomPainter {
  const GridPainter({
    required this.offset,
    required this.scale,
    required this.color,
  });

  final Offset offset;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final step = 24 * scale;
    if (step < 6) return; // too dense to be useful when zoomed far out
    final dot = Paint()..color = color;
    final r = (scale.clamp(0.6, 1.4)) * 1.0;
    var startX = offset.dx % step;
    var startY = offset.dy % step;
    if (startX > 0) startX -= step;
    if (startY > 0) startY -= step;
    for (var x = startX; x < size.width; x += step) {
      for (var y = startY; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), r, dot);
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      old.offset != offset || old.scale != scale || old.color != color;
}
