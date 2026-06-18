// ============================================================
// features/super_map/presentation/widgets/super_map.dart
// ------------------------------------------------------------
// The SuperMap canvas — the composed View. A pannable / zoomable / draggable
// node-graph with READ and EDIT modes, driven entirely by a SuperMapController:
//
//   read  — pan (drag empty canvas), zoom (scroll / pinch), drag nodes, tap to
//           select + inspect, right-click / long-press for a context menu.
//   edit  — four-sided ports (drag to connect), add / rename / re-kind /
//           duplicate / delete nodes, delete edges, undo, JSON import/export.
//
// Overlays: dot grid, minimap, details panel, title chip, zoom cluster, toast.
// A faithful port of the React SuperMap. All chrome reads SuperThemeData.
// ============================================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_map/super_map.dart';

import '../../../../core/core.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/usecases/map_logic.dart';
import '../controllers/super_map_controller.dart';
import '../painters/edge_painter.dart';
import '../painters/grid_painter.dart';
import 'map_context_menu.dart';
import 'map_details_panel.dart';
import 'map_export_sheet.dart';
import 'map_json_sheet.dart';
import 'map_minimap.dart';
import 'map_node_card.dart';
import 'map_note_popover.dart';

class _MenuReq {
  const _MenuReq(this.local, this.type, this.id);
  final Offset local;
  final MapSelectionType? type; // null ⇒ canvas
  final String? id;
}

class SuperMap extends StatefulWidget {
  const SuperMap({
    super.key,
    required this.controller,
    this.height = 540,
    this.showToolbar = true,
    this.showGrid = true,
    this.showMinimap = true,
    this.showEdgeLabels = true,
    this.showData = false,
    this.animateFlow = false,
    this.onExport,
  });

  final SuperMapController controller;
  final double height;
  final bool showToolbar;
  final bool showGrid;
  final bool showMinimap;
  final bool showEdgeLabels;

  /// When true, every node shows its own value / connection counts inline
  /// (v0.2.0 — not just the selected node's data). Toggleable from the toolbar.
  final bool showData;
  final bool animateFlow;

  /// Host hook to persist/share exported bytes (PNG / PDF / DOCX). When null,
  /// the Export button is still shown but reports that no saver is wired.
  final MapExportSaver? onExport;

  @override
  State<SuperMap> createState() => _SuperMapState();
}

