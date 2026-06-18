// ============================================================
// features/super_map/presentation/widgets/map_note_popover.dart
// ------------------------------------------------------------
// The per-node note popover (v0.2.0). Anchored near a node's note button, it
// shows the node's memo and — in edit mode — a text field to write or clear it.
// A full-canvas barrier dismisses it on outside tap. Ported in spirit from the
// React note popover; styled entirely from SuperThemeData.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/entities/map_node.dart';

class MapNotePopover extends StatefulWidget {
  const MapNotePopover({
    super.key,
    required this.node,
    required this.editMode,
    required this.onClose,
    required this.onSave,
  });

  final MapNode node;
  final bool editMode;
  final VoidCallback onClose;
  final ValueChanged<String> onSave;

  @override
  State<MapNotePopover> createState() => _MapNotePopoverState();
}

class _MapNotePopoverState extends State<MapNotePopover> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.node.note ?? '');

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
        boxShadow: SuperThemeData.popShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: SuperTokens.warning),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 11, 13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined,
                        size: 14, color: SuperTokens.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('NOTE · ${widget.node.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SuperText.label.copyWith(fontSize: 10.5, color: t.fg3)),
                    ),
                    SuperIconButton(icon: Icons.close_rounded, onPressed: widget.onClose),
                  ],
                ),
                const SizedBox(height: 9),
                if (widget.editMode)
                  TextField(
                    controller: _ctl,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    style: SuperText.body.copyWith(fontSize: 12.5, height: 1.5, color: t.fg1),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Write a note for this node…',
                      hintStyle: SuperText.body.copyWith(fontSize: 12.5, color: t.fg4),
                      filled: true,
                      fillColor: t.inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
                        borderSide: const BorderSide(color: SuperTokens.accent, width: 1.5),
                      ),
                    ),
                    onChanged: widget.onSave,
                  )
                else
                  Text(
                    widget.node.note?.isNotEmpty == true
                        ? widget.node.note!
                        : 'No note on this node.',
                    style: SuperText.body.copyWith(
                        fontSize: 12.5,
                        height: 1.6,
                        color: widget.node.note?.isNotEmpty == true ? t.fg2 : t.fg4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
