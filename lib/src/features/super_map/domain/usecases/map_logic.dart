// ============================================================
// features/super_map/domain/usecases/map_logic.dart
// ------------------------------------------------------------
// Pure, widget-free geometry + algorithms for the node graph — a 1:1 port of
// the React engine atoms: sizeOf (per node-style), sideAnchor (snap an edge end
// to the midpoint of the facing side), buildPath (curved / orthogonal /
// straight routing), graph bounds, neighbour / incident sets, per-node in/out
// stats, and a point-to-path distance for edge hit-testing. No Flutter UI —
// only `dart:ui` geometry (Offset / Size / Rect / Path).
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

import '../entities/map_graph.dart';
import '../entities/map_node.dart';

/// Which side of a node card an edge end is anchored to.
enum NodeSide { top, bottom, left, right }

/// An edge endpoint: a world-space [point] on the [side] of a node.
class EdgeAnchor {
  const EdgeAnchor(this.point, this.side);
  final Offset point;
  final NodeSide side;
}

/// The resolved geometry of one edge — both anchors and the midpoint.
class EdgeGeometry {
  const EdgeGeometry(this.edge, this.a, this.b);
  final MapEdge edge;
  final EdgeAnchor a;
  final EdgeAnchor b;
  Offset get mid => Offset((a.point.dx + b.point.dx) / 2, (a.point.dy + b.point.dy) / 2);
}

/// In/out connection summary for a single node.
class NodeStats {
  const NodeStats({
    required this.inCount,
    required this.outCount,
    required this.inSum,
    required this.outSum,
  });
  final int inCount;
  final int outCount;
  final double inSum;
  final double outSum;
  double get net => inSum - outSum;
}

double _clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

/// Stateless graph geometry. Never instantiated.
abstract final class MapLogic {
  /// The rendered size of [node] in the given [style].
  static Size sizeOf(MapNode node, MapNodeStyle style) {
    final len = node.label.length.toDouble();
    switch (style) {
      case MapNodeStyle.chip:
        return Size(_clampD(len * 8 + 38, 78, 230), 32);
      case MapNodeStyle.pill:
        return Size(_clampD(len * 8.4 + 52, 96, 250), 42);
      case MapNodeStyle.card:
        final arLen = node.ar != null ? node.ar!.length * 1.15 : 0.0;
        final maxLen = math.max(len, arLen);
        final h = (node.sub != null || node.ar != null) ? 58.0 : 46.0;
        return Size(_clampD(maxLen * 8.4 + 62, 150, 252), h);
    }
  }

  /// Snaps an edge end to the midpoint of the side of node [c] (size [size])
  /// that faces [other].
  static EdgeAnchor sideAnchor(Offset c, Size size, Offset other) {
    final dx = other.dx - c.dx, dy = other.dy - c.dy;
    final hw = size.width / 2, hh = size.height / 2;
    if (dx.abs() * hh >= dy.abs() * hw) {
      return dx >= 0
          ? EdgeAnchor(Offset(c.dx + hw, c.dy), NodeSide.right)
          : EdgeAnchor(Offset(c.dx - hw, c.dy), NodeSide.left);
    }
    return dy >= 0
        ? EdgeAnchor(Offset(c.dx, c.dy + hh), NodeSide.bottom)
        : EdgeAnchor(Offset(c.dx, c.dy - hh), NodeSide.top);
  }