class _SuperMapState extends State<SuperMap> with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();
  final FocusNode _focus = FocusNode();
  Size _viewport = Size.zero;
  _MenuReq? _menu;
  String? _noteId; // node whose note popover is open
  late bool _showData = widget.showData;

  // scale-gesture anchors
  Offset _startOffset = Offset.zero;
  double _startScale = 1;
  Offset _startFocal = Offset.zero;

  AnimationController? _flow;

  SuperMapController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.animateFlow) {
      _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    }
  }

  @override
  void dispose() {
    _flow?.dispose();
    _focus.dispose();
    super.dispose();
  }

  RenderBox? get _box => _canvasKey.currentContext?.findRenderObject() as RenderBox?;
  Offset _toLocal(Offset global) => _box?.globalToLocal(global) ?? global;

  String? _edgeAt(Offset local) {
    final m = (Matrix4.identity()
          ..translate(c.offset.dx, c.offset.dy)
          ..scale(c.scale))
        .storage;
    var bestId = '';
    var best = double.infinity;
    for (final g in c.geometry) {
      final screen = MapLogic.buildPath(g.a, g.b, c.edgeStyle).transform(m);
      final d = MapLogic.distanceToPath(screen, local);
      if (d < best) {
        best = d;
        bestId = g.edge.id;
      }
    }
    return best <= 10 ? bestId : null;
  }

  // ── scale (pan + zoom) ──
  void _onScaleStart(ScaleStartDetails d) {
    _focus.requestFocus();
    _startOffset = c.offset;
    _startScale = c.scale;
    _startFocal = d.localFocalPoint;
    setState(() => _menu = null);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final desired = (_startScale * d.scale).clamp(0.35, 2.4).toDouble();
    final worldFocal = (_startFocal - _startOffset) / _startScale;
    final newOffset = d.localFocalPoint - worldFocal * desired;
    c.setView(newOffset, desired);
  }

  void _onTapUp(TapUpDetails d) {
    if (_menu != null) {
      setState(() => _menu = null);
      return;
    }
    final id = _edgeAt(d.localPosition);
    if (id != null) {
      c.selectEdge(id);
    } else {
      c.clearSelection();
    }
  }

  void _openMenuAt(Offset global) {
    final local = _toLocal(global);
    final edge = _edgeAt(local);
    setState(() {
      _menu = edge != null
          ? _MenuReq(local, MapSelectionType.edge, edge)
          : _MenuReq(local, null, null);
    });
    if (edge != null) c.selectEdge(edge);
  }

  void _zoomCenter(double factor) {
    if (_viewport.isEmpty) return;
    c.zoomAround(factor, Offset(_viewport.width / 2, _viewport.height / 2));
  }

  void _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    final sel = c.selection;
    if (c.isEdit && (e.logicalKey == LogicalKeyboardKey.delete || e.logicalKey == LogicalKeyboardKey.backspace)) {
      if (sel?.type == MapSelectionType.node) c.deleteNode(sel!.id);
      if (sel?.type == MapSelectionType.edge) c.deleteEdge(sel!.id);
    }
  }

  Future<void> _openJson() async {
    final edited = await showMapJsonSheet(context, c.exportJson());
    if (edited == null || !mounted) return;
    final err = c.importJson(edited);
    if (err != null && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _openExport() async {
    await showMapExportSheet(
      context,
      boundaryKey: _repaintKey,
      title: c.seed.title,
      onExport: (bytes, filename, format) {
        if (widget.onExport != null) {
          widget.onExport!(bytes, filename, format);
        } else if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text('Exported $filename (${bytes.length} bytes) — wire SuperMap.onExport to save it.')),
          );
        }
      },
    );
  }

  void _toggleData() => setState(() => _showData = !_showData);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([c, if (_flow != null) _flow]),
      builder: (context, _) {
        final t = context.superTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showToolbar) ...[
              _toolbar(t),
              const SizedBox(height: 12),
            ],
            SizedBox(height: widget.height, child: _canvas(t)),
          ],
        );
      },
    );
  }

  // ── toolbar ──
  Widget _toolbar(SuperThemeData t) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ModeToggle(mode: c.mode, onChanged: c.setMode),
        if (c.isEdit) ...[
          _CanvasSeg<MapNodeStyle>(
            value: c.nodeStyle,
            onChanged: c.setNodeStyle,
            options: const {
              MapNodeStyle.card: 'Card',
              MapNodeStyle.pill: 'Pill',
              MapNodeStyle.chip: 'Chip',
            },
          ),
          _CanvasSeg<MapEdgeStyle>(
            value: c.edgeStyle,
            onChanged: c.setEdgeStyle,
            options: const {
              MapEdgeStyle.curved: 'Curved',
              MapEdgeStyle.orthogonal: 'Ortho',
              MapEdgeStyle.straight: 'Straight',
            },
          ),
        ],
        SuperButton(
          label: 'Data',
          variant: _showData ? SuperButtonVariant.primary : SuperButtonVariant.secondary,
          icon: const Icon(Icons.layers_outlined),
          onPressed: _toggleData,
        ),
        if (c.isEdit) ...[
          SuperButton(
            label: 'Add node',
            variant: SuperButtonVariant.secondary,
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              if (_viewport.isEmpty) return;
              c.addNodeAt(c.screenToWorld(Offset(_viewport.width / 2, _viewport.height / 2)));
            },
          ),
          SuperButton(
            label: 'Undo',
            variant: SuperButtonVariant.secondary,
            icon: const Icon(Icons.undo_rounded),
            onPressed: c.undo,
          ),
        ],
        SuperButton(
          label: 'Export',
          variant: SuperButtonVariant.secondary,
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: _openExport,
        ),
        SuperButton(
          label: 'JSON',
          variant: SuperButtonVariant.secondary,
          icon: const Icon(Icons.data_object_rounded),
          onPressed: _openJson,
        ),
      ],
    );
  }

  // ── canvas ──
  Widget _canvas(SuperThemeData t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _viewport = size;
        if (c.pendingFit && !size.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (c.consumePendingFit()) c.fitToView(_viewport);
          });
        }

        final accentBorder = c.isEdit
            ? Color.alphaBlend(SuperTokens.accent.withOpacity(0.4), t.border)
            : t.border;

        return Focus(
          focusNode: _focus,
          onKeyEvent: (_, e) {
            _onKey(e);
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerSignal: (s) {
              if (s is PointerScrollEvent) {
                final factor = s.scrollDelta.dy < 0 ? 1.12 : 0.89;
                c.zoomAround(factor, _toLocal(s.position));
              }
            },
            child: RepaintBoundary(
              key: _repaintKey,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.bg,
                    border: Border.all(color: accentBorder),
                    borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
                  ),
                  child: Stack(
                    key: _canvasKey,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // grid
                      if (widget.showGrid)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(offset: c.offset, scale: c.scale, color: t.border),
                          ),
                        ),
                      // pan / zoom / tap surface (below nodes)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onTapUp: _onTapUp,
                          onSecondaryTapDown: (d) => _openMenuAt(d.globalPosition),
                          onLongPressStart: (d) => _openMenuAt(d.globalPosition),
                        ),
                      ),
                      // edges
                      Positioned.fill(child: IgnorePointer(child: _edgesLayer(t))),
                      // nodes + ports + edge labels (world space)
                      Positioned.fill(child: _worldLayer(t)),
                      // overlays
                      ..._overlays(t),
                      if (_menu != null) ..._menuLayer(t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _edgesLayer(SuperThemeData t) {
    Offset? linkFrom, linkTo;
    final link = c.link;
    if (link != null) {
      final from = c.nodeById(link.fromId);
      if (from != null) {
        final a = MapLogic.sideAnchor(from.center, MapLogic.sizeOf(from, c.nodeStyle), link.cursor);
        linkFrom = a.point;
        linkTo = link.cursor;
      }
    }
    return CustomPaint(
      painter: EdgePainter(
        geometry: c.geometry,
        edgeStyle: c.edgeStyle,
        offset: c.offset,
        scale: c.scale,
        selectedNodeId: c.selectedNodeId,
        selectedEdgeId: c.selectedEdgeId,
        incident: c.incidentEdges,
        accentForEdge: (e) {
          final from = c.nodeById(e.from);
          return from?.accentOf(t) ?? MapNodeKind.leaf.colorOf(t);
        },
        borderStrong: t.borderStrong,
        accent: SuperTokens.accent,
        linkFrom: linkFrom,
        linkTo: linkTo,
        flow: widget.animateFlow,
        dashPhase: (_flow?.value ?? 0) * 26,
        flowT: _flow?.value ?? 0,
      ),
    );
  }

  Widget _worldLayer(SuperThemeData t) {
    final matrix = Matrix4.identity()
      ..translate(c.offset.dx, c.offset.dy)
      ..scale(c.scale);
    final selId = c.selectedNodeId;
    final neighbours = c.neighbours;

    return Transform(
      transform: matrix,
      child: OverflowBox(
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _viewport.width,
          height: _viewport.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // edge labels (text + value) + inline label editor
              for (final g in c.geometry)
                if (c.editingEdgeId == g.edge.id ||
                    g.edge.label != null ||
                    (widget.showEdgeLabels && g.edge.value != null))
                  Positioned(
                    left: g.mid.dx,
                    top: g.mid.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: c.editingEdgeId == g.edge.id
                          ? _EdgeLabelEditor(
                              initial: g.edge.label ?? '',
                              onCommit: c.commitEdgeLabel,
                              onCancel: c.cancelEdgeLabel,
                            )
                          : _EdgeLabel(
                              label: g.edge.label,
                              value: widget.showEdgeLabels ? g.edge.value : null,
                              dim: selId != null && !c.incidentEdges.contains(g.edge.id),
                              onTap: c.isEdit ? () => c.startEdgeLabel(g.edge.id) : null,
                            ),
                    ),
                  ),
              // nodes
              for (final n in c.nodes) _nodeCard(n, selId, neighbours),
              // ports
              if (c.isEdit)
                for (final n in c.nodes) ..._ports(n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nodeCard(MapNode n, String? selId, Set<String> neighbours) {
    final size = MapLogic.sizeOf(n, c.nodeStyle);
    final dim = selId != null && selId != n.id && !neighbours.contains(n.id);
    return Positioned(
      left: n.x - size.width / 2,
      top: n.y - size.height / 2,
      width: size.width,
      height: size.height,
      child: MapNodeCard(
        node: n,
        size: size,
        style: c.nodeStyle,
        editMode: c.isEdit,
        selected: selId == n.id,
        dimmed: dim,
        editing: c.editingId == n.id,
        showData: _showData,
        stats: _showData ? MapLogic.statsFor(c.edges, n.id) : null,
        showNote: c.isEdit || n.note != null,
        onNote: () => setState(() => _noteId = n.id),
        onSelect: () => c.selectNode(n.id),
        onDragStart: c.beginNodeDrag,
        onDragUpdate: (delta) {
          final cur = c.nodeById(n.id);
          if (cur != null) c.moveNodeTo(n.id, cur.center + delta / c.scale);
        },
        onDragEnd: () {},
        onDoubleTap: () => c.startRename(n.id),
        onContextMenu: (global) {
          c.selectNode(n.id);
          setState(() => _menu = _MenuReq(_toLocal(global), MapSelectionType.node, n.id));
        },
        onHover: (h) => c.setHover(h ? n.id : null),
        onCommitRename: c.commitRename,
        onCancelRename: c.cancelRename,
      ),
    );
  }

  List<Widget> _ports(MapNode n) {
    final size = MapLogic.sizeOf(n, c.nodeStyle);
    final hw = size.width / 2, hh = size.height / 2;
    final defs = <(NodeSide, double, double)>[
      (NodeSide.top, 0, -1),
      (NodeSide.bottom, 0, 1),
      (NodeSide.left, -1, 0),
      (NodeSide.right, 1, 0),
    ];
    final lit = c.hoverId == n.id || (c.link != null && c.link!.fromId != n.id);
    return [
      for (final (side, ux, uy) in defs)
        Positioned(
          left: n.x + ux * hw - 6,
          top: n.y + uy * hh - 6,
          child: _Port(
            lit: lit,
            onStart: (global) {
              final world = c.screenToWorld(_toLocal(global));
              c.startLink(n.id, side, world);
            },
            onUpdate: (global) => c.updateLink(c.screenToWorld(_toLocal(global))),
            onEnd: (global) {
              final world = c.screenToWorld(_toLocal(global));
              final target = MapLogic.nodeAt(c.nodes, world, c.nodeStyle);
              c.endLink(target?.id);
            },
          ),
        ),
    ];
  }

  // ── overlays ──
  List<Widget> _overlays(SuperThemeData t) {
    final sel = c.selectedNode;
    final stats = c.selectedStats;
    return [
      // top-left: fit / reset
      PositionedDirectional(
        top: 12,
        start: 12,
        child: Row(children: [
          _RoundBtn(icon: Icons.fullscreen_rounded, tooltip: 'Fit to view', onTap: () => c.fitToView(_viewport)),
          const SizedBox(width: 7),
          _RoundBtn(icon: Icons.refresh_rounded, tooltip: 'Reset layout', onTap: c.reset),
        ]),
      ),
      // top-right: title chip
      PositionedDirectional(
        top: 12,
        end: 12,
        child: _TitleChip(title: c.seed.title, zoom: (c.scale * 100).round()),
      ),
      // bottom-right: zoom cluster
      PositionedDirectional(
        bottom: 12,
        end: 12,
        child: Column(children: [
          _RoundBtn(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: () => _zoomCenter(1.2)),
          const SizedBox(height: 7),
          _RoundBtn(icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: () => _zoomCenter(1 / 1.2)),
        ]),
      ),
      // bottom-left: minimap
      if (widget.showMinimap && c.bounds != null && !_viewport.isEmpty)
        PositionedDirectional(
          bottom: 12,
          start: 12,
          child: MapMinimap(
            nodes: c.nodes,
            geometry: c.geometry,
            bounds: c.bounds!,
            style: c.nodeStyle,
            offset: c.offset,
            scale: c.scale,
            viewport: _viewport,
            selectedNodeId: c.selectedNodeId,
          ),
        ),
      // details panel
      if (sel != null && stats != null)
        PositionedDirectional(
          top: 56,
          end: 12,
          child: MapDetailsPanel(
            node: sel,
            stats: stats,
            editMode: c.isEdit,
            onClose: c.clearSelection,
            onRename: () => c.startRename(sel.id),
            onClone: () => c.duplicateNode(sel.id),
            onDelete: () => c.deleteNode(sel.id),
            onNote: () => setState(() => _noteId = sel.id),
          ),
        ),
      // all-nodes data panel (v0.2.0)
      if (_showData && c.nodes.isNotEmpty)
        PositionedDirectional(
          top: 56,
          start: 12,
          child: _DataPanel(
            controller: c,
            maxHeight: (_viewport.height - 188).clamp(120.0, double.infinity),
            onPick: (id) {
              c.selectNode(id);
              if (!_viewport.isEmpty) c.centerOn(id, _viewport);
            },
            onClose: _toggleData,
          ),
        ),
      // toast
      if (c.toast != null)
        Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: Center(
            child: _Toast(message: c.toast!, tick: c.toastTick, onDone: c.clearToast),
          ),
        ),
      // note popover (v0.2.0)
      if (_noteId != null && c.nodeById(_noteId!) != null) ..._notePopoverLayer(t),
    ];
  }

  List<Widget> _notePopoverLayer(SuperThemeData t) {
    final n = c.nodeById(_noteId!)!;
    final size = MapLogic.sizeOf(n, c.nodeStyle);
    final corner = c.worldToScreen(Offset(n.x + size.width / 2, n.y - size.height / 2));
    const w = 236.0;
    final left = (corner.dx + 6).clamp(8.0, (_viewport.width - w - 8).clamp(8.0, double.infinity));
    final top = (corner.dy - 6).clamp(8.0, (_viewport.height - 170).clamp(8.0, double.infinity));
    void close() => setState(() => _noteId = null);
    return [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: close,
          onSecondaryTap: close,
        ),
      ),
      Positioned(
        left: left,
        top: top,
        child: MapNotePopover(
          node: n,
          editMode: c.isEdit,
          onClose: close,
          onSave: (text) => c.setNote(n.id, text),
        ),
      ),
    ];
  }

  // ── context menu ──
  List<Widget> _menuLayer(SuperThemeData t) {
    final req = _menu!;
    final items = <Widget>[];
    String? title;
    MapNodeKind? currentKind;
    ValueChanged<MapNodeKind>? onPickKind;
    Color? currentColor;
    ValueChanged<Color?>? onPickColor;

    void close() => setState(() => _menu = null);

    if (req.type == MapSelectionType.node) {
      final n = c.nodeById(req.id!);
      title = n?.label ?? 'Node';
      if (c.isEdit) {
        currentKind = n?.kind;
        currentColor = n?.color;
        onPickKind = (k) {
          c.setKind(req.id!, k);
          close();
        };
        onPickColor = (col) {
          c.setNodeColor(req.id!, col);
          close();
        };
        items.addAll([
          MapMenuItem(icon: Icons.edit_outlined, label: 'Rename', kbd: '↵', onTap: () { c.startRename(req.id!); close(); }),
          MapMenuItem(icon: Icons.sticky_note_2_outlined, label: (n?.note != null) ? 'Edit note' : 'Add note', onTap: () { setState(() { _menu = null; _noteId = req.id; }); }),
          MapMenuItem(icon: Icons.link_rounded, label: 'Connect from here', onTap: () {
            final n2 = c.nodeById(req.id!);
            if (n2 != null) c.startLink(req.id!, NodeSide.right, n2.center, click: true);
            close();
          }),
          MapMenuItem(icon: Icons.copy_rounded, label: 'Duplicate', onTap: () { c.duplicateNode(req.id!); close(); }),
          const _MenuDivider(),
          MapMenuItem(icon: Icons.delete_outline_rounded, label: 'Delete', danger: true, kbd: '⌫', onTap: () { c.deleteNode(req.id!); close(); }),
        ]);
      } else {
        items.addAll([
          MapMenuItem(icon: Icons.my_location_rounded, label: 'Inspect', onTap: () { c.selectNode(req.id!); close(); }),
          if (n?.note != null)
            MapMenuItem(icon: Icons.sticky_note_2_outlined, label: 'View note', onTap: () { setState(() { _menu = null; _noteId = req.id; }); }),
          MapMenuItem(icon: Icons.center_focus_strong_rounded, label: 'Center on node', onTap: () { c.centerOn(req.id!, _viewport); close(); }),
        ]);
      }
    } else if (req.type == MapSelectionType.edge) {
      title = 'Connection';
      if (c.isEdit) {
        final e = c.edgeById(req.id!);
        items.addAll([
          MapMenuItem(icon: Icons.edit_outlined, label: (e?.label != null) ? 'Edit label' : 'Label connection', onTap: () { c.startEdgeLabel(req.id!); close(); }),
          MapMenuItem(icon: Icons.delete_outline_rounded, label: 'Delete connection', danger: true, onTap: () { c.deleteEdge(req.id!); close(); }),
        ]);
      } else {
        items.add(MapMenuItem(icon: Icons.my_location_rounded, label: 'Select connection', onTap: () { c.selectEdge(req.id!); close(); }));
      }
    } else {
      title = 'Canvas';
      if (c.isEdit) {
        items.add(MapMenuItem(icon: Icons.add_rounded, label: 'Add node here', onTap: () {
          c.addNodeAt(c.screenToWorld(req.local));
          close();
        }));
      }
      items.addAll([
        MapMenuItem(icon: Icons.fullscreen_rounded, label: 'Fit to view', onTap: () { c.fitToView(_viewport); close(); }),
        MapMenuItem(icon: Icons.refresh_rounded, label: 'Reset layout', onTap: () { c.reset(); close(); }),
        const _MenuDivider(),
        MapMenuItem(icon: Icons.data_object_rounded, label: 'Diagram JSON…', onTap: () { close(); _openJson(); }),
      ]);
    }

    const w = MapContextMenu.width;
    final left = req.local.dx.clamp(6.0, (_viewport.width - w - 6).clamp(6.0, double.infinity));
    final top = req.local.dy.clamp(6.0, (_viewport.height - 40).clamp(6.0, double.infinity));

    return [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: close,
          onSecondaryTap: close,
        ),
      ),
      Positioned(
        left: left,
        top: top,
        child: MapContextMenu(title: title, items: items, currentKind: currentKind, onPickKind: onPickKind, currentColor: currentColor, onPickColor: onPickColor),
      ),
    ];
  }
}

