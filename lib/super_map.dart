/// Super Map — a GeniusLink design-system Flutter package providing
/// **SuperMap**, a pannable, zoomable, draggable node-graph canvas with READ
/// and EDIT modes.
///
///   read  — pan / zoom / drag nodes / tap to select + inspect.
///   edit  — four-sided ports (drag to connect), add / rename / re-kind /
///           duplicate / delete nodes, delete edges, undo, JSON import/export.
///
/// Extras: per-node theme colors and notes, text-labelled connections, an
/// all-nodes data panel, image / PDF / Word export, right-click / long-press
/// context menus on nodes, edges and canvas; curved / orthogonal / straight
/// edge routing with side-anchored arrowheads; card / chip / pill node styles;
/// a dot grid; a live minimap; a selection details panel with in/out value
/// stats; and an optional animated edge flow.
///
/// The data model (`MapNode` / `MapEdge` / `MapGraph`) is domain-neutral — the
/// five bundled `MapGraphData` seeds (cash-flow, mind-map, approval workflow,
/// accounting cycle, order-to-cash) all share one engine.
///
/// Architecture: Clean Architecture per feature
///   data/        — datasources (the five sample graphs)
///   domain/      — entities (MapNode, MapEdge, MapGraph, MapNodeKind),
///                  usecases (MapLogic geometry) — pure Dart
///   presentation/— controllers (SuperMapController = Model/state),
///                  painters + widgets + pages (the View)
///
/// Shared, cross-feature code lives in `lib/src/core/`.
///
/// Import this single barrel to get everything:
///   `import 'package:super_map/super_map.dart';`
library super_map;

// ── Core (theme tokens, shared widgets, utils) ──────────────────────────────
export 'src/core/core.dart';

// ── Features ────────────────────────────────────────────────────────────────
export 'src/features/super_map/super_map.dart';
