// ============================================================
// features/super_map/domain/usecases/map_validator.dart
// ------------------------------------------------------------
// Graph-integrity validation for SuperMap (v1.0.0) — the audit-grade checks an
// ERP diagram needs before it is trusted as a record of a real process. Pure,
// widget-free Dart over the entity model; the View surfaces the returned
// [MapIssue]s in the validation panel and the controller exposes `validate()`.
//
// Checks performed:
//   • dangling edge      — an edge whose `from` / `to` node is missing (error)
//   • duplicate node id  — two nodes share an id (error: selection breaks)
//   • duplicate edge id  — two edges share an id (error)
//   • self-loop          — an edge from a node to itself (warning)
//   • parallel edge      — a second edge with the same from→to pair (info)
//   • orphan node        — a node with no incident edges (warning)
//   • cycle              — a directed cycle, reported once per back-edge
//                          (warning — illegal in approval / accounting flows)
//   • flow imbalance     — a node whose incoming value sum ≠ outgoing value sum
//                          beyond [balanceEpsilon] (warning — the double-entry /
//                          conservation check). Only nodes that BOTH receive and
//                          emit value are tested; pure sources / sinks are skipped.
// ============================================================

import '../entities/map_graph.dart';
import '../entities/map_node.dart';

/// How serious a [MapIssue] is. Drives the panel's icon + color.
enum MapIssueSeverity { error, warning, info }

/// What kind of problem a [MapIssue] reports — a stable machine tag distinct
/// from the human [MapIssue.message].
enum MapIssueCode {
  danglingEdge,
  duplicateNodeId,
  duplicateEdgeId,
  selfLoop,
  parallelEdge,
  orphanNode,
  cycle,
  flowImbalance,
}

/// One problem found by [MapValidator]. Points at the offending node or edge
/// (when applicable) so the View can select / center it on tap.
class MapIssue {
  const MapIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.nodeId,
    this.edgeId,
  });

  final MapIssueCode code;
  final MapIssueSeverity severity;

  /// A human, operator-facing description (sentence case, no period needed).
  final String message;

  /// The node this issue is anchored to, when any.
  final String? nodeId;

  /// The edge this issue is anchored to, when any.
  final String? edgeId;

  bool get isError => severity == MapIssueSeverity.error;
}

/// A grouped count of issues by severity — handy for a toolbar badge.
class MapValidationSummary {
  const MapValidationSummary(this.issues);
  final List<MapIssue> issues;

  int get errors => issues.where((i) => i.severity == MapIssueSeverity.error).length;
  int get warnings => issues.where((i) => i.severity == MapIssueSeverity.warning).length;
  int get infos => issues.where((i) => i.severity == MapIssueSeverity.info).length;

  bool get isClean => issues.isEmpty;
  int get total => issues.length;
}

