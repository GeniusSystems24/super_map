// ============================================================
// features/super_map/presentation/widgets/map_context_menu.dart
// ------------------------------------------------------------
// The right-click / long-press context menu — a floating surface card with a
// title, a list of [MapMenuItem]s, and (for nodes in edit mode) an expandable
// "Change kind" grid of the 15 kinds. The host positions it; a full-canvas
// barrier behind it dismisses on outside tap. A port of the React ContextMenu.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/entities/map_node.dart';

/// One row in a [MapContextMenu].
class MapMenuItem extends StatefulWidget {
  const MapMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.kbd,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final String? kbd;

  @override
  State<MapMenuItem> createState() => _MapMenuItemState();
}

class _MapMenuItemState extends State<MapMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final fg = widget.danger ? SuperTokens.danger : t.fg1;
    final bg = _hover
        ? (widget.danger ? t.tintFill(SuperTokens.danger, 0.12) : t.hover)
        : const Color(0x00000000);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 32,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.label, style: SuperText.caption.copyWith(fontSize: 12.5, color: fg))),
              if (widget.kbd != null)
                Text(widget.kbd!, style: SuperText.mono.copyWith(fontSize: 10.5, color: t.fg4)),
            ],
          ),
        ),
      ),
    );
  }
}

class MapContextMenu extends StatefulWidget {
  const MapContextMenu({
    super.key,
    this.title,
    required this.items,
    this.currentKind,
    this.onPickKind,
  });

  final String? title;
  final List<Widget> items;

  /// When non-null, prepends a "Change kind" expander + a kind grid.
  final MapNodeKind? currentKind;
  final ValueChanged<MapNodeKind>? onPickKind;

  static const double width = 200;

  @override
  State<MapContextMenu> createState() => _MapContextMenuState();
}

class _MapContextMenuState extends State<MapContextMenu> {
  bool _showKinds = false;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      width: MapContextMenu.width,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
        boxShadow: SuperThemeData.popShadow,
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 7),
              child: Text(
                widget.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SuperText.label.copyWith(fontSize: 10.5, color: t.fg3),
              ),
            ),
          if (widget.title != null) const Hairline(),
          if (widget.onPickKind != null) ...[
            MapMenuItem(
              icon: Icons.grid_view_rounded,
              label: _showKinds ? 'Pick a kind…' : 'Change kind',
              onTap: () => setState(() => _showKinds = !_showKinds),
            ),
            if (_showKinds) _kindGrid(t),
          ],
          ...widget.items,
        ],
      ),
    );
  }

  Widget _kindGrid(SuperThemeData t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final k in MapNodeKind.values)
            _KindChip(
              kind: k,
              selected: widget.currentKind == k,
              onTap: () => widget.onPickKind!(k),
            ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind, required this.selected, required this.onTap});
  final MapNodeKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final accent = kind.colorOf(t);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: (MapContextMenu.width - 12 - 2) / 2,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: selected ? t.tintFill(accent, 0.14) : const Color(0x00000000),
          border: Border.all(color: selected ? accent : t.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(kind.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SuperText.caption.copyWith(fontSize: 10.5, color: t.fg2)),
            ),
          ],
        ),
      ),
    );
  }
}
