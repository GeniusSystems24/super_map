// ============================================================
// example/lib/examples/04_controller_driven.dart
// ------------------------------------------------------------
// Example 4 · Drive SuperMap from the outside. The SuperMapController is a
// plain ChangeNotifier, so app chrome can call its intent methods directly
// (add nodes, label edges, recolour, fit) and listen for the live selection.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class ControllerDrivenExample extends StatefulWidget {
  const ControllerDrivenExample({super.key});

  @override
  State<ControllerDrivenExample> createState() => _ControllerDrivenExampleState();
}

class _ControllerDrivenExampleState extends State<ControllerDrivenExample> {
  static const _graph = MapGraph(
    id: 'svc',
    title: 'Services',
    legend: [MapNodeKind.hub, MapNodeKind.process],
    nodes: [
      MapNode(id: 'gw', x: 140, y: 200, label: 'Gateway', kind: MapNodeKind.hub),
      MapNode(id: 'a', x: 420, y: 120, label: 'Service A', kind: MapNodeKind.process),
      MapNode(id: 'b', x: 420, y: 280, label: 'Service B', kind: MapNodeKind.process),
    ],
    edges: [
      MapEdge(id: 'e1', from: 'gw', to: 'a', label: 'routes'),
      MapEdge(id: 'e2', from: 'gw', to: 'b', label: 'routes'),
    ],
  );

  late final SuperMapController _controller =
      SuperMapController(graph: _graph, mode: MapMode.edit);
  int _n = 0;

  @override
  void initState() {
    super.initState();
    // React to selection changes coming from inside the canvas.
    _controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  void _addService() {
    // Place a node in the current view centre and connect it to the gateway.
    final id = _controller.addNodeAt(Offset(700, 120.0 + _n * 90), kind: MapNodeKind.process);
    _controller.commitRename('Service ${String.fromCharCode(67 + _n)}');
    _controller.addEdge('gw', id);
    _controller.setEdgeLabel(_controller.edges.last.id, 'routes');
    _n++;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final sel = _controller.selectedNode;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: t.border)),
        iconTheme: IconThemeData(color: t.fg2),
        title: Text('4 · Controller-driven', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SuperTokens.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: SuperTokens.space3,
                runSpacing: SuperTokens.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SuperButton(label: 'Add service', icon: const Icon(Icons.add_rounded), onPressed: _addService),
                  SuperButton(
                    label: 'Recolour selection',
                    variant: SuperButtonVariant.secondary,
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: sel == null ? null : () => _controller.setNodeColor(sel.id, const Color(0xFFA855F7)),
                  ),
                  SuperButton(
                    label: 'Undo',
                    variant: SuperButtonVariant.secondary,
                    icon: const Icon(Icons.undo_rounded),
                    onPressed: _controller.canUndo ? _controller.undo : null,
                  ),
                  Text(
                    sel == null ? 'Nothing selected' : 'Selected: ${sel.label}',
                    style: SuperText.caption.copyWith(color: t.fg3),
                  ),
                ],
              ),
              const SizedBox(height: SuperTokens.space6),
              SuperMap(controller: _controller, height: 500, showToolbar: false, showData: true),
            ],
          ),
        ),
      ),
    );
  }
}
