// ============================================================
// features/super_map/presentation/painters/edge_painter.dart
// ------------------------------------------------------------
// Draws the directed connections between nodes: a routed path (curved /
// orthogonal / straight) per edge with a side-anchored arrowhead, plus the live
// dashed link preview while connecting. Edges fade when another node is
// selected, brighten + thicken when incident to the selection, and recolor to
// the source node's kind accent. Optional animated "flow" dashes. Painted in
// screen space from world geometry under the current view transform.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../domain/entities/map_graph.dart';
import '../../domain/entities/map_node.dart' show MapEdge;
import '../../domain/usecases/map_logic.dart';

class EdgePainter extends CustomPainter {
  const EdgePainter({
    required this.geometry,
    required this.edgeStyle,
    required this.offset,
    required this.scale,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.incident,
    required this.accentForEdge,
    required this.borderStrong,
    required this.accent,
    this.linkFrom,
    this.linkTo,
    this.flow = false,
    this.dashPhase = 0,
  });

  final List<EdgeGeometry> geometry;
  final MapEdgeStyle edgeStyle;
  final Offset offset;
  final double scale;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final Set<String> incident;

  /// Resolves the kind accent of the source node of [edge] (for incident edges).
  final Color Function(MapEdge edge) accentForEdge;
  final Color borderStrong;
  final Color accent;

  /// Live link preview (world space): anchor on the source side → cursor.
  final Offset? linkFrom;
  final Offset? linkTo;
  final bool flow;
  final double dashPhase;

  Offset _toScreen(Offset w) => w * scale + offset;

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = Matrix4.identity()
      ..translate(offset.dx, offset.dy)
      ..scale(scale);
    final m = matrix.storage;

    for (final g in geometry) {
      final on = incident.contains(g.edge.id);
      final dim = selectedNodeId != null && !on;
      final isSel = selectedEdgeId == g.edge.id;
      final color = isSel
          ? accent
          : (selectedNodeId != null && on ? accentForEdge(g.edge) : borderStrong);
      final opacity = dim
          ? 0.18
          : (isSel || (selectedNodeId != null && on) ? 0.95 : 0.55);
      final width = (isSel ? 2.8 : (on ? 2.4 : 1.6)) * scale;

      final worldPath = MapLogic.buildPath(g.a, g.b, edgeStyle);
      final screenPath = worldPath.transform(m);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withOpacity(opacity);

      if (flow) {
        canvas.drawPath(_dashed(screenPath, 7 * scale, 6 * scale, dashPhase * scale), paint);
      } else {
        canvas.drawPath(screenPath, paint);
      }
      _arrowhead(canvas, g, color.withOpacity(opacity));
    }

    // live link preview
    if (linkFrom != null && linkTo != null) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round
        ..color = accent;
      final path = Path()
        ..moveTo(_toScreen(linkFrom!).dx, _toScreen(linkFrom!).dy)
        ..lineTo(_toScreen(linkTo!).dx, _toScreen(linkTo!).dy);
      canvas.drawPath(_dashed(path, 5 * scale, 5 * scale, 0), p);
    }
  }

  void _arrowhead(Canvas canvas, EdgeGeometry g, Color color) {
    // direction the path arrives from, by anchor side
    final dir = switch (g.b.side) {
      NodeSide.left => const Offset(1, 0),
      NodeSide.right => const Offset(-1, 0),
      NodeSide.top => const Offset(0, 1),
      NodeSide.bottom => const Offset(0, -1),
    };
    final tip = _toScreen(g.b.point);
    final len = 8.0 * scale;
    final wing = 4.0 * scale;
    final back = tip + dir * len;
    final normal = Offset(-dir.dy, dir.dx);
    final p1 = back + normal * wing;
    final p2 = back - normal * wing;
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color..style = PaintingStyle.fill);
  }

  Path _dashed(Path source, double on, double off, double phase) {
    final out = Path();
    final span = on + off;
    for (final metric in source.computeMetrics()) {
      var dist = -(phase % span);
      while (dist < metric.length) {
        final start = math.max(0.0, dist);
        final end = math.min(metric.length, dist + on);
        if (end > start) out.addPath(metric.extractPath(start, end), Offset.zero);
        dist += span;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(EdgePainter old) =>
      old.offset != offset ||
      old.scale != scale ||
      old.geometry != geometry ||
      old.selectedNodeId != selectedNodeId ||
      old.selectedEdgeId != selectedEdgeId ||
      old.incident != incident ||
      old.edgeStyle != edgeStyle ||
      old.linkTo != linkTo ||
      old.dashPhase != dashPhase ||
      old.flow != flow;
}
