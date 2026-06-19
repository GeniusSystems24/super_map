// ============================================================
// core/utils/map_exporter.dart
// ------------------------------------------------------------
// Export helpers for SuperMap (v0.2.0). Turns a rendered canvas into a sharable
// artefact three ways:
//   • PNG  — rasterise a RepaintBoundary at a chosen pixel ratio (no deps).
//   • PDF  — embed that PNG, full-bleed, on an auto-orientation page (pkg:pdf).
//   • DOCX — wrap the PNG in a minimal Office-Open-XML document (pkg:archive).
//
// Every method returns raw bytes; how they are *saved* (share sheet, file
// picker, web download) is left to the host via SuperMap.onExport, so the
// package stays platform-agnostic. See README "Export" for wiring recipes.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/super_map/domain/entities/map_graph.dart';

/// The file format a SuperMap export produced.
enum MapExportFormat { png, pdf, docx, csv }

extension MapExportFormatX on MapExportFormat {
  /// The conventional extension (no dot).
  String get ext => switch (this) {
        MapExportFormat.png => 'png',
        MapExportFormat.pdf => 'pdf',
        MapExportFormat.docx => 'docx',
        MapExportFormat.csv => 'csv',
      };

  /// The MIME type a host should advertise when saving / sharing.
  String get mime => switch (this) {
        MapExportFormat.png => 'image/png',
        MapExportFormat.pdf => 'application/pdf',
        MapExportFormat.docx =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        MapExportFormat.csv => 'text/csv',
      };
}

/// Stateless export pipeline. Never instantiated.
abstract final class MapExporter {
  // ── CSV (v1.0.0) ──────────────────────────────────────────────────────────
  // Spreadsheet exports for the ERP / audit side of SuperMap. Two tables —
  // nodes and edges — each RFC-4180 quoted so labels, Arabic text and refs
  // survive commas, quotes and newlines. Western digits throughout.

  /// The node table as CSV text. Columns:
  /// `id,label,ar,kind,status,locked,ref,value,note,x,y`. [currency] (defaults
  /// to the graph's) is appended to the header's value column for clarity.
  static String nodesCsv(MapGraph graph) {
    final cur = graph.currency;
    final rows = <List<String>>[
      ['id', 'label', 'ar', 'kind', 'status', 'locked', 'ref', 'value ($cur)', 'note', 'x', 'y'],
      for (final n in graph.nodes)
        [
          n.id,
          n.label,
          n.ar ?? '',
          n.kind.name,
          n.status.isNone ? '' : n.status.name,
          n.locked ? 'true' : 'false',
          n.ref ?? '',
          n.value?.toStringAsFixed(2) ?? '',
          n.note ?? '',
          n.x.round().toString(),
          n.y.round().toString(),
        ],
    ];
    return _encodeCsv(rows);
  }

  /// The edge table as CSV text. Columns:
  /// `id,from,fromLabel,to,toLabel,label,value`.
  static String edgesCsv(MapGraph graph) {
    final byId = {for (final n in graph.nodes) n.id: n};
    final rows = <List<String>>[
      ['id', 'from', 'fromLabel', 'to', 'toLabel', 'label', 'value'],
      for (final e in graph.edges)
        [
          e.id,
          e.from,
          byId[e.from]?.label ?? '',
          e.to,
          byId[e.to]?.label ?? '',
          e.label ?? '',
          e.value?.toStringAsFixed(2) ?? '',
        ],
    ];
    return _encodeCsv(rows);
  }

  /// UTF-8 bytes for a CSV string, prefixed with a BOM so Excel opens Arabic
  /// columns in the correct encoding.
  static Uint8List csvBytes(String csv) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...const Utf8Encoder().convert(csv)]);

  static String _encodeCsv(List<List<String>> rows) =>
      rows.map((r) => r.map(_csvCell).join(',')).join('\r\n');

  static String _csvCell(String v) {
    final needsQuote =
        v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r');
    final escaped = v.replaceAll('"', '""');
    return needsQuote ? '"$escaped"' : escaped;
  }

  /// Rasterises the [RepaintBoundary] behind [boundaryKey] to PNG bytes at
  /// [pixelRatio] (2.0 ≈ retina). Returns null if the boundary isn't laid out.
  static Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    final ctx = boundaryKey.currentContext;
    final obj = ctx?.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    final ui.Image image = await obj.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  /// Wraps [png] (with its pixel [width]/[height]) into a single-page PDF whose
  /// orientation follows the image aspect, with a small [title] header.
  static Future<Uint8List> pngToPdf(
    Uint8List png, {
    required int width,
    required int height,
    String title = 'SuperMap',
  }) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    final landscape = width >= height;
    doc.addPage(
      pw.Page(
        pageFormat: (landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4)
            .copyWith(marginTop: 28, marginBottom: 28, marginLeft: 28, marginRight: 28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Expanded(child: pw.FittedBox(child: pw.Image(image))),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Builds a minimal `.docx` (Office Open XML) with [title] as a heading and
  /// [png] embedded as a full-width picture. Hand-assembled so it needs no Word
  /// toolchain — just a zip of the required parts.
  static Uint8List pngToDocx(
    Uint8List png, {
    required int width,
    required int height,
    String title = 'SuperMap',
  }) {
    // EMU = 914400 per inch; size the picture to ~6.3in wide, preserving ratio.
    const maxW = 5760000; // ~6.3in in EMU
    final emuW = maxW;
    final emuH = (maxW * height / (width == 0 ? 1 : width)).round();

    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    const contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Default Extension="png" ContentType="image/png"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';

    const rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';

    const docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>'
        '</Relationships>';

    final document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
        'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<w:body>'
        '<w:p><w:pPr><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:pPr>'
        '<w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t xml:space="preserve">${esc(title)}</w:t></w:r></w:p>'
        '<w:p><w:r><w:drawing>'
        '<wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="$emuW" cy="$emuH"/>'
        '<wp:docPr id="1" name="SuperMap"/>'
        '<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic><pic:nvPicPr><pic:cNvPr id="1" name="image1.png"/><pic:cNvPicPr/></pic:nvPicPr>'
        '<pic:blipFill><a:blip r:embed="rId1"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$emuW" cy="$emuH"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic>'
        '</a:graphicData></a:graphic></wp:inline>'
        '</w:drawing></w:r></w:p>'
        '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/></w:sectPr>'
        '</w:body></w:document>';

    final archive = Archive();
    void add(String name, List<int> bytes) =>
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
    final enc = const Utf8Encoder();
    add('[Content_Types].xml', enc.convert(contentTypes));
    add('_rels/.rels', enc.convert(rootRels));
    add('word/document.xml', enc.convert(document));
    add('word/_rels/document.xml.rels', enc.convert(docRels));
    add('word/media/image1.png', png);
    final zipped = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipped!);
  }
}
