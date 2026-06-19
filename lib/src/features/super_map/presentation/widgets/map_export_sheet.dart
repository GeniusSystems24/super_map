// ============================================================
// features/super_map/presentation/widgets/map_export_sheet.dart
// ------------------------------------------------------------
// The export chooser (v0.2.0): a small dialog offering Image (PNG) / PDF /
// Word (.docx). Each option rasterises the canvas via MapExporter, builds the
// chosen format, and hands the bytes back through [onExport] — the host decides
// how to persist them (share sheet, file picker, web download). A port in
// spirit of the React export dropdown.
// ============================================================

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Signature the host implements to save/share exported bytes.
typedef MapExportSaver = void Function(
    Uint8List bytes, String filename, MapExportFormat format);

/// Shows the export chooser. [boundaryKey] must wrap the canvas in a
/// RepaintBoundary; [title] seeds the filename and document heading.
Future<void> showMapExportSheet(
  BuildContext context, {
  required GlobalKey boundaryKey,
  required String title,
  required MapExportSaver onExport,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x80000000),
    builder: (_) => _MapExportSheet(
      boundaryKey: boundaryKey,
      title: title,
      onExport: onExport,
    ),
  );
}

class _MapExportSheet extends StatefulWidget {
  const _MapExportSheet({
    required this.boundaryKey,
    required this.title,
    required this.onExport,
  });

  final GlobalKey boundaryKey;
  final String title;
  final MapExportSaver onExport;

  @override
  State<_MapExportSheet> createState() => _MapExportSheetState();
}

class _MapExportSheetState extends State<_MapExportSheet> {
  bool _busy = false;
  String? _error;

  String get _safeName =>
      widget.title.toLowerCase().replaceAll(RegExp(r'[^\w-]+'), '-');

  Future<void> _run(MapExportFormat format) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final png =
          await MapExporter.capturePng(widget.boundaryKey, pixelRatio: 2.5);
      if (png == null) throw StateError('Canvas is not ready to capture.');
      // decode dimensions for correct PDF/DOCX sizing
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      final w = frame.image.width, h = frame.image.height;
      frame.image.dispose();

      Uint8List bytes;
      switch (format) {
        case MapExportFormat.png:
          bytes = png;
        case MapExportFormat.pdf:
          bytes = await MapExporter.pngToPdf(png,
              width: w, height: h, title: widget.title);
        case MapExportFormat.docx:
          bytes = MapExporter.pngToDocx(png,
              width: w, height: h, title: widget.title);
        case MapExportFormat.csv:
          throw UnsupportedError(
              'CSV export is not available from this sheet.');
      }
      if (!mounted) return;
      widget.onExport(bytes, '$_safeName.${format.ext}', format);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Center(
      child: Material(
        color: const Color(0x00000000),
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.borderStrong),
            borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
            boxShadow: SuperThemeData.popShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 12, 13),
                child: Row(
                  children: [
                    const Icon(Icons.ios_share_rounded,
                        size: 16, color: SuperTokens.accent),
                    const SizedBox(width: 10),
                    Text('Export diagram',
                        style: SuperText.heading
                            .copyWith(fontSize: 15, color: t.fg1)),
                    const Spacer(),
                    SuperIconButton(
                        icon: Icons.close_rounded,
                        onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              const Hairline(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _ExportOption(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      sub: 'PNG · raster snapshot',
                      onTap: () => _run(MapExportFormat.png),
                    ),
                    const SizedBox(height: 8),
                    _ExportOption(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF document',
                      sub: 'Vector page, auto-orientation',
                      onTap: () => _run(MapExportFormat.pdf),
                    ),
                    const SizedBox(height: 8),
                    _ExportOption(
                      icon: Icons.description_outlined,
                      label: 'Word document',
                      sub: '.docx · drops into a report',
                      onTap: () => _run(MapExportFormat.docx),
                    ),
                  ],
                ),
              ),
              if (_busy || _error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: _busy
                      ? Row(children: [
                          const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text('Rendering…',
                              style: SuperText.caption.copyWith(color: t.fg3)),
                        ])
                      : Text(_error!,
                          style: SuperText.caption
                              .copyWith(color: SuperTokens.danger)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportOption extends StatefulWidget {
  const _ExportOption({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  State<_ExportOption> createState() => _ExportOptionState();
}

class _ExportOptionState extends State<_ExportOption> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _hover ? t.hover : t.inputBg,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.tintFill(SuperTokens.accent, 0.14),
                  borderRadius:
                      BorderRadius.circular(SuperTokens.radiusControl),
                ),
                child: Icon(widget.icon, size: 18, color: SuperTokens.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: SuperText.body.copyWith(
                            fontWeight: FontWeight.w700, color: t.fg1)),
                    Text(widget.sub,
                        style: SuperText.caption.copyWith(color: t.fg3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: t.fg4),
            ],
          ),
        ),
      ),
    );
  }
}
