// ============================================================
// example/lib/examples/09_csv_export.dart
// ------------------------------------------------------------
// Example 9 · CSV export (v1.0.0). MapExporter gains spreadsheet output for the
// ERP / audit side: nodesCsv(graph) and edgesCsv(graph) return RFC-4180 quoted
// tables (Arabic-safe), and csvBytes(...) wraps a string in a BOM-prefixed
// UTF-8 byte list ready to save or share. This page previews both tables; in a
// real app you would hand the bytes to a file picker, share sheet or download.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_map/super_map.dart';

class CsvExportExample extends StatefulWidget {
  const CsvExportExample({super.key});

  @override
  State<CsvExportExample> createState() => _CsvExportExampleState();
}

class _CsvExportExampleState extends State<CsvExportExample> {
  final MapGraph _graph = MapGraphData.accountingCycle;
  late String _csv = MapExporter.nodesCsv(_graph);
  bool _nodes = true;

  void _show(bool nodes) => setState(() {
        _nodes = nodes;
        _csv = nodes ? MapExporter.nodesCsv(_graph) : MapExporter.edgesCsv(_graph);
      });

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    // The bytes you would actually save (BOM-prefixed UTF-8 so Excel reads it).
    final bytes = MapExporter.csvBytes(_csv);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: t.border)),
        iconTheme: IconThemeData(color: t.fg2),
        title: Text('9 · CSV Export', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SuperTokens.space8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('MapExporter.nodesCsv / edgesCsv turn any MapGraph into an '
                      'audit-ready spreadsheet. ${bytes.length} bytes ready to save.',
                      style: SuperText.body.copyWith(color: t.fg3)),
                  const SizedBox(height: SuperTokens.space4),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    SuperButton(
                      label: 'Nodes table',
                      variant: _nodes ? SuperButtonVariant.primary : SuperButtonVariant.secondary,
                      icon: const Icon(Icons.table_rows_outlined),
                      onPressed: () => _show(true),
                    ),
                    SuperButton(
                      label: 'Edges table',
                      variant: !_nodes ? SuperButtonVariant.primary : SuperButtonVariant.secondary,
                      icon: const Icon(Icons.timeline_outlined),
                      onPressed: () => _show(false),
                    ),
                    SuperButton(
                      label: 'Copy CSV',
                      variant: SuperButtonVariant.secondary,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _csv));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV copied to clipboard')),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: SuperTokens.space6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SuperTokens.space4),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
                      boxShadow: t.cardShadow,
                    ),
                    child: SelectableText(
                      _csv,
                      style: SuperText.mono.copyWith(fontSize: 12, color: t.fg2, height: 1.5),
                    ),
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
