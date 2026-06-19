// ============================================================
// features/super_map/domain/usecases/map_layout.dart
// ------------------------------------------------------------
// Deterministic auto-layout for SuperMap (v1.0.0). Pure Dart over the entity
// model — given a graph it returns a NEW list of nodes with recomputed `x`/`y`,
// leaving labels, kinds, values and edges untouched. The controller calls these
// to "tidy" a hand-built or freshly-imported ERP diagram into a readable shape.
//
// Three algorithms, each suited to a different ERP diagram shape:
//   • layered  — longest-path layering of a DAG into left→right (or top→down)
//                ranks. The right pick for approval chains and document flows,
//                where direction == process order.
//   • grid     — simple row-major grid in node order. The safe fallback for a
//                bag of records with no meaningful flow (e.g. a chart of stores).
//   • radial   — a chosen/!inferred root at the center, descendants on
//                concentric rings by BFS depth. Good for one account exploding
//                into its sub-accounts.
//
// Layout never moves a node flagged [MapNode.locked]; locked nodes keep their
// hand-placed coordinates and the rest flow around them.
// ============================================================

import 'dart:math' as math;

import '../entities/map_graph.dart';
import '../entities/map_node.dart';

/// Which auto-layout algorithm [MapLayout.apply] should run.
enum MapLayoutKind { layered, grid, radial }

/// The axis a [MapLayoutKind.layered] layout flows along.
enum MapLayoutDirection { leftToRight, topToBottom }

/// Tunable spacing for a layout pass. Defaults are sized for the package's
/// ~200×96 node cards with comfortable gutters.
class MapLayoutSpec {
  const MapLayoutSpec({
    this.kind = MapLayoutKind.layered,
    this.direction = MapLayoutDirection.leftToRight,
    this.rankGap = 320,
    this.nodeGap = 180,
    this.origin = const (60.0, 60.0),
    this.rootId,
    this.ringGap = 260,
  });

  /// The algorithm to run.
  final MapLayoutKind kind;

  /// Flow axis for [MapLayoutKind.layered].
  final MapLayoutDirection direction;

  /// Distance between successive ranks / grid columns (along the flow axis).
  final double rankGap;

  /// Distance between siblings within a rank / grid rows (cross axis).
  final double nodeGap;

  /// Top-left anchor the layout grows from, as `(x, y)`.
  final (double, double) origin;

  /// The root for [MapLayoutKind.radial]. When null the node with the highest
  /// out-degree (or simply the first node) is used.
  final String? rootId;

  /// Ring-to-ring distance for [MapLayoutKind.radial].
  final double ringGap;
}

/// Stateless layout engine. Never instantiated.
abstract final class MapLayout {
  /// Returns a copy of [graph] with auto-placed node coordinates per [spec].
  /// Edges are returned untouched. Locked nodes keep their coordinates.
  static MapGraph apply(MapGraph graph, MapLayoutSpec spec) {
    final placed = switch (spec.kind) {
      MapLayoutKind.layered => _layered(graph, spec),
      MapLayoutKind.grid => _grid(graph, spec),
      MapLayoutKind.radial => _radial(graph, spec),
    };
    return graph.copyWith(nodes: placed);
  }

  /// Convenience: layered left→right with default spacing.
  static MapGraph tidy(MapGraph graph) =>
      apply(graph, const MapLayoutSpec());

  // Re-applies original coordinates for any locked node so a layout never
  // disturbs audit-pinned records.
  static List<MapNode> _respectLocks(
    List<MapNode> original,
    Map<String, (double, double)> coords,
  ) =>
      [
        for (final n in original)
          n.locked
              ? n
              : () {
                  final c = coords[n.id];
                  return c == null ? n : n.copyWith(x: c.$1, y: c.$2);
                }(),
      ];

