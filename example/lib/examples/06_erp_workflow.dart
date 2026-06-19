// ============================================================
// example/lib/examples/06_erp_workflow.dart
// ------------------------------------------------------------
// Example 6 · ERP workflow overlay (v1.0.0). A journal-entry approval chain
// built from scratch, showing the new node fields: a workflow MapNodeStatus
// (the status dot on the card + the status pill in the details panel), an
// audit-locked "Posted" record, a source-record `ref` (JV-2024-0042) and an
// audit `meta` map — all formatted against the graph's `currency` (SAR).
//
// Open a node (tap it) to see the status pill, the monospace ref and the meta
// rows in the details panel.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

/// A small opening-journal-entry approval flow, GeniusLink-style.
final MapGraph erpWorkflowGraph = MapGraph(
  id: 'jv-approval',
  title: 'Opening Journal Entry قيد افتتاحي',
  currency: 'SAR',
  legend: const [MapNodeKind.document, MapNodeKind.approval, MapNodeKind.account],
  nodes: const [
    MapNode(
      id: 'draft',
      x: 0,
      y: 0,
      label: 'Draft Entry',
      ar: 'مسودة القيد',
      kind: MapNodeKind.document,
      status: MapNodeStatus.draft,
      ref: 'JV-2024-0042',
      value: 5240,
      meta: {'Created': '2024-03-12', 'By': 'A. Salem'},
    ),
    MapNode(
      id: 'review',
      x: 320,
      y: -120,
      label: 'Manager Review',
      ar: 'مراجعة المدير',
      kind: MapNodeKind.approval,
      status: MapNodeStatus.pending,
      meta: {'Queue': 'Finance', 'SLA': '24h'},
    ),
    MapNode(
      id: 'approved',
      x: 640,
      y: 0,
      label: 'Approved',
      ar: 'معتمد',
      kind: MapNodeKind.approval,
      status: MapNodeStatus.approved,
      meta: {'Approved': '2024-03-14', 'By': 'M. Idris'},
    ),
    MapNode(
      id: 'posted',
      x: 960,
      y: 0,
      label: 'Posted to Ledger',
      ar: 'مرحّل للدفتر',
      kind: MapNodeKind.account,
      status: MapNodeStatus.posted,
      locked: true, // audit-locked: cannot be moved / edited / deleted
      ref: 'GL-2024-1180',
      value: 5240,
      meta: {'Posted': '2024-03-14', 'Period': 'FY24-Q1'},
    ),
  ],
  edges: const [
    MapEdge(id: 'e1', from: 'draft', to: 'review', value: 5240),
    MapEdge(id: 'e2', from: 'review', to: 'approved'),
    MapEdge(id: 'e3', from: 'approved', to: 'posted', value: 5240),
  ],
);

class ErpWorkflowExample extends StatefulWidget {
  const ErpWorkflowExample({super.key});

  @override
  State<ErpWorkflowExample> createState() => _ErpWorkflowExampleState();
}

class _ErpWorkflowExampleState extends State<ErpWorkflowExample> {
  late final SuperMapController _controller =
      SuperMapController(graph: erpWorkflowGraph, mode: MapMode.read);

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
        title: Text('6 · ERP Workflow', style: SuperText.heading.copyWith(color: t.fg1)),
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
                  Text('Draft → Pending → Approved → Posted. Tap a node to inspect its '
                      'status, source ref and audit metadata. The Posted record is locked.',
                      style: SuperText.body.copyWith(color: t.fg3)),
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