/// Stateless graph validator. Never instantiated.
abstract final class MapValidator {
  /// Runs every check against [graph] and returns the issues, errors first.
  /// [balanceEpsilon] is the tolerance for the flow-imbalance check (defaults
  /// to 0.5 currency units to absorb rounding).
  static List<MapIssue> validate(
    MapGraph graph, {
    double balanceEpsilon = 0.5,
  }) {
    final issues = <MapIssue>[];
    final nodes = graph.nodes;
    final edges = graph.edges;

    // ── id maps + duplicate detection ──
    final seenNodeIds = <String>{};
    final dupNodeIds = <String>{};
    for (final n in nodes) {
      if (!seenNodeIds.add(n.id)) dupNodeIds.add(n.id);
    }
    for (final id in dupNodeIds) {
      issues.add(MapIssue(
        code: MapIssueCode.duplicateNodeId,
        severity: MapIssueSeverity.error,
        message: 'Duplicate node id "$id" — selection and connections will break',
        nodeId: id,
      ));
    }

    final seenEdgeIds = <String>{};
    for (final e in edges) {
      if (!seenEdgeIds.add(e.id)) {
        issues.add(MapIssue(
          code: MapIssueCode.duplicateEdgeId,
          severity: MapIssueSeverity.error,
          message: 'Duplicate connection id "${e.id}"',
          edgeId: e.id,
        ));
      }
    }

    final byId = {for (final n in nodes) n.id: n};

    // ── per-edge checks ──
    final pairSeen = <String>{};
    final incident = <String, int>{};
    for (final e in edges) {
      final fromOk = byId.containsKey(e.from);
      final toOk = byId.containsKey(e.to);
      if (!fromOk || !toOk) {
        final missing = !fromOk ? e.from : e.to;
        issues.add(MapIssue(
          code: MapIssueCode.danglingEdge,
          severity: MapIssueSeverity.error,
          message: 'Connection "${e.id}" points at a missing node "$missing"',
          edgeId: e.id,
        ));
        continue; // a dangling edge can't contribute to the other checks
      }
      incident[e.from] = (incident[e.from] ?? 0) + 1;
      incident[e.to] = (incident[e.to] ?? 0) + 1;

      if (e.from == e.to) {
        issues.add(MapIssue(
          code: MapIssueCode.selfLoop,
          severity: MapIssueSeverity.warning,
          message: 'Node "${byId[e.from]!.label}" is connected to itself',
          edgeId: e.id,
          nodeId: e.from,
        ));
      }
      final pair = '${e.from}\u0000${e.to}';
      if (!pairSeen.add(pair) && e.from != e.to) {
        issues.add(MapIssue(
          code: MapIssueCode.parallelEdge,
          severity: MapIssueSeverity.info,
          message: 'A second connection runs ${byId[e.from]!.label} → ${byId[e.to]!.label}',
          edgeId: e.id,
        ));
      }
    }

    // ── orphan nodes ──
    for (final n in nodes) {
      if ((incident[n.id] ?? 0) == 0 && !dupNodeIds.contains(n.id)) {
        issues.add(MapIssue(
          code: MapIssueCode.orphanNode,
          severity: MapIssueSeverity.warning,
          message: 'Node "${n.label}" has no connections',
          nodeId: n.id,
        ));
      }
    }

    // ── cycle detection (DFS over valid edges) ──
    for (final issue in _cycles(nodes, edges, byId)) {
      issues.add(issue);
    }

    // ── flow imbalance (the double-entry / conservation check) ──
    for (final n in nodes) {
      var inSum = 0.0, outSum = 0.0, inCount = 0, outCount = 0;
      for (final e in edges) {
        if (!byId.containsKey(e.from) || !byId.containsKey(e.to)) continue;
        if (e.to == n.id) {
          inSum += e.value ?? 0;
          inCount++;
        }
        if (e.from == n.id) {
          outSum += e.value ?? 0;
          outCount++;
        }
      }
      // Only test pass-through nodes that both receive and emit value.
      if (inCount > 0 && outCount > 0 && inSum > 0 && outSum > 0) {
        final delta = inSum - outSum;
        if (delta.abs() > balanceEpsilon) {
          final sign = delta > 0 ? '+' : '-';
          issues.add(MapIssue(
            code: MapIssueCode.flowImbalance,
            severity: MapIssueSeverity.warning,
            message:
                'Node "${n.label}" is unbalanced — in and out differ by $sign${delta.abs().toStringAsFixed(2)}',
            nodeId: n.id,
          ));
        }
      }
    }

    // errors first, then warnings, then infos — stable within a severity.
    issues.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return issues;
  }

  /// Convenience wrapper returning a [MapValidationSummary].
  static MapValidationSummary summarise(MapGraph graph, {double balanceEpsilon = 0.5}) =>
      MapValidationSummary(validate(graph, balanceEpsilon: balanceEpsilon));

  // DFS cycle detection over the directed graph (valid edges only). Reports one
  // issue per back-edge encountered so each cycle surfaces without flooding.
  static List<MapIssue> _cycles(
    List<MapNode> nodes,
    List<MapEdge> edges,
    Map<String, MapNode> byId,
  ) {
    final adj = <String, List<MapEdge>>{};
    for (final e in edges) {
      if (e.from == e.to) continue; // self-loops handled separately
      if (!byId.containsKey(e.from) || !byId.containsKey(e.to)) continue;
      (adj[e.from] ??= []).add(e);
    }

    const white = 0, grey = 1, black = 2;
    final color = {for (final n in nodes) n.id: white};
    final out = <MapIssue>[];

    void visit(String id) {
      color[id] = grey;
      for (final e in adj[id] ?? const <MapEdge>[]) {
        final c = color[e.to] ?? white;
        if (c == grey) {
          out.add(MapIssue(
            code: MapIssueCode.cycle,
            severity: MapIssueSeverity.warning,
            message:
                'Cycle: ${byId[e.from]!.label} → ${byId[e.to]!.label} loops back into the path',
            edgeId: e.id,
            nodeId: e.to,
          ));
        } else if (c == white) {
          visit(e.to);
        }
      }
      color[id] = black;
    }

    for (final n in nodes) {
      if ((color[n.id] ?? white) == white) visit(n.id);
    }
    return out;
  }
}
