// ============================================================
// features/super_map/presentation/widgets/map_minimap.dart
// ------------------------------------------------------------
// The bottom-left minimap: a 168×108 overview that fits the whole graph, draws
// every edge as a hairline and every node as a kind-colored dot, and overlays
// the current viewport rectangle. A port of the React minimap.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/entities/map_graph.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/usecases/map_logic.dart';

class MapMinimap extends StatelessWidget {
  const MapMinimap({
    super.key,
    required this.nodes,
    required this.geometry,
    required this.bounds,
    required this.style,
    required this.offset,
    required this.scale,
    required this.viewport,
    required this.selectedNodeId,
  });

  final List<MapNode> nodes;
  final List<EdgeGeometry> geometry;
  final Rect bounds;
  final MapNodeStyle style;
  final Offset offset;
  final double scale;
  final Size viewport;
  final String? selectedNodeId;

  static const double w = 168;
  static const double h = 108;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Color.alphaBlend(t.surface.withOpacity(0.9), t.bg),
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _MinimapPainter(
          nodes: nodes,
          geometry: geometry,
          bounds: bounds,
          offset: offset,
          scale: scale,
          viewport: viewport,
          selectedNodeId: selectedNodeId,
          edgeColor: t.borderStrong,
          accent: SuperTokens.accent,
          accentForNode: (n) => n.accentOf(t),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.nodes,
    required this.geometry,
    required this.bounds,
    required this.offset,
    required this.scale,
    required this.viewport,
    required this.selectedNodeId,
    required this.edgeColor,
    required this.accent,
    required this.accentForNode,
  });

  final List<MapNode> nodes;
  final List<EdgeGeometry> geometry;
  final Rect bounds;
  final Offset offset;
  final double scale;
  final Size viewport;
  final String? selectedNodeId;
  final Color edgeColor;
  final Color accent;
  final Color Function(MapNode) accentForNode;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final bw = bounds.width <= 0 ? 1 : bounds.width;
    final bh = bounds.height <= 0 ? 1 : bounds.height;
    final k = ((size.width - pad * 2) / bw).clamp(0.0, double.infinity);
    final kh = (size.height - pad * 2) / bh;
    final mk = k < kh ? k : kh;
    final ox = (size.width - bounds.width * mk) / 2 - bounds.left * mk;
    final oy = (size.height - bounds.height * mk) / 2 - bounds.top * mk;
    Offset map(Offset w) => Offset(w.dx * mk + ox, w.dy * mk + oy);

    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1;
    for (final g in geometry) {
      canvas.drawLine(map(g.a.point), map(g.b.point), edgePaint);
    }
    for (final n in nodes) {
      final p = Paint()..color = accentForNode(n);
      canvas.drawCircle(map(n.center), selectedNodeId == n.id ? 4 : 3, p);
    }

    // viewport rectangle (world rect currently visible)
    final viewWorld = Rect.fromLTWH(
      -offset.dx / scale,
      -offset.dy / scale,
      viewport.width / scale,
      viewport.height / scale,
    );
    final r = Rect.fromLTRB(
      map(viewWorld.topLeft).dx,
      map(viewWorld.topLeft).dy,
      map(viewWorld.bottomRight).dx,
      map(viewWorld.bottomRight).dy,
    );
    canvas.drawRect(r, Paint()..color = accent.withOpacity(0.14));
    canvas.drawRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = accent);
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.offset != offset ||
      old.scale != scale ||
      old.nodes != nodes ||
      old.geometry != geometry ||
      old.selectedNodeId != selectedNodeId ||
      old.viewport != viewport;
}
