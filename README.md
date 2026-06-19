# super_map

A **GeniusLink design-system** Flutter package providing **`SuperMap`** — a pannable, zoomable, draggable **node-graph canvas** with **READ** and **EDIT** modes.

- **read** — pan (drag empty canvas), zoom (scroll / pinch), drag nodes to rearrange, tap to select + inspect, open per-node **notes**, right-click / long-press for a context menu.
- **edit** — everything in read, plus four-sided **connection ports** (drag to connect), **add / rename / re-kind / recolour / duplicate / delete** nodes, **text-label** connections, attach **notes**, switch node + edge styles in-canvas, **delete** edges, **undo** (depth 40), and **JSON import / export** that round-trips the whole diagram.

Extras: **per-node theme colours**, **text-labelled connections**, an **all-nodes data panel** (every node's stats at once), **image / PDF / Word / CSV export**, curved / orthogonal / straight **edge routing** with side-anchored arrowheads, **card / chip / pill** node styles, a **dot grid**, a live **minimap**, a selection **details panel** with in/out value stats + a Net figure, and an optional animated **edge flow**.

**Built for ERP & accounting diagrams.** v1.0.0 adds a domain layer over the canvas: a workflow **status** per node (`draft → pending → approved / posted / rejected`), an **audit lock** that pins posted records, a **source-record ref** + **audit metadata** map, a per-graph **currency**, toolbar **node search**, **auto-layout** (layered / grid / radial), an audit-grade **validator** (dangling / duplicate / self-loop / orphan / cycle + a double-entry flow-balance check), and **CSV export**.

The data model (`MapNode` / `MapEdge` / `MapGraph`) is **domain-neutral** — the five bundled `MapGraphData` seeds (cash-flow, mind-map, approval workflow, accounting cycle, order-to-cash) all share one engine. A faithful Dart port of the React `super-map` tool. Light + dark themes, LTR + RTL.

> **1.0.0** — the ERP release: workflow status, audit locks, source refs + metadata, per-graph currency, node search, layered/grid/radial auto-layout, a graph validator (incl. double-entry balance) and CSV export. Fully backward-compatible with 0.2.0 graphs. See the [changelog](CHANGELOG.md).

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
  showSearch: true,               // toolbar node search (v1.0.0)
  showValidate: true,             // toolbar Validate button (v1.0.0)
  showLayout: true,               // toolbar Layout menu in edit mode (v1.0.0)
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

- `MapNode` — a card centered at world `(x, y)` with an English `label`, an optional Arabic `ar`, an optional uppercase `sub` caption, a `kind`, an optional numeric `value`, an optional per-node `color` (overrides the kind accent — **v0.2.0**), and an optional `note` memo (**v0.2.0**). **v1.0.0** adds a workflow `status` ([`MapNodeStatus`](#erp-layer-v100)), an audit `locked` flag, a source-record `ref` (e.g. `JV-2024-0042`) and an ordered `meta` map of audit key/values. World coordinates are abstract; the engine **fits them to the viewport** on load. `node.accentOf(theme)` resolves the effective colour.
- `MapEdge` — a directed `from → to` connection with an optional numeric `value` and an optional text `label` naming the relationship (**v0.2.0**), both rendered at the midpoint.
- `MapGraph` — `id`, `title`, optional `ar` / `subtitle`, a `legend`, the `nodes` + `edges`, and a `currency` code (**v1.0.0**, default `SAR`) used to format value sums.
- `MapNodeKind` — 15 kinds (income, hub, expense, equity, topic, branch, leaf, process, role, approval, document, account, statement, party, payment), each with a brand color, an icon and a human tag. `kind.colorOf(theme)` resolves neutral kinds against the theme.

Both `MapNode` and `MapGraph` round-trip via `toJson()` / `fromJson()` — the same shape the in-canvas JSON editor reads and writes (`color` serialises as `#RRGGBB`; `status`, `locked`, `ref`, `meta` and `currency` round-trip too).

---

## ERP layer (v1.0.0)

The canvas stays domain-neutral, but these additions make it audit-grade for ledgers, settlements and approval flows.

### Workflow status, locks, refs & metadata

```dart
MapNode(
  id: 'jv', x: 0, y: 0, label: 'Journal Entry', ar: 'قيد يومية',
  kind: MapNodeKind.document,
  status: MapNodeStatus.posted,           // draft · pending · approved · posted · rejected · onHold
  locked: true,                           // audit-locked: resists move / re-kind / recolour / delete
  ref: 'JV-2024-0042',                    // source record, rendered monospace
  meta: {'Posted': '2024-03-14', 'By': 'A. Salem'},
  value: 5240,
);
```

A non-`none` status draws a coloured dot on the card and a pill in the details panel; a locked node shows a lock glyph. In edit mode the details panel exposes a **status picker** and a **lock toggle**, and the controller enforces locks (`setStatus`, `setLocked`, `setRef`, `setMeta`, `isLocked`). Value sums format against the graph's `currency`.

### Validation — `MapValidator`

Run the audit checks over any graph; press **Validate** in the toolbar to surface them in a tappable panel.

```dart
final issues = MapValidator.validate(graph);   // List<MapIssue>, errors first
final summary = MapValidator.summarise(graph); // counts by severity
```

Checks: **dangling edge** (missing endpoint), **duplicate node / edge id**, **self-loop**, **parallel edge**, **orphan node**, **directed cycle** (illegal in approval / accounting flows), and **flow imbalance** — a pass-through node whose incoming value sum ≠ outgoing sum beyond a tolerance (the double-entry / conservation check). Each `MapIssue` carries a `code`, `severity`, `message` and the `nodeId` / `edgeId` it anchors to.

### Auto-layout — `MapLayout`

Tidy a hand-built or freshly-imported diagram. Locked nodes keep their coordinates.

```dart
controller.autoLayout(const MapLayoutSpec(kind: MapLayoutKind.layered)); // layered · grid · radial
final tidy = MapLayout.apply(graph, const MapLayoutSpec(kind: MapLayoutKind.radial, rootId: 'root'));
```

- **layered** — longest-path ranks, left→right or top→down. Best for approval chains / document flows.
- **grid** — row-major in node order. A safe fallback for a bag of records.
- **radial** — a root at the centre, descendants on concentric rings by BFS depth.

The toolbar **Layout** button (edit mode) runs the same three.

### Node search

The toolbar search field filters across a node's label, Arabic name, sub-title, ref, note, kind, status and value; matches stay lit, the rest dim. Drive it from chrome with `controller.setQuery(...)`, `controller.matches`, `controller.hasQuery`, `controller.clearQuery()`.

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
| `Delete` / `Backspace` | — | delete the selection (locked nodes resist) |

The **details panel** shows the selected node's kind, **status** + **lock** pills, labels, the source **ref**, **audit metadata** rows, In / Out connection counts + value sums (in the graph's currency), the Net figure, and its note; in edit mode it adds a status picker, a lock toggle, and rename / note / clone / delete. Toggle **Data** in the toolbar (or `showData: true`) to surface **every** node's value + degree inline plus an all-nodes list panel — not just the selected one. The toolbar also carries **Search**, **Validate** and (in edit) **Layout**. The **JSON** button opens an editor over the live `{ meta, nodes, edges }` — edit and *Apply* to regenerate, or *Copy*.

---

## Export

The **Export** toolbar button rasterises the canvas and offers three formats, all produced by `MapExporter`:

| Format | How |
|---|---|
| **Image (PNG)** | a `RepaintBoundary` capture at 2.5× pixel ratio |
| **PDF** | the PNG embedded full-bleed on an auto-orientation A4 page (`package:pdf`) |
| **Word (.docx)** | the PNG wrapped in a minimal Office Open XML document (`package:archive`) |
| **CSV** | `MapExporter.nodesCsv(graph)` / `edgesCsv(graph)` — RFC-4180-quoted, Arabic-safe spreadsheet tables (**v1.0.0**) |

The image formats return **raw bytes** through your `onExport` callback so the package stays platform-agnostic — wire it to a share sheet, file picker or web download:

```dart
import 'package:printing/printing.dart';

SuperMap(
  controller: controller,
  onExport: (bytes, filename, format) =>
      Printing.sharePdf(bytes: bytes, filename: filename), // works on mobile / desktop / web
);
```

For spreadsheets, call `MapExporter` directly and save the bytes (BOM-prefixed UTF-8 so Excel reads Arabic columns):

```dart
final csv   = MapExporter.nodesCsv(controller.toGraph());
final bytes = MapExporter.csvBytes(csv); // Uint8List ready to write to a .csv
```

Or call the image helpers directly: `capturePng(key)`, `pngToPdf(png, …)`, `pngToDocx(png, …)`.

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
            │   ├── entities/             # MapNode, MapEdge, MapGraph, MapNodeKind, MapNodeStatus
            │   └── usecases/             # MapLogic (geometry), MapValidator, MapLayout — pure Dart
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

A runnable gallery lives in `example/` — it registers the theme extension, toggles light/dark and LTR/RTL, and links **thirteen** demos that share **one** engine:

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
- **6 · ERP workflow** — status, audit lock, source ref + metadata and currency on a journal-entry approval chain (**v1.0.0**).
- **7 · Validation** — a deliberately broken graph exercising every `MapValidator` check incl. the flow-balance test (**v1.0.0**).
- **8 · Auto-layout** — layered / grid / radial via `MapLayout` (**v1.0.0**).
- **9 · CSV export** — `MapExporter.nodesCsv` / `edgesCsv` spreadsheet output (**v1.0.0**).
- **10 · Node search** — filter + dim a dense diagram from the toolbar (**v1.0.0**).
- **11 · Audit locks** — pinned posted records that resist edits (**v1.0.0**).

---

## License

Internal GeniusLink design-system package.
