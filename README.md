# super_map

A **GeniusLink design-system** Flutter package providing **`SuperMap`** — a pannable, zoomable, draggable **node-graph canvas** with **READ** and **EDIT** modes.

- **read** — pan (drag empty canvas), zoom (scroll / pinch), drag nodes to rearrange, tap to select + inspect, right-click / long-press for a context menu.
- **edit** — everything in read, plus four-sided **connection ports** (drag to connect), **add / rename / re-kind / duplicate / delete** nodes, **delete** edges, **undo** (depth 40), and **JSON import / export** that round-trips the whole diagram.

Extras: curved / orthogonal / straight **edge routing** with side-anchored arrowheads, **card / chip / pill** node styles, a **dot grid**, a live **minimap**, a selection **details panel** with in/out value stats + a Net figure, and an optional animated **edge flow**.

The data model (`MapNode` / `MapEdge` / `MapGraph`) is **domain-neutral** — the five bundled `MapGraphData` seeds (cash-flow, mind-map, approval workflow, accounting cycle, order-to-cash) all share one engine. A faithful Dart port of the React `super-map` tool. Light + dark themes, LTR + RTL.

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
  animateFlow: false,
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
    MapNode(id: 'orders', x: 420, y: 240, label: 'Orders Service', ar: 'خدمة الطلبات', kind: MapNodeKind.process),
    MapNode(id: 'db', x: 740, y: 240, label: 'Postgres', kind: MapNodeKind.account, value: 184000),
  ],
  edges: [
    MapEdge(id: 'e1', from: 'gw', to: 'orders'),
    MapEdge(id: 'e2', from: 'orders', to: 'db', value: 184000),
  ],
);
```

- `MapNode` — a card centered at world `(x, y)` with an English `label`, an optional Arabic `ar`, an optional uppercase `sub` caption, a `kind`, and an optional numeric `value`. World coordinates are abstract; the engine **fits them to the viewport** on load.
- `MapEdge` — a directed `from → to` connection with an optional `value` rendered as a midpoint pill.
- `MapNodeKind` — 15 kinds (income, hub, expense, equity, topic, branch, leaf, process, role, approval, document, account, statement, party, payment), each with a brand color, an icon and a human tag. `kind.colorOf(theme)` resolves neutral kinds against the theme.

Both `MapNode` and `MapGraph` round-trip via `toJson()` / `fromJson()` — the same shape the in-canvas JSON editor reads and writes.

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
| Drag a side **port** | — | connect to another node |
| Right-click / long-press | inspect / center menu | full action menu |
| `Delete` / `Backspace` | — | delete the selection |

The **details panel** shows the selected node's kind, labels, In / Out connection counts + value sums, and the Net figure; in edit mode it adds rename / clone / delete. The **JSON** toolbar button opens an editor over the live `{ meta, nodes, edges }` — edit and *Apply* to regenerate, or *Copy*.

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

A runnable gallery lives in `example/` — it registers the theme extension, toggles light/dark and LTR/RTL, and links two demos that share **one** engine:

```bash
cd example
flutter run
```

- **Sample Graphs** — the five `MapGraphData` seeds with read/edit + node/edge style toggles (`SuperMapDemo`).
- **Custom Graph** — a hand-built `MapGraph` wired straight into `SuperMap`.

---

## License

Internal GeniusLink design-system package.
