// ============================================================
// example/lib/examples/08_auto_layout.dart
// ------------------------------------------------------------
// Example 8 · Auto-layout (v1.0.0). A scrambled order-to-cash graph with nodes
// at arbitrary coordinates. The Layout button in the toolbar (edit mode) offers
// layered / grid / radial; this page ALSO drives the same MapLayout usecase
// from its own buttons via controller.autoLayout(MapLayoutSpec(...)) so you can
// see each algorithm reshape the diagram. Locked nodes keep their position.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class AutoLayoutExample extends StatefulWidget {
  const AutoLayoutExample({super.key});

  @override
  State<AutoLayoutExample> createState() => _AutoLayoutExampleState();
}

class _AutoLayoutExampleState extends State<AutoLayoutExample> {
  // A messy DAG — coordinates are intentionally jumbled.
  late final SuperMapController _controller = SuperMapController(
    graph: MapGraph(
      id: 'scrambled-o2c',
      title: 'Order to Cash (scrambled)',
      currency: 'SAR',
      legend: const [MapNodeKind.process, MapNodeKind.document, MapNodeKind.payment],
      nodes: const [
        MapNode(id: 'order', x: 420, y: 280, label: 'Sales Order', kind: MapNodeKind.document),
        MapNode(id: 'pick', x: 80, y: 60, label: 'Pick & Pack', kind: MapNodeKind.process),
        MapNode(id: 'ship', x: 700, y: 120, label: 'Ship', kind: MapNodeKind.process),
        MapNode(id: 'invoice', x: 200, y: 360, label: 'Invoice', kind: MapNodeKind.document, value: 8400),
        MapNode(id: 'receipt', x: 560, y: 420, label: 'Cash Receipt', kind: MapNodeKind.payment, value: 8400),
      ],
      edges: const [
        MapEdge(id: 'e1', from: 'order', to: 'pick'),
        MapEdge(id: 'e2', from: 'pick', to: 'ship'),
        MapEdge(id: 'e3', from: 'ship', to: 'invoice'),
        MapEdge(id: 'e4', from: 'invoice', to: 'receipt', value: 8400),
      ],
    ),
    mode: MapMode.edit,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _layout(MapLayoutKind kind) =>
      _controller.autoLayout(MapLayoutSpec(kind: kind));

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
        title: Text('8 · Auto-layout', style: SuperText.heading.copyWith(color: t.fg1)),
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
                  Text('Tidy the scrambled diagram with one click. The toolbar Layout '
                      'button offers the same three algorithms.',
                      style: SuperText.body.copyWith(color: t.fg3)),
                  const SizedBox(height: SuperTokens.space4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SuperButton(
                        label: 'Layered',
                        icon: const Icon(Icons.account_tree_outlined),
                        onPressed: () => _layout(MapLayoutKind.layered),
                      ),
                      SuperButton(
                        label: 'Grid',
                        variant: SuperButtonVariant.secondary,
                        icon: const Icon(Icons.grid_view_rounded),
                        onPressed: () => _layout(MapLayoutKind.grid),
                      ),
                      SuperButton(
                        label: 'Radial',
                        variant: SuperButtonVariant.secondary,
                        icon: const Icon(Icons.blur_circular_outlined),
                        onPressed: () => _layout(MapLayoutKind.radial),
                      ),
                    ],
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
