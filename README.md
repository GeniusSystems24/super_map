# super_map

A **GeniusLink design-system** Flutter package providing **`SuperMap`** — a pannable, zoomable, draggable **node-graph canvas** with **READ** and **EDIT** modes.

- **read** — pan (drag empty canvas), zoom (scroll / pinch), drag nodes to rearrange, tap to select + inspect, open per-node **notes**, right-click / long-press for a context menu.
- **edit** — everything in read, plus four-sided **connection ports** (drag to connect), **add / rename / re-kind / recolour / duplicate / delete** nodes, **text-label** connections, attach **notes**, switch node + edge styles in-canvas, **delete** edges, **undo** (depth 40), and **JSON import / export** that round-trips the whole diagram.

Extras: **per-node theme colours**, **text-labelled connections**, an **all-nodes data panel** (every node's stats at once), **image / PDF / Word export**, curved / orthogonal / straight **edge routing** with side-anchored arrowheads, **card / chip / pill** node styles, a **dot grid**, a live **minimap**, a selection **details panel** with in/out value stats + a Net figure, and an optional animated **edge flow**.

The data model (`MapNode` / `MapEdge` / `MapGraph`) is **domain-neutral** — the five bundled `MapGraphData` seeds (cash-flow, mind-map, approval workflow, accounting cycle, order-to-cash) all share one engine. A faithful Dart port of the React `super-map` tool. Light + dark themes, LTR + RTL.

> **0.2.0** adds per-node colours & notes, text labels on connections, an all-nodes data panel, in-canvas style switchers, and image / PDF / Word export. See the [changelog](CHANGELOG.md).

---

## Install

```yaml
# pubspec.yaml
dependencies:
  super_map:
    path: ../super_map   # or a git/hosted ref
```

```dart
import 'package:super_map/super_map.dart';
```

### Register the theme extension

`SuperMap` themes through a `ThemeExtension`. Register it once on your `ThemeData` so colors track light/dark:

```dart
MaterialApp(
  theme:     ThemeData(brightness: Brightness.light, extensions: [SuperThemeData.light]),
  darkTheme: ThemeData(brightness: Brightness.dark,  extensions: [SuperThemeData.dark]),
);
```

> Fonts: the design system uses Manrope (display), Inter (body), JetBrains Mono (numerics) and Noto Naskh Arabic. Drop the `.ttf` files under `assets/fonts/` and uncomment the `fonts:` block in `pubspec.yaml` to match it exactly; otherwise platform defaults are used.

---

## Quick start

`SuperMap` is driven by a `SuperMapController` (the Model). Give it a `MapGraph` and drop the widget into the tree:

```dart
final controller = SuperMapController(
  graph: MapGraphData.cashFlow,   // any MapGraph
  mode: MapMode.read,             // or MapMode.edit
);

SuperMap(
  controller: controller,
  height: 540,
  showMinimap: true,
  showEdgeLabels: true,
  showData: false,                // show every node's value/degree inline
  animateFlow: false,
  onExport: (bytes, filename, format) { /* save / share the bytes */ },
);
```

…or route the ready-made showcase page (five seeds + style toggles):

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const SuperMapDemo()),
);
```

---

## The data model

A diagram is a `MapGraph` of positioned `MapNode`s and directed `MapEdge`s:

```dart
const MapGraph(
  id: 'services',
  title: 'Service topology',
  subtitle: 'The gateway fans out to services that share a database.',
  legend: [MapNodeKind.hub, MapNodeKind.process, MapNodeKind.account],
  nodes: [
    MapNode(id: 'gw', x: 120, y: 240, label: 'API Gateway', kind: MapNodeKind.hub, sub: 'Edge'),
    MapNode(id: 'orders', x: 420, y: 240, label: 'Orders Service', ar: 'خدمة الطلبات', kind: MapNodeKind.process,
            color: Color(0xFFF97316), note: 'Owns the order lifecycle.'),
    MapNode(id: 'db', x: 740, y: 240, label: 'Postgres', kind: MapNodeKind.account, value: 184000),
  ],
  edges: [
    MapEdge(id: 'e1', from: 'gw', to: 'orders', label: 'routes'),
    MapEdge(id: 'e2', from: 'orders', to: 'db', value: 184000, label: 'writes'),
  ],
);
```

- `MapNode` — a card centered at world `(x, y)` with an English `label`, an optional Arabic `ar`, an optional uppercase `sub` caption, a `kind`, an optional numeric `value`, an optional per-node `color` (overrides the kind accent — **v0.2.0**), and an optional `note` memo (**v0.2.0**). World coordinates are abstract; the engine **fits them to the viewport** on load. `node.accentOf(theme)` resolves the effective colour.
- `MapEdge` — a directed `from → to` connection with an optional numeric `value` and an optional text `label` naming the relationship (**v0.2.0**), both rendered at the midpoint.
- `MapNodeKind` — 15 kinds (income, hub, expense, equity, topic, branch, leaf, process, role, approval, document, account, statement, party, payment), each with a brand color, an icon and a human tag. `kind.colorOf(theme)` resolves neutral kinds against the theme.

Both `MapNode` and `MapGraph` round-trip via `toJson()` / `fromJson()` — the same shape the in-canvas JSON editor reads and writes (`color` serialises as `#RRGGBB`).