// ── small View atoms ──────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final MapMode mode;
  final ValueChanged<MapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    Widget seg(String label, MapMode m) {
      final on = mode == m;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: SuperTokens.durBase,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: on ? SuperTokens.accent : const Color(0x00000000),
            borderRadius: BorderRadius.circular(SuperTokens.radiusControl - 1),
          ),
          child: Text(label,
              style: SuperText.button.copyWith(
                  fontSize: 13, color: on ? Colors.white : t.fg2)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.inputBg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('Read', MapMode.read), seg('Edit', MapMode.edit)]),
    );
  }
}

class _RoundBtn extends StatefulWidget {
  const _RoundBtn({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_RoundBtn> createState() => _RoundBtnState();
}

class _RoundBtnState extends State<_RoundBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: SuperTokens.durBase,
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hover ? t.hover : t.surface,
              border: Border.all(color: t.borderStrong),
              borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
            ),
            child: Icon(widget.icon, size: 16, color: _hover ? t.fg1 : t.fg2),
          ),
        ),
      ),
    );
  }
}

class _TitleChip extends StatelessWidget {
  const _TitleChip({required this.title, required this.zoom});
  final String title;
  final int zoom;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(t.surface.withOpacity(0.88), t.bg),
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.my_location_rounded, size: 13, color: SuperTokens.accent),
        const SizedBox(width: 8),
        Text(title, style: SuperText.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: t.fg1)),
        const SizedBox(width: 8),
        Text('$zoom%', style: SuperText.mono.copyWith(fontSize: 10.5, color: t.fg3)),
      ]),
    );
  }
}

