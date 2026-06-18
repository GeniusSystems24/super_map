---
name: super-map
description: >
  Use the super_map Flutter package to build GeniusLink design-system node-graph
  / diagram canvases — SuperMap, a pannable, zoomable, draggable graph with READ
  and EDIT modes (pan/zoom/drag/inspect; ports to connect, add/rename/re-kind/
  recolour/duplicate/delete nodes, text-labelled connections, per-node notes,
  edge editing, undo, JSON import/export, image/PDF/Word export). Apply when a
  Flutter app needs a themed (light/dark, LTR/RTL) flow map, mind-map, org /
  approval workflow, accounting-cycle, topology or any node-and-edge diagram.
---

# Super Map — Agent Skill

`super_map` provides **`SuperMap`**, a pannable / zoomable / draggable
node-graph canvas with READ and EDIT modes, driven by a `SuperMapController`.
The data model is domain-neutral, so the same engine renders cash-flow maps,
mind-maps, workflows, accounting cycles, service topologies — any nodes + edges.
This skill tells you how to wire it correctly.

## When to use

- Any diagram / graph / flow-map UI in the GeniusLink visual language
  (dark-first ERP / accounting screens, bilingual English + Arabic).
- A cash-flow map, org / approval workflow, mind-map, accounting cycle,
  order-to-cash pipeline, dependency or service topology.
- Anywhere you need pan + zoom + draggable nodes + connect/edit + a minimap.

Do **not** hand-roll a `Stack` of `Positioned` boxes with a `CustomPaint` for
lines and your own pan/zoom math — use this component so theme, gestures,
routing, ports, undo, the minimap and RTL come for free.

## Install & setup

```yaml
dependencies:
  super_map:
    path: ../super_map
```

```dart
import 'package:super_map/super_map.dart';
```

Register the theme extension on your `ThemeData` (most common omission — without
it colors fall back to defaults):

```dart
theme:     ThemeData(brightness: Brightness.light, extensions: [SuperThemeData.light]),
darkTheme: ThemeData(brightness: Brightness.dark,  extensions: [SuperThemeData.dark]),
```

A `Material` ancestor must be in scope (a `Scaffold` is fine) — the inline
rename field and tooltips need it.

## The data model

A diagram is a `MapGraph` of `MapNode`s + `MapEdge`s:

```dart
const MapGraph(
  id: 'flow',
  title: 'Cash-flow map',
  ar: 'خريطة التدفّق النقدي',                 // optional Arabic title
  subtitle: 'How money moves through the entity.',
  legend: [MapNodeKind.income, MapNodeKind.hub, MapNodeKind.expense],
  nodes: [
    MapNode(id: 'retail',  x: 120, y: 80,  label: 'Retail Sales', ar: 'مبيعات التجزئة', kind: MapNodeKind.income, sub: 'Channel'),
    MapNode(id: 'company', x: 470, y: 290, label: 'GeniusLink Co.', kind: MapNodeKind.hub, sub: 'Operating entity'),
  ],
  edges: [
    MapEdge(id: 'e1', from: 'retail', to: 'company', value: 642000),
  ],
);
```

Rules:
- `MapNode.id` and `MapEdge.id` must be **unique** within the graph — they are
  the selection keys and edge endpoint references.
- `(x, y)` is the node **center** in an abstract world space. Don't worry about
  the viewport — the engine fits the whole graph to it on load.
- `kind` drives color + icon + tag. Pick from the 15 `MapNodeKind`s; neutral
  kinds (`leaf`, `document`) resolve their color against the theme.
- Put a `value` on a node or edge only when a number is meaningful — it surfaces
  in the details-panel stats and as an edge midpoint pill.
- **v0.2.0 fields:** `MapNode.color` (a custom accent overriding the kind —
  `node.accentOf(theme)` resolves it), `MapNode.note` (a free-text memo shown via
  the node's note button), and `MapEdge.label` (text naming the connection,
  rendered at the midpoint). All round-trip through `toJson`/`fromJson`.

## Driving it

`SuperMap` is a View over a `SuperMapController` (the Model):

