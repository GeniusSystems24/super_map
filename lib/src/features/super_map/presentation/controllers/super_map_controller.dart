// ============================================================
// features/super_map/presentation/controllers/super_map_controller.dart
// ------------------------------------------------------------
// The MVC controller for SuperMap — the single source of truth a thin View
// renders and forwards events to. A faithful port of the React component's hook
// state: the view transform (pan offset + zoom), the live nodes + edges,
// selection (node / edge), hover, the in-progress rename and link drafts, the
// read/edit mode, the node/edge render styles, an undo history (depth 40), and
// a transient toast. Every mutation is expressed as a widget-free intent
// method; the controller never imports a Flutter widget.
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size, Rect, Color;

import '../../domain/entities/map_graph.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/usecases/map_logic.dart';
import '../../domain/usecases/map_layout.dart';
import '../../domain/usecases/map_validator.dart';

/// Read vs. edit interaction mode.
enum MapMode { read, edit }

/// What is currently selected on the canvas.
enum MapSelectionType { node, edge }

/// A live selection — a [type] and the selected entity [id].
@immutable
class MapSelection {
  const MapSelection(this.type, this.id);
  final MapSelectionType type;
  final String id;
}

/// An in-progress connection drag from a node port.
@immutable
class LinkDraft {
  const LinkDraft({
    required this.fromId,
    required this.side,
    required this.cursor,
    this.click = false,
  });

  /// The source node id.
  final String fromId;

  /// The side the drag started from.
  final NodeSide side;

  /// The current cursor position in world space.
  final Offset cursor;

  /// True when started via the context-menu "Connect from here" (click-to-drop)
  /// rather than a pointer drag.
  final bool click;

  LinkDraft copyWith({Offset? cursor}) =>
      LinkDraft(fromId: fromId, side: side, cursor: cursor ?? this.cursor, click: click);
}

class _Snapshot {
  const _Snapshot(this.nodes, this.edges);
  final List<MapNode> nodes;
  final List<MapEdge> edges;
}

class SuperMapController extends ChangeNotifier {
  SuperMapController({
    required MapGraph graph,
    MapMode mode = MapMode.read,
    MapNodeStyle nodeStyle = MapNodeStyle.card,
    MapEdgeStyle edgeStyle = MapEdgeStyle.curved,
    this.onSelectNode,
  })  : _seed = graph,
        _mode = mode,
        _nodeStyle = nodeStyle,
        _edgeStyle = edgeStyle {
    _apply(graph);
  }

  /// Optional host hook fired whenever a node is selected (inspect / open).
  final void Function(MapNode node)? onSelectNode;

  MapGraph _seed;
  MapMode _mode;
  MapNodeStyle _nodeStyle;
  MapEdgeStyle _edgeStyle;

  List<MapNode> _nodes = const [];
  List<MapEdge> _edges = const [];
  Offset _offset = Offset.zero;
  double _scale = 1;

  MapSelection? _selection;
  String? _hoverId;
  String? _editingId;
  String? _editingEdgeId;
  LinkDraft? _link;
  String? _toast;
  int _toastTick = 0;
  bool _pendingFit = false;
  String _query = '';
  List<MapIssue> _issues = const [];

  final List<_Snapshot> _history = [];
  int _uid = 0;

  // ── reads ──
  MapGraph get seed => _seed;
  MapMode get mode => _mode;
  bool get isEdit => _mode == MapMode.edit;
  MapNodeStyle get nodeStyle => _nodeStyle;
  MapEdgeStyle get edgeStyle => _edgeStyle;

  List<MapNode> get nodes => _nodes;
  List<MapEdge> get edges => _edges;
  Offset get offset => _offset;
  double get scale => _scale;

  MapSelection? get selection => _selection;
  String? get selectedNodeId =>
      _selection?.type == MapSelectionType.node ? _selection!.id : null;
  String? get selectedEdgeId =>
      _selection?.type == MapSelectionType.edge ? _selection!.id : null;
  String? get hoverId => _hoverId;
  String? get editingId => _editingId;
  String? get editingEdgeId => _editingEdgeId;
  LinkDraft? get link => _link;
  String? get toast => _toast;

  /// Increments on every toast — lets the View distinguish repeat messages.
  int get toastTick => _toastTick;
  bool get canUndo => _history.isNotEmpty;

