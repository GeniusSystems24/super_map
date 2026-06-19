# Changelog

All notable changes to **super_map** are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versioning is [SemVer](https://semver.org/).

## [1.0.0] — 2026-06-19

The **ERP release** — a domain layer over the node-graph canvas for audit-grade
ledger, settlement and approval diagrams. Fully backward-compatible: every
0.2.0 graph, controller call and widget keeps working unchanged.

### Added
- **Workflow status** — `MapNode.status` (`MapNodeStatus`: none · draft · pending
  · approved · posted · rejected · onHold) tracks where a record stands in a
  process, independent of its semantic `kind`. A coloured status dot appears on
  the card and a status pill in the details panel; edit mode gets an inline
  status picker. Set with `SuperMapController.setStatus`.
- **Audit locks** — `MapNode.locked` pins a posted/approved record: the
  controller refuses to move, re-kind, recolour, re-ref or delete it and toasts
  "Node is locked". The card shows a lock glyph; the details panel shows a
  Locked pill and a lock toggle. `setLocked` / `isLocked` on the controller.
- **Source refs & audit metadata** — `MapNode.ref` (e.g. `JV-2024-0042`, rendered
  monospace) ties a node to its source ERP record; `MapNode.meta` is an ordered
  key→value map surfaced as rows in the details panel. `setRef` / `setMeta`.
- **Per-graph currency** — `MapGraph.currency` (default `SAR`) formats every
  value sum in the details panel and CSV export; round-trips through JSON `meta`.
- **`MapValidator`** — an audit-grade graph validator (pure Dart). Detects
  dangling edges, duplicate node/edge ids, self-loops, parallel edges, orphan
  nodes, **directed cycles**, and **flow imbalance** (a pass-through node whose
  incoming value sum ≠ outgoing sum — the double-entry/conservation check).
  Returns ordered `MapIssue`s (errors first); `validate()` / `summarise()`. The
  toolbar **Validate** button opens a tappable issues panel that jumps to the
  offending node/edge.
- **`MapLayout`** — deterministic auto-layout (pure Dart): **layered** (longest-
  path ranks, L→R or T→B), **grid** (row-major) and **radial** (BFS rings from a
  root). Locked nodes keep their coordinates. `controller.autoLayout(spec)` and
  the edit-toolbar **Layout** menu.
- **Node search** — a toolbar search field filters across a node's label, Arabic
  name, sub, ref, note, kind, status and value; matches stay lit, the rest dim.
  `setQuery` / `matches` / `hasQuery` / `clearQuery` on the controller; toggle
  with `SuperMap(showSearch: …)`.
- **CSV export** — `MapExporter.nodesCsv(graph)` and `edgesCsv(graph)` emit
  RFC-4180-quoted, Arabic-safe spreadsheet tables; `csvBytes(csv)` wraps a string
  as BOM-prefixed UTF-8. `MapExportFormat.csv` joins the format enum.
- **Six new examples** — `06_erp_workflow`, `07_validation`, `08_auto_layout`,
  `09_csv_export`, `10_search`, `11_audit_locks` — registered in the gallery.

### Changed
- `MapNode.copyWith` / `toJson` / `fromJson` carry the new `status`, `locked`,
  `ref` and `meta` fields (all optional; omitted when default).
- `MapGraph.toJson` writes `meta.currency`; `fromJson` reads it.
- The details panel takes a `currency` and optional `onToggleLock` /
  `onSetStatus` hooks (defaulted, so existing call sites are unaffected).
- `SuperMap` gains `showSearch`, `showValidate`, `showLayout` flags (all
  default `true`).

## [0.2.0] — 2026-06-18

### Added
- **Per-node theme colour** — `MapNode.color` overrides the kind accent without
  changing the node's semantic kind. Picked from a curated brand palette via the
  node context menu (edit) or set programmatically with
  `SuperMapController.setNodeColor`. `node.accentOf(theme)` resolves the
  effective colour; serialises as `#RRGGBB`.
- **Per-node notes** — `MapNode.note` attaches a free-text memo. Every node shows
  a note button (filled amber when a note exists); pressing it opens a popover
  that reads the note in read mode and edits it in edit mode. Surfaced in the
  details panel; settable with `setNote`.
- **Text-labelled connections** — `MapEdge.label` names a connection's meaning
  (e.g. "Revenue", "Settles"). Rendered as a pill at the edge midpoint above any
  numeric value; double-click an edge (or use the menu) to edit inline.
  `startEdgeLabel` / `commitEdgeLabel` / `setEdgeLabel` on the controller.
- **All-nodes data panel** — a new `showData` flag (and toolbar **Data** toggle)
  renders every node's value + in/out degree inline *and* opens a scrollable
  list of all nodes with their stats — fixing the previous behaviour where data
  only appeared for the selected node. Tapping a row selects + centers it.
- **In-canvas style switchers** — node-style (card / chip / pill) and
  edge-routing (curved / orthogonal / straight) segmented controls now sit in the
  edit toolbar, so the drawing style of the connecting lines is changeable
  without leaving the canvas.
- **Export** — `MapExporter` + an Export chooser produce **PNG** (RepaintBoundary
  capture), **PDF** (`package:pdf`) and **Word .docx** (`package:archive`) from
  the live diagram. Bytes are handed back through the new `SuperMap.onExport`
  callback so the host owns persistence (share sheet / file / web download).
- **Animated flow** now adds a pulse dot travelling source → target along each
  connection (on top of the marching-ants dashes) when `animateFlow` is on,
  respecting `prefers-reduced-motion`.
- Five new runnable examples (`example/lib/examples/`): minimal read-only,
  editable + export, colours/labels/notes, controller-driven, and JSON-driven.

### Changed
- The cash-flow seed now carries node values, edge labels and a note to
  demonstrate the new fields.
- The edge painter, minimap and details panel resolve node accents through
  `accentOf` so custom colours apply everywhere.
- Dependencies: added `pdf` and `archive` for the export pipeline.

### Fixed
- **Node drag is now undoable** — a single history snapshot is taken on the first
  real move (not on a click), so dragging, deleting and duplicating all restore
  cleanly with undo.
- `duplicateNode` rebuilt to copy every field (including colour + note) into a
  fresh id in one step, removing the transient duplicate-id intermediate.
- Read-mode panning and node movement hardened against accidental
  selection/drag conflicts.

## [0.1.0] — 2026-06-16

### Added
- Initial release, extracted as a focused package from `super_toolkit` and
  ported from the React `super-map` tool.
- **`SuperMap`** — a pannable / zoomable / draggable node-graph canvas with
  READ and EDIT modes. Read: pan (drag canvas), zoom (scroll / pinch around the
  pointer), drag nodes, tap to select + inspect, right-click / long-press menu.
  Edit: four-sided **ports** (drag to connect), add / rename (inline) / re-kind /
  duplicate / delete nodes, delete edges, undo, and JSON import/export. Overlays:
  fit / reset controls, a title + zoom chip, a zoom cluster, a dot grid, a live
  minimap, a selection details panel and a transient toast.
- **`SuperMapController`** — the `ChangeNotifier` Model: the view transform
  (pan offset + zoom), live nodes + edges, selection (node / edge), hover, the
  in-progress rename + link drafts, mode, node/edge render styles, an undo
  history (depth 40) and a toast, plus widget-free intent methods
  (`panBy`/`zoomAround`/`fitToView`/`centerOn`, `moveNodeTo`, `addNodeAt`,
  `duplicateNode`, `deleteNode`, `setKind`, `startRename`/`commitRename`,
  `addEdge`/`deleteEdge`, `startLink`/`updateLink`/`endLink`, `undo`,
  `loadGraph`/`replaceGraph`/`reset`, `exportJson`/`importJson`).
- **Data model** — `MapNode` (world position, English + optional Arabic labels,
  uppercase caption, kind, optional value), `MapEdge` (directed, optional value),
  `MapGraph` (titled node/edge set + legend), and `MapNodeKind` (15 kinds, each
  with a brand color / icon / tag). All round-trip via `toJson` / `fromJson`.
- **`MapLogic`** — pure, widget-free geometry: per-style node sizing, side
  anchoring, curved / orthogonal / straight path routing, graph bounds,
  neighbour / incident sets, per-node in/out stats, node hit-testing and a
  point-to-path distance for edge picking.
- **`MapGraphData`** — five bundled sample graphs sharing one engine: cash-flow,
  strategy mind-map, purchase-approval workflow, accounting cycle, order-to-cash.
- **Node styles** (card / chip / pill) and **edge routing** (curved / orthogonal
  / straight); optional animated edge **flow** that respects reduced-motion.
- `SuperThemeData` `ThemeExtension` with light + dark variants; full LTR + RTL
  support (chrome flips; the diagram itself is not mirrored).
- Runnable `example/` gallery with light/dark + LTR/RTL toggles and two demos:
  the five-seed `SuperMapDemo` and a hand-built custom graph.
- `README.md` and `SKILL.md` (agent usage guide).
