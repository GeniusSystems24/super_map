// ============================================================
// features/super_map/domain/entities/map_node.dart
// ------------------------------------------------------------
// The node-graph data model — a faithful port of the React super-map tool.
// A [MapNode] is a positioned card in an abstract world space; a [MapEdge] is a
// directed connection between two nodes. [MapNodeKind] enumerates the 15 node
// kinds (each with a brand color, an icon and a human tag). Pure data — no
// Flutter widgets, only `Color`/`IconData` value types from the foundation.
// ============================================================

import 'package:flutter/material.dart';

import 'package:super_core/super_core.dart';

/// The kind of a [MapNode] — drives its accent color, icon and tag. Ported 1:1
/// from the React `KIND` table. Neutral kinds (`leaf`, `document`) carry a null
/// color and resolve to the theme's tertiary foreground at render time so they
/// read correctly in both light and dark.
enum MapNodeKind {
  income(SuperTokens.success, Icons.bar_chart_rounded, 'Income'),
  hub(SuperTokens.accent, Icons.hub_outlined, 'Entity'),
  expense(SuperTokens.danger, Icons.call_split_rounded, 'Expense'),
  equity(_violet, Icons.verified_outlined, 'Equity'),
  topic(SuperTokens.accent, Icons.tag_rounded, 'Topic'),
  branch(SuperTokens.warning, Icons.folder_open_rounded, 'Branch'),
  leaf(null, Icons.description_outlined, 'Idea'),
  process(SuperTokens.accent, Icons.bolt_rounded, 'Process'),
  role(_sky, Icons.person_outline_rounded, 'Role'),
  approval(SuperTokens.warning, Icons.check_circle_outline_rounded, 'Approval'),
  document(null, Icons.insert_drive_file_outlined, 'Document'),
  account(SuperTokens.success, Icons.menu_book_outlined, 'Account'),
  statement(_violet, Icons.receipt_long_outlined, 'Statement'),
  party(SuperTokens.accent, Icons.people_outline_rounded, 'Party'),
  payment(SuperTokens.success, Icons.payments_outlined, 'Payment');

  const MapNodeKind(this._color, this.icon, this.tag);

  static const Color _violet = Color(0xFFA855F7);
  static const Color _sky = Color(0xFF0EA5E9);

  /// The raw accent color, or null for neutral kinds (resolved by [colorOf]).
  final Color? _color;

  /// The line icon shown on the node card / details panel.
  final IconData icon;

  /// The human-readable tag rendered in the details-panel pill.
  final String tag;

  /// The accent color for this kind, theme-aware for neutral kinds.
  Color colorOf(SuperThemeData t) => _color ?? t.fg3;

  /// Looks a kind up by its serialized name, falling back to [leaf].
  static MapNodeKind fromName(String? name) =>
      values.firstWhere((k) => k.name == name, orElse: () => leaf);
}

/// The workflow / lifecycle state of a [MapNode] — an ERP-grade overlay on top
/// of its [MapNodeKind] (v1.0.0). A node keeps its semantic kind (what it *is*)
/// while [MapNodeStatus] tracks where it *stands* in a process: a journal entry
/// is a `document` kind that moves `draft → pending → posted`; a purchase line
/// is a `process` kind that moves `pending → approved`/`rejected`. Drives a
/// small status dot on the card and a status pill in the details panel. Neutral
/// states carry a null color and resolve against the theme.
enum MapNodeStatus {
  none(null, ''),
  draft(null, 'Draft'),
  pending(SuperTokens.warning, 'Pending'),
  approved(SuperTokens.success, 'Approved'),
  posted(SuperTokens.accent, 'Posted'),
  rejected(SuperTokens.danger, 'Rejected'),
  onHold(_holdViolet, 'On Hold');

  const MapNodeStatus(this._color, this.tag);

  static const Color _holdViolet = Color(0xFFA855F7);

  /// The raw status color, or null for the neutral `none` / `draft` states.
  final Color? _color;

  /// The human-readable label rendered in the status pill.
  final String tag;

  /// True for the default, unset state (no badge is drawn).
  bool get isNone => this == MapNodeStatus.none;

  /// The status color, theme-aware for neutral states.
  Color colorOf(SuperThemeData t) => _color ?? t.fg3;

  /// Looks a status up by its serialized name, falling back to [none].
  static MapNodeStatus fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => none);
}

/// One node in a [MapNode] graph. Carries a world position ([x], [y] — the
/// center of the card), an English [label], an optional Arabic [ar] label, an
/// optional uppercase [sub] caption, a [kind], and an optional numeric [value].
@immutable
class MapNode {
  const MapNode({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    this.ar,
    this.sub,
    this.kind = MapNodeKind.leaf,
    this.value,
    this.color,
    this.note,
    this.status = MapNodeStatus.none,
    this.locked = false,
    this.ref,
    this.meta,
  });

  /// Stable unique id — the selection key and the edge endpoint reference.
  final String id;

  /// World-space center coordinates (the engine fits them to the viewport).
  final double x;
  final double y;

  /// Primary (English / LTR) label.
  final String label;

  /// Optional secondary Arabic label, rendered RTL beneath [label] on cards.
  final String? ar;

  /// Optional uppercase caption shown under the label when there is no [ar].
  final String? sub;

  /// The node's kind — drives color, icon and tag.
  final MapNodeKind kind;

  /// Optional numeric metric (e.g. a balance) — surfaced in the details panel.
  final double? value;

  /// Optional per-node theme color that overrides the [kind] accent. Lets a
  /// single node be re-colored without changing its semantic kind (v0.2.0).
  final Color? color;