```dart
final controller = SuperMapController(
  graph: MapGraphData.cashFlow,   // any MapGraph (bundled or your own)
  mode: MapMode.read,             // or MapMode.edit
  onSelectNode: (n) => inspect(n),
);

SuperMap(
  controller: controller,
  height: 540,
  showGrid: true,
  showMinimap: true,
  showEdgeLabels: true,
  showData: false,                // every node's value+degree inline + a list panel
  animateFlow: false,             // animated dashes along edges
  onExport: (bytes, filename, format) {  // PNG / PDF / DOCX bytes — you persist them
    // e.g. Printing.sharePdf(bytes: bytes, filename: filename);
  },
);
```

Switch styles / mode on the controller and the canvas reflows:
`controller.setMode(MapMode.edit)`, `controller.setNodeStyle(MapNodeStyle.chip)`,
`controller.setEdgeStyle(MapEdgeStyle.orthogonal)`. Programmatic edits:
`addEdge`, `deleteNode`, `setKind`, `setNodeColor(id, color)`, `setNote(id, text)`,
`setEdgeLabel(id, text)`, `loadGraph`, `importJson(text)`, `exportJson()`, `undo`.
Camera: `fitToView(size)`, `centerOn(id, size)`, `zoomAround(factor, focus)`.

## Export (v0.2.0)

The **Export** toolbar button captures the canvas and offers PNG / PDF / Word.
`MapExporter` does the work — `capturePng(repaintKey)`, `pngToPdf(...)`,
`pngToDocx(...)` — and the finished bytes arrive via `SuperMap.onExport(bytes,
filename, format)`. Persist them yourself (share sheet, file, web download); the
`printing` package's `Printing.sharePdf(bytes:, filename:)` is the simplest
cross-platform saver. The package depends on `pdf` + `archive` for assembly.

## Bundled seeds (fastest path)

`MapGraphData` ships five ready graphs that all share one engine —
`cashFlow`, `mindMap`, `approval`, `accountingCycle`, `orderToCash` (and
`MapGraphData.all`). `const SuperMapDemo()` is a ready-to-route page that
cycles all five with style toggles.

## Interaction model (automatic)

Read: drag canvas = pan · scroll / pinch = zoom · drag node = rearrange · tap =
select + inspect · tap a node's note button = read its note · right-click /
long-press = menu. Edit adds: drag a side **port** to connect · double-tap a node
= inline rename · double-tap an edge = inline label · `Delete`/`Backspace` =
remove the selection · context-menu = rename / note / colour / connect /
duplicate / change kind / label / delete · toolbar = node+edge style switchers /
Data / Add node / Undo / Export / JSON. Don't reimplement these — they ship in
`SuperMap`.

## Reusing the geometry

`MapLogic` is pure and widget-free — reuse it outside the widget for layout or
export: `sizeOf`, `sideAnchor`, `buildPath`, `geometry`, `bounds`, `neighbours`,
`incidentEdges`, `statsFor`, `nodeAt`, `distanceToPath`.

## Architecture (when extending)

Clean Architecture per feature under `lib/src/features/super_map/`:
`data/` (the five sample graphs) · `domain/` (`MapNode` / `MapEdge` / `MapGraph`
entities; `MapLogic` geometry — pure Dart) · `presentation/` (`controllers/` =
`SuperMapController` Model as a `ChangeNotifier`, `painters/` + `widgets/` +
`pages/` = View). Shared tokens/widgets live in `lib/src/core/`. Add new graph
algorithms in `domain/usecases/map_logic.dart`; keep the controller widget-free.

## Common mistakes

- Forgetting to register `SuperThemeData` → the canvas looks unstyled.
- Non-unique `MapNode.id` / `MapEdge.id` → broken selection, dragging and
  connecting; ids must be unique within the graph.
- Mutating the controller's nodes/edges lists in place instead of calling an
  intent method (`addNodeAt`, `moveNodeTo`, `setKind`, …) → no rebuild / no undo.
- Using `SuperMap` with no `Material`/`Scaffold` ancestor → the inline rename
  field and tooltips assert.
- Expecting world `(x, y)` to be screen pixels — they are abstract; the engine
  fits and the user pans/zooms from there. Call `fitToView` after a manual load.