class _EdgeLabel extends StatelessWidget {
  const _EdgeLabel({this.label, this.value, required this.dim, this.onTap});
  final String? label;
  final double? value;
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    Widget pill(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: child,
        );
    return AnimatedOpacity(
      duration: SuperTokens.durBase,
      opacity: dim ? 0.2 : 1,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.text : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onDoubleTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                pill(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 168),
                  child: Text(label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SuperText.caption.copyWith(
                          fontSize: 10.5, fontWeight: FontWeight.w600, color: t.fg2)),
                )),
              if (label != null && value != null) const SizedBox(height: 2),
              if (value != null)
                pill(Text(mapCompact(value!),
                    style: SuperText.mono.copyWith(
                        fontSize: 10, fontWeight: FontWeight.w700, color: t.fg3))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline editor for an edge's text label, rendered at the edge midpoint.
class _EdgeLabelEditor extends StatefulWidget {
  const _EdgeLabelEditor({required this.initial, required this.onCommit, required this.onCancel});
  final String initial;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  @override
  State<_EdgeLabelEditor> createState() => _EdgeLabelEditorState();
}

class _EdgeLabelEditorState extends State<_EdgeLabelEditor> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return SizedBox(
      width: 132,
      height: 24,
      child: TextField(
        controller: _ctl,
        focusNode: _focus,
        textAlign: TextAlign.center,
        cursorColor: SuperTokens.accent,
        style: SuperText.body.copyWith(fontSize: 11, color: t.fg1),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Label…',
          hintStyle: SuperText.body.copyWith(fontSize: 11, color: t.fg4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          filled: true,
          fillColor: t.inputBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: SuperTokens.accent, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: SuperTokens.accent, width: 1.5),
          ),
        ),
        onSubmitted: widget.onCommit,
        onTapOutside: (_) => widget.onCommit(_ctl.text),
      ),
    );
  }
}

