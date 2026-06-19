// ============================================================
// example/lib/examples/07_validation.dart
// ------------------------------------------------------------
// Example 7 · Audit validation (v1.0.0). A deliberately broken settlement graph
// exercises every MapValidator check: a dangling edge, an orphan node, a
// directed cycle, and a flow imbalance where a node's incoming value sum does
// not equal its outgoing sum (the double-entry check).
//
// Press Validate in the toolbar — the issues panel lists every finding; tap a
// row to jump to the offending node / edge. The example also calls
// MapValidator.validate(...) directly to drive its own headline banner.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

/// A settlement graph with intentional integrity problems.
final MapGraph brokenGraph = MapGraph(
  id: 'broken-settlement',
  title: 'Inter-Account Settlement [TR-9042]',
  currency: 'SAR',
  legend: const [MapNodeKind.party, MapNodeKind.process, MapNodeKind.account],
  nodes: const [
    MapNode(id: 'src', x: 0, y: 0, label: 'Source Account', kind: MapNodeKind.account, value: 10000),
    MapNode(id: 'clear', x: 320, y: 0, label: 'Clearing', kind: MapNodeKind.process),
    MapNode(id: 'dst', x: 640, y: -120, label: 'Destination', kind: MapNodeKind.account),
    MapNode(id: 'fees', x: 640, y: 140, label: 'Fees', kind: MapNodeKind.process),
    // Orphan: connected to nothing.
    MapNode(id: 'orphan', x: 320, y: 320, label: 'Unlinked Note', kind: MapNodeKind.leaf),
  ],
  edges: const [
    // 10,000 in…
    MapEdge(id: 'e1', from: 'src', to: 'clear', value: 10000),
    // …but only 9,400 out → clearing is unbalanced by 600.
    MapEdge(id: 'e2', from: 'clear', to: 'dst', value: 9000),
    MapEdge(id: 'e3', from: 'clear', to: 'fees', value: 400),
    // Cycle: destination loops back into clearing.
    MapEdge(id: 'e4', from: 'dst', to: 'clear', value: 0),
    // Dangling: 'ghost' node does not exist.
    MapEdge(id: 'e5', from: 'fees', to: 'ghost', value: 400),
  ],
);

class ValidationExample extends StatefulWidget {
  const ValidationExample({super.key});

  @override
  State<ValidationExample> createState() => _ValidationExampleState();
}

class _ValidationExampleState extends State<ValidationExample> {
  late final SuperMapController _controller =
      SuperMapController(graph: brokenGraph, mode: MapMode.read);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    // Drive a headline banner straight from the usecase (no widgets needed).
    final summary = MapValidator.summarise(brokenGraph);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: t.border)),
        iconTheme: IconThemeData(color: t.fg2),
        title: Text('7 · Validation', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SuperTokens.space8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: t.tintFill(SuperTokens.warning, 0.10),
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
                    ),
                    child: Row(children: [
                      const Icon(Icons.report_problem_outlined, size: 16, color: SuperTokens.warning),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'MapValidator found ${summary.errors} error(s), '
                          '${summary.warnings} warning(s) and ${summary.infos} info note(s). '
                          'Press Validate to explore them.',
                          style: SuperText.caption.copyWith(fontSize: 12, color: t.fg2),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: SuperTokens.space6),
                  SuperMap(
                    controller: _controller,
                    height: 560,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
