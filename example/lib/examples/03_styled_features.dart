// ============================================================
// example/lib/examples/03_styled_features.dart
// ------------------------------------------------------------
// Example 3 · The v0.2.0 expressive features. A hand-built graph that uses
// per-node theme colours, text-labelled connections, and per-node notes,
// rendered as pills with orthogonal routing and the all-nodes data panel on.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class StyledFeaturesExample extends StatefulWidget {
  const StyledFeaturesExample({super.key});

  @override
  State<StyledFeaturesExample> createState() => _StyledFeaturesExampleState();
}

class _StyledFeaturesExampleState extends State<StyledFeaturesExample> {
  // Per-node `color` overrides the kind accent; `note` attaches a memo;
  // edges carry a text `label` naming the relationship.
  static const _graph = MapGraph(
    id: 'supply',
    title: 'Supply network',
    subtitle: 'Custom colours, labelled connections and notes — all v0.2.0.',
    legend: [MapNodeKind.party, MapNodeKind.hub, MapNodeKind.account],
    nodes: [
      MapNode(
        id: 'farm', x: 110, y: 110, label: 'Farms', kind: MapNodeKind.party,
        color: Color(0xFF1DB88A), sub: 'Source',
        note: 'Three contracted growers in the Eastern region. Audited quarterly.',
      ),
      MapNode(id: 'mill', x: 420, y: 110, label: 'Mill', kind: MapNodeKind.hub, color: Color(0xFFF97316), sub: 'Process'),
      MapNode(id: 'wh', x: 420, y: 300, label: 'Warehouse', kind: MapNodeKind.account, color: Color(0xFF0EA5E9), sub: 'Store',
        note: 'Cold-chain capacity is the bottleneck during peak season.'),
      MapNode(id: 'shop', x: 730, y: 110, label: 'Retail', kind: MapNodeKind.party, color: Color(0xFFA855F7), sub: 'Sell'),
      MapNode(id: 'export', x: 730, y: 300, label: 'Export', kind: MapNodeKind.party, color: Color(0xFF4A7CFF), sub: 'Sell'),
    ],
    edges: [
      MapEdge(id: 'e1', from: 'farm', to: 'mill', label: 'Raw crop'),
      MapEdge(id: 'e2', from: 'mill', to: 'wh', label: 'Packed'),
      MapEdge(id: 'e3', from: 'wh', to: 'shop', label: 'Distributes'),
      MapEdge(id: 'e4', from: 'wh', to: 'export', label: 'Ships'),
    ],
  );

  late final SuperMapController _controller = SuperMapController(
    graph: _graph,
    nodeStyle: MapNodeStyle.pill,
    edgeStyle: MapEdgeStyle.orthogonal,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: t.border)),
        iconTheme: IconThemeData(color: t.fg2),
        title: Text('3 · Colours · labels · notes', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SuperTokens.space8),
          child: SuperMap(
            controller: _controller,
            height: 520,
            showData: true,
          ),
        ),
      ),
    );
  }
}
