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
import 'package:flutter/widgets.dart' show Offset, Size, Rect;

import '../../domain/entities/map_graph.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/usecases/map_logic.dart';

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
  LinkDraft? _link;
  String? _toast;
  int _toastTick = 0;
  bool _pendingFit = false;

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
  LinkDraft? get link => _link;
  String? get toast => _toast;

  /// Increments on every toast — lets the View distinguish repeat messages.
  int get toastTick => _toastTick;
  bool get canUndo => _history.isNotEmpty;

  MapNode? nodeById(String id) {
    for (final n in _nodes) {
      if (n.id == id) return n;
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
    _link = null;
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

  /// Moves node [id] to a new world position (live during a drag).
  void moveNodeTo(String id, Offset world) {
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
    _nodes = [..._nodes, n.copyWith(x: n.x + 36, y: n.y + 36)];
    // copyWith keeps the same id; rebuild with the new id explicitly:
    _nodes[_nodes.length - 1] = MapNode(
      id: nid,
      x: n.x + 36,
      y: n.y + 36,
      label: n.label,
      ar: n.ar,
      sub: n.sub,
      kind: n.kind,
      value: n.value,
    );
    _selection = MapSelection(MapSelectionType.node, nid);
    _showToast('Duplicated');
  }

  void deleteNode(String id) {
    _pushHistory();
    _nodes = _nodes.where((n) => n.id != id).toList();
    _edges = _edges.where((e) => e.from != id && e.to != id).toList();
    _selection = null;
    _showToast('Deleted');
  }

  void setKind(String id, MapNodeKind kind) {
    _pushHistory();
    _nodes = [for (final n in _nodes) n.id == id ? n.copyWith(kind: kind) : n];
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