/// A compact segmented control used in the canvas toolbar (node / edge style).
class _CanvasSeg<T> extends StatelessWidget {
  const _CanvasSeg({required this.value, required this.options, required this.onChanged});
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.inputBg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final entry in options.entries)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: SuperTokens.durBase,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: value == entry.key ? SuperTokens.accent : const Color(0x00000000),
                borderRadius: BorderRadius.circular(SuperTokens.radiusControl - 1),
              ),
              child: Text(entry.value,
                  style: SuperText.button.copyWith(
                      fontSize: 11.5, color: value == entry.key ? Colors.white : t.fg2)),
            ),
          ),
      ]),
    );
  }
}

/// The all-nodes data panel (v0.2.0): a scrollable list of every node with its
/// in/out degree and value — so all nodes' data is visible at once, not only
/// the selected one. Tapping a row selects + centers that node.
class _DataPanel extends StatelessWidget {
  const _DataPanel({
    required this.controller,
    required this.maxHeight,
    required this.onPick,
    required this.onClose,
  });
  final SuperMapController controller;
  final double maxHeight;
  final ValueChanged<String> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final c = controller;
    return Container(
      width: 222,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Color.alphaBlend(t.surface.withOpacity(0.96), t.bg),
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
        boxShadow: t.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            child: Row(children: [
              const Icon(Icons.layers_outlined, size: 13, color: SuperTokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('ALL NODES · ${c.nodes.length}',
                    style: SuperText.label.copyWith(fontSize: 10.5, color: t.fg2)),
              ),
              SuperIconButton(icon: Icons.close_rounded, onPressed: onClose),
            ]),
          ),
          const Hairline(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: c.nodes.length,
              separatorBuilder: (_, __) => const Hairline(),
              itemBuilder: (context, i) {
                final n = c.nodes[i];
                final s = MapLogic.statsFor(c.edges, n.id);
                final accent = n.accentOf(t);
                final selected = c.selectedNodeId == n.id;
                return _DataRow(
                  node: n,
                  stats: s,
                  accent: accent,
                  selected: selected,
                  onTap: () => onPick(n.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  const _DataRow({
    required this.node,
    required this.stats,
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final MapNode node;
  final NodeStats stats;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final n = widget.node, s = widget.stats;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: widget.selected
              ? t.tintFill(SuperTokens.accent, 0.10)
              : (_hover ? t.hover : const Color(0x00000000)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.accent, shape: BoxShape.circle)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(n.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SuperText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: t.fg1)),
                  Text('in ${s.inCount} · out ${s.outCount}${n.note != null ? ' · note' : ''}',
                      style: SuperText.mono.copyWith(fontSize: 9.5, color: t.fg4)),
                ],
              ),
            ),
            if (n.value != null)
              Text(mapCompact(n.value!),
                  style: SuperText.mono.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, color: widget.accent)),
          ]),
        ),
      ),
    );
  }
}

