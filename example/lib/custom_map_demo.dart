// ============================================================
// example/lib/custom_map_demo.dart
// ------------------------------------------------------------
// The shortest path to a working SuperMap: build a MapGraph by hand, hand it to
// a SuperMapController, and drop a SuperMap into the tree. Shows a tiny
// microservice topology — no bundled data involved.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

const _graph = MapGraph(
  id: 'services',
  title: 'Service topology',
  subtitle: 'A small microservice graph — the gateway fans out to services that share a database and a cache.',
  legend: [MapNodeKind.hub, MapNodeKind.process, MapNodeKind.account],
  nodes: [
    MapNode(id: 'gw', x: 120, y: 240, label: 'API Gateway', kind: MapNodeKind.hub, sub: 'Edge'),
    MapNode(id: 'auth', x: 420, y: 90, label: 'Auth Service', kind: MapNodeKind.process, sub: 'gRPC'),
    MapNode(id: 'orders', x: 420, y: 240, label: 'Orders Service', kind: MapNodeKind.process, sub: 'gRPC'),
    MapNode(id: 'billing', x: 420, y: 390, label: 'Billing Service', kind: MapNodeKind.process, sub: 'gRPC'),
    MapNode(id: 'db', x: 740, y: 165, label: 'Postgres', kind: MapNodeKind.account, sub: 'Primary'),
    MapNode(id: 'cache', x: 740, y: 320, label: 'Redis', kind: MapNodeKind.account, sub: 'Cache'),
  ],
  edges: [
    MapEdge(id: 'e1', from: 'gw', to: 'auth'),
    MapEdge(id: 'e2', from: 'gw', to: 'orders'),
    MapEdge(id: 'e3', from: 'gw', to: 'billing'),
    MapEdge(id: 'e4', from: 'orders', to: 'db'),
    MapEdge(id: 'e5', from: 'billing', to: 'db'),
    MapEdge(id: 'e6', from: 'orders', to: 'cache'),
    MapEdge(id: 'e7', from: 'auth', to: 'cache'),
  ],
);

class CustomMapDemo extends StatefulWidget {
  const CustomMapDemo({super.key});

  @override
  State<CustomMapDemo> createState() => _CustomMapDemoState();
}

class _CustomMapDemoState extends State<CustomMapDemo> {
  late final SuperMapController _controller =
      SuperMapController(graph: _graph, mode: MapMode.edit);

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
        title: Text('Custom Graph', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SuperTokens.space8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_graph.title, style: SuperText.h1.copyWith(color: t.fg1)),
                  const SizedBox(height: SuperTokens.space2),
                  Text(_graph.subtitle!, style: SuperText.body.copyWith(color: t.fg3)),
                  const SizedBox(height: SuperTokens.space6),
                  SuperMap(controller: _controller, height: 520),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
