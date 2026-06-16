# Changelog

All notable changes to **super_map** are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versioning is [SemVer](https://semver.org/).

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