  // ── search (v1.0.0) ──
  /// The active node search query (case-insensitive).
  String get query => _query;
  bool get hasQuery => _query.trim().isNotEmpty;

  /// Ids of nodes matching the current [query] across label / ar / sub / ref /
  /// note / kind / status / value. Empty when [query] is blank.
  Set<String> get matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const {};
    bool hit(MapNode n) {
      final hay = [
        n.label,
        n.ar ?? '',
        n.sub ?? '',
        n.ref ?? '',
        n.note ?? '',
        n.kind.name,
        n.status.tag,
        n.value?.toString() ?? '',
      ].join('\u0000').toLowerCase();
      return hay.contains(q);
    }

    return {for (final n in _nodes) if (hit(n)) n.id};
  }

  /// The most recent [validate] result (empty until validate() runs).
  List<MapIssue> get issues => _issues;
  MapValidationSummary get validationSummary => MapValidationSummary(_issues);

  MapNode? nodeById(String id) {
    for (final n in _nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  MapEdge? edgeById(String id) {
    for (final e in _edges) {
      if (e.id == id) return e;
    }
    return null;
  }

  MapNode? get selectedNode {
    final id = selectedNodeId;
    return id == null ? null : nodeById(id);
  }

  /// Edge geometry for the current nodes/edges and style.
  List<EdgeGeometry> get geometry => MapLogic.geometry(_nodes, _edges, _nodeStyle);

  Set<String> get incidentEdges =>
      selectedNodeId == null ? const {} : MapLogic.incidentEdges(_edges, selectedNodeId!);
  Set<String> get neighbours =>
      selectedNodeId == null ? const {} : MapLogic.neighbours(_edges, selectedNodeId!);
  NodeStats? get selectedStats =>
      selectedNodeId == null ? null : MapLogic.statsFor(_edges, selectedNodeId!);
  Rect? get bounds => MapLogic.bounds(_nodes, _nodeStyle);

  // ── graph lifecycle ──
  void _apply(MapGraph g) {
    _nodes = g.nodes.map((n) => n.copyWith()).toList();
    _edges = List<MapEdge>.from(g.edges);
    _selection = null;
    _editingId = null;
    _editingEdgeId = null;
    _link = null;
    _issues = const [];
    _history.clear();
    _pendingFit = true;
  }

  /// Loads a new graph as the live + seed diagram and requests a fit.
  void loadGraph(MapGraph g) {
    _seed = g;
    _apply(g);
    notifyListeners();
  }

  /// Replaces the live nodes/edges without changing the stored seed
  /// (e.g. after a JSON import) and requests a fit.
  void replaceGraph(MapGraph g) {
    _apply(g);
    notifyListeners();
  }

  /// Reloads the original seed layout.
  void reset() {
    _apply(_seed);
    notifyListeners();
  }

  /// True (once) after a load — the View consumes it to fit on first layout.
  bool consumePendingFit() {
    if (!_pendingFit) return false;
    _pendingFit = false;
    return true;
  }

  /// Whether a fit is queued (set on load, cleared by [consumePendingFit]).
  bool get pendingFit => _pendingFit;

  // ── settings ──
  void setMode(MapMode m) {
    if (_mode == m) return;
    _mode = m;
    if (m == MapMode.read) {
      _link = null;
      _editingId = null;
      _editingEdgeId = null;
    }
    notifyListeners();
  }

  void setNodeStyle(MapNodeStyle s) {
    if (_nodeStyle == s) return;
    _nodeStyle = s;
    notifyListeners();
  }

  void setEdgeStyle(MapEdgeStyle s) {
    if (_edgeStyle == s) return;
    _edgeStyle = s;
    notifyListeners();
  }

  // ── view transform ──
  void setView(Offset offset, double scale) {
    _offset = offset;
    _scale = scale.clamp(0.35, 2.4);
    notifyListeners();
  }

  void panBy(Offset delta) {
    _offset += delta;
    notifyListeners();
  }

  /// Converts a screen-space point to world space under the current transform.
  Offset screenToWorld(Offset s) => (s - _offset) / _scale;

  /// Converts a world-space point to screen space.
  Offset worldToScreen(Offset w) => w * _scale + _offset;

  /// Zooms by [factor] keeping the world point under [focus] (screen px) fixed.
  void zoomAround(double factor, Offset focus) {
    final k2 = (_scale * factor).clamp(0.35, 2.4);
    final w = (focus - _offset) / _scale;
    _offset = focus - w * k2;
    _scale = k2;
    notifyListeners();
  }

  /// Fits the whole graph into [viewport] with a comfortable padding.
  void fitToView(Size viewport, {double pad = 64}) {
    final b = bounds;
    if (b == null || viewport.isEmpty) return;
    final w = b.width <= 0 ? 1.0 : b.width;
    final h = b.height <= 0 ? 1.0 : b.height;
    final kw = ((viewport.width - pad * 2) / w).clamp(0.35, 1.5).toDouble();
    final kh = ((viewport.height - pad * 2) / h).clamp(0.35, 1.5).toDouble();
    final scale = kw < kh ? kw : kh;
    _offset = Offset(
      (viewport.width - b.width * scale) / 2 - b.left * scale,
      (viewport.height - b.height * scale) / 2 - b.top * scale,
    );
    _scale = scale;
    notifyListeners();
  }

  /// Centers the view on [id] without changing zoom.
  void centerOn(String id, Size viewport) {
    final n = nodeById(id);
    if (n == null) return;
    _offset = Offset(
      viewport.width / 2 - n.x * _scale,
      viewport.height / 2 - n.y * _scale,
    );
    notifyListeners();
  }

  // ── selection / hover ──
  void selectNode(String id) {
    _selection = MapSelection(MapSelectionType.node, id);
    final n = nodeById(id);
    if (n != null) onSelectNode?.call(n);
    notifyListeners();
  }

  void selectEdge(String id) {
    _selection = MapSelection(MapSelectionType.edge, id);
    notifyListeners();
  }

  void clearSelection() {
    if (_selection == null) return;
    _selection = null;
    notifyListeners();
  }

  void setHover(String? id) {
    if (_hoverId == id) return;
    _hoverId = id;
    notifyListeners();
  }

  // ── history ──
  void _pushHistory() {
    _history.add(_Snapshot(List.of(_nodes), List.of(_edges)));
    if (_history.length > 40) _history.removeAt(0);
  }

  void undo() {
    if (_history.isEmpty) {
      _showToast('Nothing to undo');
      return;
    }
    final last = _history.removeLast();
    _nodes = last.nodes;
    _edges = last.edges;
    _selection = null;
    _showToast('Undone');
  }

  // ── node mutations ──
  String _newId(String prefix) => '$prefix${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${_uid++}';

  /// True when node [id] is audit-locked and so cannot be edited / moved.
  bool isLocked(String id) => nodeById(id)?.locked ?? false;

  /// Moves node [id] to a new world position (live during a drag). A locked
  /// node ignores the move.
  void moveNodeTo(String id, Offset world) {
    if (isLocked(id)) return;
    _nodes = [
      for (final n in _nodes) n.id == id ? n.copyWith(x: world.dx, y: world.dy) : n,
    ];
    notifyListeners();
  }

  /// Snapshots state at the start of a node drag so the move is undoable.
  void beginNodeDrag() => _pushHistory();

  /// Adds a new node centered on [world] and starts renaming it.
  String addNodeAt(Offset world, {MapNodeKind kind = MapNodeKind.process}) {
    _pushHistory();
    final id = _newId('n');
    _nodes = [..._nodes, MapNode(id: id, x: world.dx, y: world.dy, label: 'New node', kind: kind)];
    _selection = MapSelection(MapSelectionType.node, id);
    _editingId = id;
    notifyListeners();
    return id;
  }

  void duplicateNode(String id) {
    final n = nodeById(id);
    if (n == null) return;
    _pushHistory();
    final nid = _newId('n');
    _nodes = [
      ..._nodes,
      MapNode(
        id: nid,
        x: n.x + 36,
        y: n.y + 36,
        label: n.label,
        ar: n.ar,
        sub: n.sub,
        kind: n.kind,
        value: n.value,
        color: n.color,
        note: n.note,
        status: n.status,
        // A duplicate is a fresh draft: never inherit the lock or the source ref.
        locked: false,
      ),
    ];
    _selection = MapSelection(MapSelectionType.node, nid);
    _showToast('Duplicated');
  }

  void deleteNode(String id) {
    if (isLocked(id)) {
      _showToast('Node is locked');
      return;
    }
    _pushHistory();
    _nodes = _nodes.where((n) => n.id != id).toList();
    _edges = _edges.where((e) => e.from != id && e.to != id).toList();
    _selection = null;
    _showToast('Deleted');
  }

  void setKind(String id, MapNodeKind kind) {
    if (isLocked(id)) {
      _showToast('Node is locked');
      return;
    }
    _pushHistory();
    _nodes = [for (final n in _nodes) n.id == id ? n.copyWith(kind: kind) : n];
    notifyListeners();
  }

  /// Sets the workflow [status] of node [id] (v1.0.0).
  void setStatus(String id, MapNodeStatus status) {
    if (isLocked(id)) {
      _showToast('Node is locked');
      return;
    }
    _pushHistory();
    _nodes = [for (final n in _nodes) n.id == id ? n.copyWith(status: status) : n];
    _showToast(status.isNone ? 'Status cleared' : 'Status: ${status.tag}');
  }

  /// Toggles (or sets, when [value] is given) node [id]'s audit lock (v1.0.0).
  /// Locking is always permitted; unlocking is what a lock is meant to prevent
  /// implicitly, so it is an explicit, deliberate action here.
  void setLocked(String id, [bool? value]) {
    final n = nodeById(id);
    if (n == null) return;
    final next = value ?? !n.locked;
    _pushHistory();
    _nodes = [for (final m in _nodes) m.id == id ? m.copyWith(locked: next) : m];
    _showToast(next ? 'Locked' : 'Unlocked');
  }

  /// Sets (or clears, when empty/null) the source-record [ref] of node [id]
  /// (v1.0.0) — e.g. `JV-2024-0042`.
  void setRef(String id, String? ref) {
    if (isLocked(id)) {
      _showToast('Node is locked');
      return;
    }
    final trimmed = (ref ?? '').trim();
    _pushHistory();
    _nodes = [
      for (final n in _nodes)
        n.id == id ? n.copyWith(ref: trimmed.isEmpty ? null : trimmed) : n
    ];
    notifyListeners();
  }

  /// Sets (or clears, when empty/null) node [id]'s audit metadata map (v1.0.0).
  void setMeta(String id, Map<String, String>? meta) {
    if (isLocked(id)) {
      _showToast('Node is locked');
      return;
    }
    _pushHistory();
    final clean = (meta == null || meta.isEmpty) ? null : meta;
    _nodes = [for (final n in _nodes) n.id == id ? n.copyWith(meta: clean) : n];
    notifyListeners();
  }

  /// Sets (or clears, when [color] is null) the per-node theme color (v0.2.0).
  void setNodeColor(String id, Color? color) {
    if (isLocked(id)) {
      _showToast('Node is locked');
      return;
    }
    _pushHistory();
    _nodes = [for (final n in _nodes) n.id == id ? n.copyWith(color: color) : n];
    _showToast(color == null ? 'Color cleared' : 'Color set');
  }

  /// Sets (or clears, when [note] is empty/null) the per-node memo (v0.2.0).
  void setNote(String id, String? note) {
    final trimmed = (note ?? '').trim();
    _pushHistory();
    _nodes = [
      for (final n in _nodes)
        n.id == id ? n.copyWith(note: trimmed.isEmpty ? null : trimmed) : n
    ];
    notifyListeners();
  }

  // ── rename ──
  void startRename(String id) {
    _selection = MapSelection(MapSelectionType.node, id);
    _editingId = id;
    notifyListeners();
  }

  void commitRename(String text) {
    final id = _editingId;
    if (id == null) return;
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      _nodes = [for (final n in _nodes) n.id == id ? n.copyWith(label: trimmed) : n];
    }
    _editingId = null;
    notifyListeners();
  }

  void cancelRename() {
    if (_editingId == null) return;
    _editingId = null;
    notifyListeners();
  }

  // ── edges ──
  void addEdge(String from, String to) {
    if (from == to) return;
    if (_edges.any((e) => e.from == from && e.to == to)) {
      _showToast('Already connected');
      return;
    }
    _pushHistory();
    _edges = [..._edges, MapEdge(id: _newId('e'), from: from, to: to)];
    _showToast('Connected');
  }

  void deleteEdge(String id) {
    _pushHistory();
    _edges = _edges.where((e) => e.id != id).toList();
    _selection = null;
    _showToast('Edge removed');
  }

  // ── edge label (v0.2.0) ──
  /// Begins inline editing of edge [id]'s text label.
  void startEdgeLabel(String id) {
    _selection = MapSelection(MapSelectionType.edge, id);
    _editingEdgeId = id;
    notifyListeners();
  }

  /// Commits the edited edge label (an empty string clears it).
  void commitEdgeLabel(String text) {
    final id = _editingEdgeId;
    if (id == null) return;
    final trimmed = text.trim();
    _pushHistory();
    _edges = [
      for (final e in _edges)
        e.id == id ? e.copyWith(label: trimmed.isEmpty ? null : trimmed) : e
    ];
    _editingEdgeId = null;
    notifyListeners();
  }

  void cancelEdgeLabel() {
    if (_editingEdgeId == null) return;
    _editingEdgeId = null;
    notifyListeners();
  }

  /// Directly sets edge [id]'s label without entering edit mode.
  void setEdgeLabel(String id, String? label) {
    final trimmed = (label ?? '').trim();
    _pushHistory();
    _edges = [
      for (final e in _edges)
        e.id == id ? e.copyWith(label: trimmed.isEmpty ? null : trimmed) : e
    ];
    notifyListeners();
  }

  // ── linking (drag a port to connect) ──
  void startLink(String fromId, NodeSide side, Offset worldCursor, {bool click = false}) {
    _link = LinkDraft(fromId: fromId, side: side, cursor: worldCursor, click: click);
    notifyListeners();
  }

  void updateLink(Offset worldCursor) {
    if (_link == null) return;
    _link = _link!.copyWith(cursor: worldCursor);
    notifyListeners();
  }

  /// Ends a link drag, connecting to [targetId] when present and different.
  void endLink(String? targetId) {
    final draft = _link;
    _link = null;
    if (draft != null && targetId != null && targetId != draft.fromId) {
      addEdge(draft.fromId, targetId);
    } else {
      notifyListeners();
    }
  }

  void cancelLink() {
    if (_link == null) return;
    _link = null;
    notifyListeners();
  }

  // ── search / filter (v1.0.0) ──
  /// Sets the live node search query. Matching node ids are exposed via
  /// [matches]; the View dims non-matches. Passing blank clears the search.
  void setQuery(String q) {
    if (_query == q) return;
    _query = q;
    notifyListeners();
  }

  void clearQuery() => setQuery('');

  // ── auto-layout (v1.0.0) ──
  /// Re-places nodes with one of the [MapLayout] algorithms (locked nodes keep
  /// their coordinates) and requests a fit. Undoable.
  void autoLayout([MapLayoutSpec spec = const MapLayoutSpec()]) {
    if (_nodes.isEmpty) return;
    _pushHistory();
    final laid = MapLayout.apply(toGraph(), spec);
    _nodes = laid.nodes.map((n) => n.copyWith()).toList();
    _pendingFit = true;
    _showToast('Layout applied');
  }

  // ── validation (v1.0.0) ──
  /// Runs [MapValidator] over the live graph, caches the result in [issues],
  /// surfaces a one-line toast, and returns the issues.
  List<MapIssue> validate({double balanceEpsilon = 0.5}) {
    _issues = MapValidator.validate(toGraph(), balanceEpsilon: balanceEpsilon);
    final s = MapValidationSummary(_issues);
    _showToast(s.isClean
        ? 'Validation passed'
        : '${s.errors} error(s), ${s.warnings} warning(s)');
    return _issues;
  }

  /// Clears the cached validation result.
  void clearIssues() {
    if (_issues.isEmpty) return;
    _issues = const [];
    notifyListeners();
  }

  // ── JSON ──
  String exportJson() => const JsonEncoder.withIndent('  ').convert(toGraph().toJson());

  /// The current live state as a [MapGraph].
  MapGraph toGraph() => _seed.copyWith(nodes: _nodes, edges: _edges);

  /// Parses [text] and replaces the live graph; returns an error string or null.
  String? importJson(String text) {
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic> || data['nodes'] is! List) {
        return 'Missing a "nodes" array.';
      }
      replaceGraph(MapGraph.fromJson(data, id: _seed.id, title: _seed.title));
      _showToast('Diagram generated');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── toast ──
  void _showToast(String msg) {
    _toast = msg;
    _toastTick++;
    notifyListeners();
  }

  /// Clears the toast (the View calls this after its display timer).
  void clearToast() {
    if (_toast == null) return;
    _toast = null;
    notifyListeners();
  }
}
