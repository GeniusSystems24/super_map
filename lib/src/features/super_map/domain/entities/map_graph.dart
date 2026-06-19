// ============================================================
// features/super_map/domain/entities/map_graph.dart
// ------------------------------------------------------------
// A whole diagram: a titled set of [MapNode]s + [MapEdge]s plus presentation
// metadata (a legend of the kinds it uses). Also the two rendering enums —
// [MapNodeStyle] (card / chip / pill) and [MapEdgeStyle] (curved / orthogonal /
// straight). Pure data.
// ============================================================

import 'package:flutter/foundation.dart';

import 'map_node.dart';

/// The visual form of a node card.
enum MapNodeStyle {
  /// Rectangular card with icon + label + secondary line (the default).
  card,

  /// Compact chip with a colored dot.
  chip,

  /// Elongated pill with a colored dot.
  pill,
}

/// How an edge is routed between two nodes.
enum MapEdgeStyle {
  /// Bézier curves that adapt to the facing sides of the nodes (the default).
  curved,

  /// Right-angled orthogonal segments.
  orthogonal,

  /// Direct straight lines.
  straight,
}

/// A complete node-graph: nodes, directed edges, a title and an optional
/// Arabic title / subtitle / legend used by the showcase chrome.
@immutable
class MapGraph {
  const MapGraph({
    required this.id,
    required this.title,
    this.ar,
    this.subtitle,
    this.legend = const [],
    this.currency = 'SAR',
    required this.nodes,
    required this.edges,
  });

  /// Stable id (used as a key when switching seeds).
  final String id;

  /// English title shown in the title chip.
  final String title;

  /// Optional Arabic title.
  final String? ar;

  /// Optional one-line plain-English explainer.
  final String? subtitle;

  /// The kinds this graph uses, in legend order.
  final List<MapNodeKind> legend;

  /// The currency code used to format node / edge [MapNode.value]s and the
  /// details-panel sums — e.g. `SAR`, `USD`, `AED` (v1.0.0). Rendered as a
  /// trailing code (`5,240.00 SAR`), Western digits regardless of language.
  final String currency;

  final List<MapNode> nodes;
  final List<MapEdge> edges;

  MapGraph copyWith({
    List<MapNode>? nodes,
    List<MapEdge>? edges,
  }) =>
      MapGraph(
        id: id,
        title: title,
        ar: ar,
        subtitle: subtitle,
        legend: legend,
        currency: currency,
        nodes: nodes ?? this.nodes,
        edges: edges ?? this.edges,
      );

  /// Serializes to `{ meta, nodes[], edges[] }` (matches the React export).
  Map<String, dynamic> toJson() => {
        'meta': {'title': title, 'currency': currency},
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  /// Rebuilds a graph from JSON. Edges without an `id` are assigned a stable
  /// index-based one so selection still works after an import.
  factory MapGraph.fromJson(
    Map<String, dynamic> j, {
    String id = 'imported',
    String title = 'Imported',
    String currency = 'SAR',
  }) {
    final meta = j['meta'] as Map<String, dynamic>?;
    final rawNodes = (j['nodes'] as List?) ?? const [];
    final rawEdges = (j['edges'] as List?) ?? const [];
    return MapGraph(
      id: id,
      title: (meta?['title'] as String?) ?? title,
      currency: (meta?['currency'] as String?) ?? currency,
      nodes: rawNodes
          .map((e) => MapNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      edges: [
        for (var i = 0; i < rawEdges.length; i++)
          MapEdge.fromJson(
            rawEdges[i] as Map<String, dynamic>,
            id: (rawEdges[i] as Map<String, dynamic>)['id'] as String? ?? 'e$i',
          ),
      ],
    );
  }
}