  /// Optional free-text memo attached to the node, revealed via the node's note
  /// button and the details panel (v0.2.0).
  final String? note;

  /// Workflow / lifecycle state — an ERP overlay on top of [kind] (v1.0.0).
  /// Defaults to [MapNodeStatus.none] (no badge).
  final MapNodeStatus status;

  /// When true the node is audit-locked: it cannot be moved, re-kinded,
  /// recolored or deleted in edit mode (v1.0.0). Use for posted / approved
  /// records that must not change. Shown with a small lock glyph.
  final bool locked;

  /// Optional reference to the source ERP record this node stands for — a
  /// serial / document id such as `JV-2024-0042` or `INV-ISS-2024-0089`
  /// (v1.0.0). Rendered monospace in the details panel.
  final String? ref;

  /// Optional ordered audit metadata (key → value) surfaced as rows in the
  /// details panel — e.g. `{'Posted': '2024-03-14', 'By': 'A. Salem'}`
  /// (v1.0.0). Values are strings; keep them short.
  final Map<String, String>? meta;

  /// The world-space center as an [Offset].
  Offset get center => Offset(x, y);

  /// The effective accent for this node: the custom [color] when set, otherwise
  /// the theme-aware [kind] color.
  Color accentOf(SuperThemeData t) => color ?? kind.colorOf(t);

  MapNode copyWith({
    double? x,
    double? y,
    String? label,
    String? ar,
    String? sub,
    MapNodeKind? kind,
    double? value,
    Object? color = _unset,
    Object? note = _unset,
    MapNodeStatus? status,
    bool? locked,
    Object? ref = _unset,
    Object? meta = _unset,
  }) =>
      MapNode(
        id: id,
        x: x ?? this.x,
        y: y ?? this.y,
        label: label ?? this.label,
        ar: ar ?? this.ar,
        sub: sub ?? this.sub,
        kind: kind ?? this.kind,
        value: value ?? this.value,
        color: color == _unset ? this.color : color as Color?,
        note: note == _unset ? this.note : note as String?,
        status: status ?? this.status,
        locked: locked ?? this.locked,
        ref: ref == _unset ? this.ref : ref as String?,
        meta: meta == _unset ? this.meta : meta as Map<String, String>?,
      );

  /// Serializes to the round-trippable JSON shape `{ id, x, y, label, ar?,
  /// kind, sub?, value?, color?, note?, status?, locked?, ref?, meta? }`.
  /// [color] is written as a `#RRGGBB` hex string.
  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x.round(),
        'y': y.round(),
        'label': label,
        if (ar != null) 'ar': ar,
        'kind': kind.name,
        if (sub != null) 'sub': sub,
        if (value != null) 'value': value,
        if (color != null) 'color': _hex(color!),
        if (note != null) 'note': note,
        if (status != MapNodeStatus.none) 'status': status.name,
        if (locked) 'locked': true,
        if (ref != null) 'ref': ref,
        if (meta != null && meta!.isNotEmpty) 'meta': meta,
      };

  factory MapNode.fromJson(Map<String, dynamic> j) => MapNode(
        id: j['id'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        label: (j['label'] as String?) ?? 'Node',
        ar: j['ar'] as String?,
        sub: j['sub'] as String?,
        kind: MapNodeKind.fromName(j['kind'] as String?),
        value: (j['value'] as num?)?.toDouble(),
        color: _parseColor(j['color']),
        note: j['note'] as String?,
        status: MapNodeStatus.fromName(j['status'] as String?),
        locked: j['locked'] == true,
        ref: j['ref'] as String?,
        meta: _parseMeta(j['meta']),
      );

  static const Object _unset = Object();
  static String _hex(Color c) =>
      '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  static Color? _parseColor(Object? v) {
    if (v is! String || v.isEmpty) return null;
    final s = v.startsWith('#') ? v.substring(1) : v;
    final n = int.tryParse(s, radix: 16);
    if (n == null) return null;
    return Color(s.length <= 6 ? (0xFF000000 | n) : n);
  }

  static Map<String, String>? _parseMeta(Object? v) {
    if (v is! Map) return null;
    final out = <String, String>{};
    v.forEach((k, val) => out['$k'] = '$val');
    return out.isEmpty ? null : out;
  }

  @override
  bool operator ==(Object other) => other is MapNode && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A directed connection between two [MapNode]s, with an optional numeric
/// [value] (rendered as a pill at the edge midpoint).
@immutable
class MapEdge {
  const MapEdge({
    required this.id,
    required this.from,
    required this.to,
    this.value,
    this.label,
  });

  /// Stable unique id — the selection key.
  final String id;

  /// Source node id.
  final String from;

  /// Target node id (the arrowhead points here).
  final String to;

  /// Optional numeric value carried by the connection.
  final double? value;

  /// Optional free-text label rendered on the connection to name its meaning
  /// (e.g. "Revenue", "Settles") — v0.2.0.
  final String? label;

  MapEdge copyWith({Object? value = _unset, Object? label = _unset}) => MapEdge(
        id: id,
        from: from,
        to: to,
        value: value == _unset ? this.value : value as double?,
        label: label == _unset ? this.label : label as String?,
      );

  static const Object _unset = Object();

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        if (value != null) 'value': value,
        if (label != null) 'label': label,
      };

  factory MapEdge.fromJson(Map<String, dynamic> j, {required String id}) => MapEdge(
        id: id,
        from: j['from'] as String,
        to: j['to'] as String,
        value: (j['value'] as num?)?.toDouble(),
        label: j['label'] as String?,
      );

  @override
  bool operator ==(Object other) => other is MapEdge && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
