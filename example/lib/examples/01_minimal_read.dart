// ============================================================
// example/lib/examples/01_minimal_read.dart
// ------------------------------------------------------------
// Example 1 · The shortest path. Build a tiny MapGraph, hand it to a
// SuperMapController in read mode, drop a SuperMap into the tree. Pan, zoom,
// drag and tap to inspect — no edit chrome.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class MinimalReadExample extends StatefulWidget {
  const MinimalReadExample({super.key});

  @override
  State<MinimalReadExample> createState() => _MinimalReadExampleState();
}

class _MinimalReadExampleState extends State<MinimalReadExample> {
  // A three-node graph: a request flows to a reviewer, then to an approver.
  static const _graph = MapGraph(
    id: 'mini',
    title: 'Approval (mini)',
    subtitle: 'Three nodes, read-only. Drag to rearrange, tap to inspect.',
    legend: [MapNodeKind.process, MapNodeKind.role, MapNodeKind.approval],
    nodes: [
      MapNode(id: 'req', x: 120, y: 160, label: 'Request', kind: MapNodeKind.process, sub: 'Start'),
      MapNode(id: 'rev', x: 380, y: 160, label: 'Reviewer', kind: MapNodeKind.role, sub: 'Checks'),
      MapNode(id: 'apr', x: 640, y: 160, label: 'Approved', kind: MapNodeKind.approval, sub: 'Done'),
    ],
    edges: [
      MapEdge(id: 'e1', from: 'req', to: 'rev'),
      MapEdge(id: 'e2', from: 'rev', to: 'apr'),
    ],
  );

  late final SuperMapController _controller =
      SuperMapController(graph: _graph); // defaults to read mode

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
        title: Text('1 · Minimal (read)', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SuperTokens.space8),
          // The toolbar is hidden — this is a pure, read-only view.
          child: SuperMap(
            controller: _controller,
            height: 460,
            showToolbar: false,
          ),
        ),
      ),
    );
  }
}