---

## Node styles & edge routing

| Node style | Form |
|---|---|
| `MapNodeStyle.card` | icon + label + secondary line (default) |
| `MapNodeStyle.chip` | compact chip with a colored dot |
| `MapNodeStyle.pill` | elongated pill with a colored dot |

| Edge style | Routing |
|---|---|
| `MapEdgeStyle.curved` | Bézier curves that adapt to facing sides (default) |
| `MapEdgeStyle.orthogonal` | right-angled segments |
| `MapEdgeStyle.straight` | direct lines |

Set them on the controller — `controller.setNodeStyle(...)`, `controller.setEdgeStyle(...)` — and the canvas reflows.

---

## Interaction model

| Gesture | Read | Edit |
|---|---|---|
| Drag empty canvas | pan | pan |
| Scroll / pinch | zoom (around the pointer) | zoom |
| Drag a node | rearrange | rearrange |
| Tap a node / edge | select + inspect | select |
| Double-tap a node | — | inline rename |
| Double-tap a connection | — | inline label |
| Tap a node's **note** button | view note | view / edit note |
| Drag a side **port** | — | connect to another node |
| Right-click / long-press | inspect / center menu | full action menu (rename · note · colour · kind · label · delete) |
| `Delete` / `Backspace` | — | delete the selection |

The **details panel** shows the selected node's kind, labels, In / Out connection counts + value sums, the Net figure, and its note; in edit mode it adds rename / note / clone / delete. Toggle **Data** in the toolbar (or `showData: true`) to surface **every** node's value + degree inline plus an all-nodes list panel — not just the selected one. The **JSON** button opens an editor over the live `{ meta, nodes, edges }` — edit and *Apply* to regenerate, or *Copy*.

---

## Export

The **Export** toolbar button rasterises the canvas and offers three formats, all produced by `MapExporter`:

| Format | How |
|---|---|
| **Image (PNG)** | a `RepaintBoundary` capture at 2.5× pixel ratio |
| **PDF** | the PNG embedded full-bleed on an auto-orientation A4 page (`package:pdf`) |
| **Word (.docx)** | the PNG wrapped in a minimal Office Open XML document (`package:archive`) |

Every format returns **raw bytes** through your `onExport` callback so the package stays platform-agnostic — wire it to a share sheet, file picker or web download:

```dart
import 'package:printing/printing.dart';

SuperMap(
  controller: controller,
  onExport: (bytes, filename, format) =>
      Printing.sharePdf(bytes: bytes, filename: filename), // works on mobile / desktop / web
);
```

Or call `MapExporter` directly: `capturePng(key)`, `pngToPdf(png, …)`, `pngToDocx(png, …)`.

---

## Architecture

Clean Architecture, MVC-aligned, split per feature:

```
lib/
├── super_map.dart                        # public barrel — import this
└── src/
    ├── core/                             # shared tokens, widgets, utils, extensions
    └── features/
        └── super_map/
            ├── data/
            │   └── datasources/          # MapGraphData (five sample graphs)
            ├── domain/
            │   ├── entities/             # MapNode, MapEdge, MapGraph, MapNodeKind
            │   └── usecases/             # MapLogic (geometry, routing, bounds, stats) — pure Dart
            └── presentation/
                ├── controllers/          # SuperMapController (the Model/state)
                ├── painters/             # GridPainter, EdgePainter
                ├── widgets/              # SuperMap, MapNodeCard, details / minimap / menu / json
                └── pages/                # SuperMapDemo
```

- **Model** — `SuperMapController` is a `ChangeNotifier` holding the view transform, nodes/edges, selection, hover, rename + link drafts, mode, styles, the undo history and a toast. It imports no widget.
- **View** — `SuperMap` (+ atoms) observes the controller and renders; painters draw the grid + edges; node cards forward pointer intents back.
- **Domain** — `MapNode` / `MapEdge` / `MapGraph` and `MapLogic` are pure Dart (`dart:ui` geometry only), no Flutter UI.

---

## Example

A runnable gallery lives in `example/` — it registers the theme extension, toggles light/dark and LTR/RTL, and links seven demos that share **one** engine:

```bash
cd example
flutter run
```

- **Sample Graphs** — the five `MapGraphData` seeds with read/edit + node/edge style + data toggles (`SuperMapDemo`).
- **Custom Graph** — a hand-built `MapGraph` wired straight into `SuperMap`.
- **1 · Minimal (read)** — the shortest path: a 3-node, toolbar-less read-only canvas.
- **2 · Editable + Export** — edit mode with Image / PDF / Word export wired to `printing`.
- **3 · Colours · labels · notes** — the v0.2.0 expressive features on a hand-built graph.
- **4 · Controller-driven** — driving the canvas from app chrome via controller intents.
- **5 · JSON-driven** — parsing a graph from a JSON string with `MapGraph.fromJson`.

---

## License

Internal GeniusLink design-system package.