  /// Builds a routed [Path] from anchor [a] to anchor [b] in [style].
  static Path buildPath(EdgeAnchor a, EdgeAnchor b, MapEdgeStyle style) {
    final p = Path()..moveTo(a.point.dx, a.point.dy);
    switch (style) {
      case MapEdgeStyle.straight:
        p.lineTo(b.point.dx, b.point.dy);
      case MapEdgeStyle.orthogonal:
        if (a.side == NodeSide.left || a.side == NodeSide.right) {
          final mx = (a.point.dx + b.point.dx) / 2;
          p.lineTo(mx, a.point.dy);
          p.lineTo(mx, b.point.dy);
        } else {
          final my = (a.point.dy + b.point.dy) / 2;
          p.lineTo(a.point.dx, my);
          p.lineTo(b.point.dx, my);
        }
        p.lineTo(b.point.dx, b.point.dy);
      case MapEdgeStyle.curved:
        final dist = (b.point - a.point).distance;
        final d = math.max(40.0, dist * 0.4);
        final c1 = _off(a.point, a.side, d);
        final c2 = _off(b.point, b.side, d);
        p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.point.dx, b.point.dy);
    }
    return p;
  }

  static Offset _off(Offset pt, NodeSide side, double d) => switch (side) {
        NodeSide.left => Offset(pt.dx - d, pt.dy),
        NodeSide.right => Offset(pt.dx + d, pt.dy),
        NodeSide.top => Offset(pt.dx, pt.dy - d),
        NodeSide.bottom => Offset(pt.dx, pt.dy + d),
      };

  /// Resolves the geometry of every edge whose endpoints both exist.
  static List<EdgeGeometry> geometry(
    List<MapNode> nodes,
    List<MapEdge> edges,
    MapNodeStyle style,
  ) {
    final byId = {for (final n in nodes) n.id: n};
    final out = <EdgeGeometry>[];
    for (final e in edges) {
      final from = byId[e.from], to = byId[e.to];
      if (from == null || to == null) continue;
      final a = sideAnchor(from.center, sizeOf(from, style), to.center);
      final b = sideAnchor(to.center, sizeOf(to, style), from.center);
      out.add(EdgeGeometry(e, a, b));
    }
    return out;
  }

  /// The world-space bounding box of all [nodes], or null when the list is empty.
  static Rect? bounds(List<MapNode> nodes, MapNodeStyle style) {
    if (nodes.isEmpty) return null;
    var x0 = double.infinity, y0 = double.infinity;
    var x1 = -double.infinity, y1 = -double.infinity;
    for (final n in nodes) {
      final s = sizeOf(n, style);
      x0 = math.min(x0, n.x - s.width / 2);
      y0 = math.min(y0, n.y - s.height / 2);
      x1 = math.max(x1, n.x + s.width / 2);
      y1 = math.max(y1, n.y + s.height / 2);
    }
    return Rect.fromLTRB(x0, y0, x1, y1);
  }

  /// The set of node ids directly connected to [nodeId] (either direction).
  static Set<String> neighbours(List<MapEdge> edges, String nodeId) {
    final s = <String>{};
    for (final e in edges) {
      if (e.from == nodeId) s.add(e.to);
      if (e.to == nodeId) s.add(e.from);
    }
    return s;
  }

  /// The ids of the edges incident to [nodeId].
  static Set<String> incidentEdges(List<MapEdge> edges, String nodeId) {
    final s = <String>{};
    for (final e in edges) {
      if (e.from == nodeId || e.to == nodeId) s.add(e.id);
    }
    return s;
  }

  /// In/out counts and value sums for [nodeId].
  static NodeStats statsFor(List<MapEdge> edges, String nodeId) {
    var inC = 0, outC = 0;
    var inS = 0.0, outS = 0.0;
    for (final e in edges) {
      if (e.to == nodeId) {
        inC++;
        inS += e.value ?? 0;
      }
      if (e.from == nodeId) {
        outC++;
        outS += e.value ?? 0;
      }
    }
    return NodeStats(inCount: inC, outCount: outC, inSum: inS, outSum: outS);
  }

  /// The node whose card rect contains world-space [point], topmost first, or
  /// null. Used for drop-to-connect hit-testing.
  static MapNode? nodeAt(List<MapNode> nodes, Offset point, MapNodeStyle style) {
    for (final n in nodes.reversed) {
      final s = sizeOf(n, style);
      final r = Rect.fromCenter(center: n.center, width: s.width, height: s.height);
      if (r.contains(point)) return n;
    }
    return null;
  }

  /// The shortest distance (world units) from [point] to a routed edge path,
  /// sampled along its metric. Used to pick the nearest edge on a canvas tap.
  static double distanceToPath(Path path, Offset point) {
    var best = double.infinity;
    for (final metric in path.computeMetrics()) {
      final steps = math.max(2, (metric.length / 8).ceil());
      for (var i = 0; i <= steps; i++) {
        final t = metric.length * (i / steps);
        final tan = metric.getTangentForOffset(t);
        if (tan == null) continue;
        final d = (tan.position - point).distance;
        if (d < best) best = d;
      }
    }
    return best;
  }
}
