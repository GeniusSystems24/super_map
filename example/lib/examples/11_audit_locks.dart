// ============================================================
// example/lib/examples/11_audit_locks.dart
// ------------------------------------------------------------
// Example 11 · Audit locks (v1.0.0). In edit mode a node with locked == true is
// pinned: it cannot be dragged, re-kinded, recoloured or deleted, and the
// details panel shows a "Locked" pill plus an unlock toggle. This models posted
// / approved ERP records that must not change. Try to move or delete the locked
// "Posted" entries — SuperMap refuses and toasts "Node is locked". Use the
// lock toggle in the details panel to release one deliberately.
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

class AuditLocksExample extends StatefulWidget {
  const AuditLocksExample({super.key});

  @override
  State<AuditLocksExample> createState() => _AuditLocksExampleState();
}

class _AuditLocksExampleState extends State<AuditLocksExample> {
  late final SuperMapController _controller = SuperMapController(
    graph: MapGraph(
      id: 'ledger-locks',
      title: 'General Ledger — March',
      currency: 'SAR',
      legend: const [MapNodeKind.document, MapNodeKind.account],
      nodes: const [
        MapNode(
          id: 'open',
          x: 0,
          y: 0,
          label: 'Opening Balance',
          kind: MapNodeKind.account,
          status: MapNodeStatus.posted,
          locked: true,
          ref: 'GL-2024-1001',
          value: 120000,
          meta: {'Posted': '2024-03-01'},
        ),
        MapNode(
          id: 'jv1',
          x: 340,
          y: -120,
          label: 'Journal Entry 1',
          kind: MapNodeKind.document,
          status: MapNodeStatus.posted,
          locked: true,
          ref: 'JV-2024-0042',
          value: 5240,
        ),
        MapNode(
          id: 'jv2',
          x: 340,
          y: 120,
          label: 'Journal Entry 2 (draft)',
          kind: MapNodeKind.document,
          status: MapNodeStatus.draft,
          ref: 'JV-2024-0043',
          value: 980,
        ),
        MapNode(
          id: 'close',
          x: 680,
          y: 0,
          label: 'Running Balance',
          kind: MapNodeKind.account,
          value: 126220,
        ),
      ],
      edges: const [
        MapEdge(id: 'e1', from: 'open', to: 'close', value: 120000),
        MapEdge(id: 'e2', from: 'jv1', to: 'close', value: 5240),
        MapEdge(id: 'e3', from: 'jv2', to: 'close', value: 980),
      ],
    ),
    mode: MapMode.edit,
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
        title: Text('11 · Audit Locks', style: SuperText.heading.copyWith(color: t.fg1)),
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
                  Text('The two posted entries are locked (lock glyph on the card). Try to '
                      'drag or delete one — it refuses. Select it and use the lock toggle '
                      'in the details panel to release it.',
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
