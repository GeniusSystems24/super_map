// ============================================================
// core/core.dart — facade over the shared `super_core` foundation.
// ------------------------------------------------------------
// The GeniusLink theme tokens, `SuperThemeData`, text styles, formatters and
// design-system widgets now live in the standalone `super_core` package so the
// whole Super toolkit shares one identity. This file re-exports them — plus the
// SuperMap-specific `MapExporter` util — so the package's existing
// `import '.../core/core.dart';` call sites keep working.
// Features import from here, never from each other.
// ============================================================

export 'package:super_core/super_core.dart';

// SuperMap-specific export pipeline (stays in this package).
export 'utils/map_exporter.dart';
