// ============================================================
// example/lib/examples/05_json_driven.dart
// ------------------------------------------------------------
// Example 5 · Data in, diagram out. A graph defined entirely as JSON is parsed
// with MapGraph.fromJson and rendered — the same shape SuperMap exports, so any
// stored / API-fetched diagram round-trips. Includes v0.2.0 colour, note and
// edge-label fields.
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class JsonDrivenExample extends StatefulWidget {
  const JsonDrivenExample({super.key});

  @override
  State<JsonDrivenExample> createState() => _JsonDrivenExampleState();
}

class _JsonDrivenExampleState extends State<JsonDrivenExample> {
  // The exact JSON shape SuperMap reads & writes: { meta, nodes[], edges[] }.
  static const _json = '''
{
  "meta": { "title": "Org chart" },
  "nodes": [
    { "id": "ceo", "x": 380, "y": 80,  "label": "CEO",        "kind": "role",    "color": "#A855F7", "note": "Final sign-off authority." },
    { "id": "cfo", "x": 200, "y": 240, "label": "Finance",    "kind": "role",    "sub": "Dept" },
    { "id": "cto", "x": 560, "y": 240, "label": "Technology", "kind": "role",    "sub": "Dept" },
    { "id": "acc", "x": 200, "y": 400, "label": "Accounting", "kind": "account", "value": 12 },
    { "id": "eng", "x": 560, "y": 400, "label": "Engineering","kind": "process", "value": 34 }
  ],
  "edges": [
    { "from": "ceo", "to": "cfo", "label": "reports" },
    { "from": "ceo", "to": "cto", "label": "reports" },
    { "from": "cfo", "to": "acc", "label": "owns" },
    { "from": "cto", "to": "eng", "label": "owns" }
  ]
}
''';

  late final SuperMapController _controller = SuperMapController(
    graph: MapGraph.fromJson(
      jsonDecode(_json) as Map<String, dynamic>,
      id: 'org',
      title: 'Org chart',
    ),
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
        title: Text('5 · JSON-driven', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SuperTokens.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Parsed from a JSON string via MapGraph.fromJson. '
                  'Open the JSON button to see it round-trip.',
                  style: SuperText.body.copyWith(color: t.fg3)),
              const SizedBox(height: SuperTokens.space6),
              SuperMap(controller: _controller, height: 500),
            ],
          ),
        ),
      ),
    );
  }
}
