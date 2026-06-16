// ============================================================
// features/super_map/presentation/widgets/map_json_sheet.dart
// ------------------------------------------------------------
// The diagram-JSON dialog: a monospace editor over the current `{ meta, nodes,
// edges }` export. Apply re-generates the graph from the edited text; Copy
// drops it on the clipboard. A port of the React JsonModal (download is a
// no-op stub on platforms without a file system — Copy covers the common case).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';

/// Shows the JSON editor. Returns the edited text to apply, or null on cancel.
Future<String?> showMapJsonSheet(BuildContext context, String initial) {
  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x80000000),
    builder: (_) => _MapJsonSheet(initial: initial),
  );
}

class _MapJsonSheet extends StatefulWidget {
  const _MapJsonSheet({required this.initial});
  final String initial;

  @override
  State<_MapJsonSheet> createState() => _MapJsonSheetState();
}

class _MapJsonSheetState extends State<_MapJsonSheet> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Center(
      child: Material(
        color: const Color(0x00000000),
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.borderStrong),
            borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
            boxShadow: SuperThemeData.popShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 12, 15),
                child: Row(
                  children: [
                    const Icon(Icons.data_object_rounded, size: 17, color: SuperTokens.accent),
                    const SizedBox(width: 10),
                    Text('Diagram JSON', style: SuperText.heading.copyWith(fontSize: 15, color: t.fg1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('· edit & apply, or copy',
                          style: SuperText.caption.copyWith(color: t.fg3)),
                    ),
                    SuperIconButton(icon: Icons.close_rounded, onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              const Hairline(),
              Flexible(
                child: Container(
                  color: t.bg,
                  child: TextField(
                    controller: _ctl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: SuperText.mono.copyWith(fontSize: 12, color: t.fg1, height: 1.6),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                ),
              ),
              const Hairline(),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    SuperButton(
                      label: 'Copy',
                      variant: SuperButtonVariant.secondary,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => Clipboard.setData(ClipboardData(text: _ctl.text)),
                    ),
                    const Spacer(),
                    SuperButton(
                      label: 'Apply & generate',
                      icon: const Icon(Icons.check_rounded),
                      onPressed: () => Navigator.of(context).pop(_ctl.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