class _Port extends StatefulWidget {
  const _Port({required this.lit, required this.onStart, required this.onUpdate, required this.onEnd});
  final bool lit;
  final ValueChanged<Offset> onStart; // global position
  final ValueChanged<Offset> onUpdate;
  final ValueChanged<Offset> onEnd;

  @override
  State<_Port> createState() => _PortState();
}

class _PortState extends State<_Port> {
  Offset _last = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          _last = d.globalPosition;
          widget.onStart(d.globalPosition);
        },
        onPanUpdate: (d) {
          _last = d.globalPosition;
          widget.onUpdate(d.globalPosition);
        },
        onPanEnd: (_) => widget.onEnd(_last),
        onPanCancel: () => widget.onEnd(_last),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.lit ? SuperTokens.accent : t.surface,
            border: Border.all(color: SuperTokens.accent, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Hairline(color: context.superTheme.border),
      );
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.tick, required this.onDone});
  final String message;
  final int tick;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(_Toast old) {
    super.didUpdateWidget(old);
    if (old.tick != widget.tick) _arm();
  }

  void _arm() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: t.fg1,
        borderRadius: BorderRadius.circular(999),
        boxShadow: t.cardShadow,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_rounded, size: 13, color: t.bg),
        const SizedBox(width: 7),
        Text(widget.message, style: SuperText.button.copyWith(fontSize: 12, color: t.bg)),
      ]),
    );
  }
}
