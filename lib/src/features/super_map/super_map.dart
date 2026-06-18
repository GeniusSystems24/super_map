// ============================================================
// features/super_map/super_map.dart
// ------------------------------------------------------------
// Public barrel for the SuperMap feature.
//
// SuperMap is a pannable / zoomable / draggable node-graph canvas with READ and
// EDIT modes: pan + zoom + drag + inspect in read; four-sided ports, add /
// rename / re-kind / duplicate / delete, edge editing, undo and JSON
// import/export in edit. The data model (`MapNode` / `MapEdge` / `MapGraph`) is
// domain-neutral — the five bundled `MapGraphData` seeds (cash-flow, mind-map,
// approval workflow, accounting cycle, order-to-cash) all share one engine.
// ============================================================

// Domain — entities
export 'domain/entities/map_node.dart';
export 'domain/entities/map_graph.dart';

// Domain — usecases
export 'domain/usecases/map_logic.dart';

// Data — sample datasource
export 'data/datasources/map_graph_data.dart';

// Presentation — controller (the Model)
export 'presentation/controllers/super_map_controller.dart';

// Presentation — painters
export 'presentation/painters/grid_painter.dart';
export 'presentation/painters/edge_painter.dart';

// Presentation — widgets (the View)
export 'presentation/widgets/map_node_card.dart';
export 'presentation/widgets/map_details_panel.dart';
export 'presentation/widgets/map_minimap.dart';
export 'presentation/widgets/map_context_menu.dart';
export 'presentation/widgets/map_json_sheet.dart';
export 'presentation/widgets/map_export_sheet.dart';
export 'presentation/widgets/map_note_popover.dart';
export 'presentation/widgets/super_map.dart';

// Presentation — pages
export 'presentation/pages/super_map_demo.dart';
