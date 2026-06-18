// ============================================================
// example/lib/examples/02_editable_export.dart
// ------------------------------------------------------------
// Example 2 · Edit mode + export. Opens a bundled seed in edit mode and wires
// SuperMap.onExport to the `printing` package so the Image / PDF / Word bytes
// produced by MapExporter are actually shared / downloaded on every platform.
// ============================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:super_map/super_map.dart';

class EditableExportExample extends StatefulWidget {
  const EditableExportExample({super.key});

  @override
  State<EditableExportExample> createState() => _EditableExportExampleState();
}

class _EditableExportExampleState extends State<EditableExportExample> {
  late final SuperMapController _controller = SuperMapController(
    graph: MapGraphData.cashFlow,
    mode: MapMode.edit,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // SuperMap hands us the finished bytes + a suggested filename + the format.
  // Here we use `printing` (works on mobile, desktop and web) to share/save.
  void _onExport(Uint8List bytes, String filename, MapExportFormat format) {
    Printing.sharePdf(bytes: bytes, filename: filename);
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
        title: Text('2 · Editable + Export', style: SuperText.heading.copyWith(color: t.fg1)),
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
                  Text('Edit the diagram, then use Export → Image / PDF / Word.',
                      style: SuperText.body.copyWith(color: t.fg3)),
                  const SizedBox(height: SuperTokens.space6),
                  SuperMap(
                    controller: _controller,
                    height: 560,
                    showData: true,
                    onExport: _onExport,
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