  // ── layered (longest-path ranking of a DAG; cycles tolerated) ──
  static List<MapNode> _layered(MapGraph g, MapLayoutSpec spec) {
    final ids = g.nodes.map((n) => n.id).toSet();
    final outAdj = <String, List<String>>{};
    final indeg = <String, int>{for (final n in g.nodes) n.id: 0};
    for (final e in g.edges) {
      if (e.from == e.to) continue;
      if (!ids.contains(e.from) || !ids.contains(e.to)) continue;
      (outAdj[e.from] ??= []).add(e.to);
      indeg[e.to] = (indeg[e.to] ?? 0) + 1;
    }

    // Kahn-style longest-path ranking; nodes left in a cycle fall to rank 0.
    final rank = <String, int>{for (final n in g.nodes) n.id: 0};
    final queue = <String>[
      for (final n in g.nodes)
        if ((indeg[n.id] ?? 0) == 0) n.id
    ];
    final workIndeg = Map<String, int>.from(indeg);
    var head = 0;
    while (head < queue.length) {
      final u = queue[head++];
      for (final v in outAdj[u] ?? const <String>[]) {
        rank[v] = math.max(rank[v] ?? 0, (rank[u] ?? 0) + 1);
        workIndeg[v] = (workIndeg[v] ?? 0) - 1;
        if (workIndeg[v] == 0) queue.add(v);
      }
    }

    // Group by rank, preserving node order within a rank.
    final byRank = <int, List<MapNode>>{};
    for (final n in g.nodes) {
      (byRank[rank[n.id] ?? 0] ??= []).add(n);
    }

    final coords = <String, (double, double)>{};
    final (ox, oy) = spec.origin;
    final horizontal = spec.direction == MapLayoutDirection.leftToRight;
    final ranks = byRank.keys.toList()..sort();
    for (final r in ranks) {
      final col = byRank[r]!;
      for (var i = 0; i < col.length; i++) {
        final along = (horizontal ? ox : oy) + r * spec.rankGap;
        final cross = (horizontal ? oy : ox) + i * spec.nodeGap;
        coords[col[i].id] = horizontal ? (along, cross) : (cross, along);
      }
    }
    return _respectLocks(g.nodes, coords);
  }

  // ── grid (row-major in node order) ──
  static List<MapNode> _grid(MapGraph g, MapLayoutSpec spec) {
    final n = g.nodes.length;
    final cols = math.max(1, math.sqrt(n).ceil());
    final (ox, oy) = spec.origin;
    final coords = <String, (double, double)>{};
    for (var i = 0; i < n; i++) {
      final c = i % cols, r = i ~/ cols;
      coords[g.nodes[i].id] = (ox + c * spec.rankGap, oy + r * spec.nodeGap);
    }
    return _respectLocks(g.nodes, coords);
  }

  // ── radial (BFS rings from a root) ──
  static List<MapNode> _radial(MapGraph g, MapLayoutSpec spec) {
    if (g.nodes.isEmpty) return g.nodes;
    final ids = g.nodes.map((n) => n.id).toSet();
    final adj = <String, List<String>>{};
    final outDeg = <String, int>{for (final n in g.nodes) n.id: 0};
    for (final e in g.edges) {
      if (!ids.contains(e.from) || !ids.contains(e.to) || e.from == e.to) {
        continue;
      }
      (adj[e.from] ??= []).add(e.to);
      (adj[e.to] ??= []).add(e.from); // undirected for ring placement
      outDeg[e.from] = (outDeg[e.from] ?? 0) + 1;
    }

    final rootId = spec.rootId ??
        (g.nodes.toList()
              ..sort((a, b) => (outDeg[b.id] ?? 0).compareTo(outDeg[a.id] ?? 0)))
            .first
            .id;

    // BFS depth from the root.
    final depth = <String, int>{rootId: 0};
    final q = <String>[rootId];
    var head = 0;
    while (head < q.length) {
      final u = q[head++];
      for (final v in adj[u] ?? const <String>[]) {
        if (!depth.containsKey(v)) {
          depth[v] = depth[u]! + 1;
          q.add(v);
        }
      }
    }
    // Disconnected nodes ring out at the max depth + 1.
    final maxDepth = depth.values.fold(0, math.max);
    for (final n in g.nodes) {
      depth.putIfAbsent(n.id, () => maxDepth + 1);
    }

    final byRing = <int, List<MapNode>>{};
    for (final n in g.nodes) {
      (byRing[depth[n.id]!] ??= []).add(n);
    }

    final (ox, oy) = spec.origin;
    // Center is offset from origin by the outermost ring radius.
    final maxRing = byRing.keys.fold(0, math.max);
    final cx = ox + maxRing * spec.ringGap;
    final cy = oy + maxRing * spec.ringGap;
    final coords = <String, (double, double)>{};
    for (final entry in byRing.entries) {
      final ring = entry.key;
      final members = entry.value;
      if (ring == 0) {
        coords[members.first.id] = (cx, cy);
        continue;
      }
      final radius = ring * spec.ringGap;
      for (var i = 0; i < members.length; i++) {
        final angle = (2 * math.pi * i) / members.length;
        coords[members[i].id] =
            (cx + radius * math.cos(angle), cy + radius * math.sin(angle));
      }
    }
    return _respectLocks(g.nodes, coords);
  }
}
