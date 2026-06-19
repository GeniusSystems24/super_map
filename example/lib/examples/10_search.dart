// ============================================================
// example/lib/examples/10_search.dart
// ------------------------------------------------------------
// Example 10 · Node search (v1.0.0). The toolbar search field filters across a
// node's label, Arabic name, sub-title, ref, note, kind, status and value.
// Matching nodes stay lit; everything else dims so a single record is easy to
// find in a dense diagram. The controller exposes the same surface
// programmatically: setQuery(...), matches and hasQuery — used here to drive a
// live match counter above the canvas.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class SearchExample extends StatefulWidget {
  const SearchExample({super.key});

  @override
  State<SearchExample> createState() => _SearchExampleState();
}

class _SearchExampleState extends State<SearchExample> {
  late final SuperMapController _controller =
      SuperMapController(graph: MapGraphData.cashFlow, mode: MapMode.read);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final c = _controller;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: t.border)),
        iconTheme: IconThemeData(color: t.fg2),
        title: Text('10 · Node Search', style: SuperText.heading.copyWith(color: t.fg1)),
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
                  Row(children: [
                    Expanded(
                      child: Text('Type in the toolbar search (try "income" or "payroll"). '
                          'Or drive it from chrome with the quick chips below.',
                          style: SuperText.body.copyWith(color: t.fg3)),
                    ),
                    if (c.hasQuery)
                      Text('${c.matches.length} match(es)',
                          style: SuperText.mono.copyWith(fontSize: 12, color: SuperTokens.accent)),
                  ]),
                  const SizedBox(height: SuperTokens.space3),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final q in const ['income', 'expense', 'payroll', 'GeniusLink'])
                      SuperButton(
                        label: q,
                        variant: c.query == q ? SuperButtonVariant.primary : SuperButtonVariant.secondary,
                        onPressed: () => c.setQuery(q),
                      ),
                    SuperButton(
                      label: 'Clear',
                      variant: SuperButtonVariant.secondary,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: c.clearQuery,
                    ),
                  ]),
                  const SizedBox(height: SuperTokens.space6),
                  SuperMap(
                    controller: c,
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
