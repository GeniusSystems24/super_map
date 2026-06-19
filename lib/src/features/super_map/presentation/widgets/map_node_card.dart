// ============================================================
// features/super_map/presentation/widgets/map_node_card.dart
// ------------------------------------------------------------
// One node on the canvas — the View atom. Renders the card / chip / pill form
// for a [MapNode], owns its hover + inline-rename field, and reports pointer
// intents (select, drag, double-tap-rename, context menu) back to the host.
// Drag deltas are screen-space; the host divides by the zoom to move in world
// space. Styled entirely from SuperThemeData + the node's kind accent.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/entities/map_graph.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/usecases/map_logic.dart';

/// Compact value formatter shared with the details panel (642000 → "642K").
String _compact(num n) {
  final neg = n < 0 ? '-' : '';
  final a = n.abs();
  if (a >= 1e6) return '$neg${(a / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e3) return '$neg${(a / 1e3).round()}K';
  return '$neg${a.toStringAsFixed(0)}';
}

class MapNodeCard extends StatefulWidget {
  const MapNodeCard({
    super.key,
    required this.node,
    required this.size,
    required this.style,
    required this.editMode,
    required this.selected,
    required this.dimmed,
    required this.editing,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDoubleTap,
    required this.onContextMenu,
    required this.onHover,
    required this.onCommitRename,
    required this.onCancelRename,
    this.showData = false,
    this.stats,
    this.showNote = false,
    this.onNote,
  });

  final MapNode node;
  final Size size;
  final MapNodeStyle style;
  final bool editMode;
  final bool selected;
  final bool dimmed;
  final bool editing;

  /// When true, every node shows its own value / connection counts inline
  /// (v0.2.0 — "show all node data", not just the selected one).
  final bool showData;

  /// In/out connection summary for [showData] (resolved by the host).
  final NodeStats? stats;

  /// When true, a note button is shown on the card (always in edit mode, or in
  /// read mode when the node already carries a note).
  final bool showNote;
  final VoidCallback? onNote;

  final VoidCallback onSelect;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDoubleTap;
  final ValueChanged<Offset> onContextMenu; // global position
  final ValueChanged<bool> onHover;
  final ValueChanged<String> onCommitRename;
  final VoidCallback onCancelRename;

  @override
  State<MapNodeCard> createState() => _MapNodeCardState();
}

class _MapNodeCardState extends State<MapNodeCard> {
  TextEditingController? _ctl;
  FocusNode? _focus;

  @override
  void initState() {
    super.initState();
    if (widget.editing) _beginEdit();
  }

  @override
  void didUpdateWidget(MapNodeCard old) {
    super.didUpdateWidget(old);
    if (widget.editing && !old.editing) _beginEdit();
    if (!widget.editing && old.editing) _endEdit();
  }

  void _beginEdit() {
    _ctl = TextEditingController(text: widget.node.label)
      ..selection =
          TextSelection(baseOffset: 0, extentOffset: widget.node.label.length);
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus?.requestFocus());
  }

  void _endEdit() {
    _ctl?.dispose();
    _focus?.dispose();
    _ctl = null;
    _focus = null;
  }

  @override
  void dispose() {
    _ctl?.dispose();
    _focus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final accent = widget.node.accentOf(t);
    final isChip = widget.style != MapNodeStyle.card;

    final frame = widget.selected ? accent : t.borderStrong;
    final accentWidth = isChip ? 3.0 : 4.0;
    final decoration = BoxDecoration(
      color: t.surface,
      border: Border.all(color: frame),
      borderRadius: BorderRadius.circular(isChip ? 999 : SuperTokens.radiusMd),
      boxShadow: [
        ...t.cardShadow,
        if (widget.selected)
          BoxShadow(
              color: accent.withOpacity(0.30), blurRadius: 0, spreadRadius: 3),
      ],
    );

    Widget content = widget.editing ? _editor(t, accent) : _label(t, accent);

    final card = AnimatedOpacity(
      duration: SuperTokens.durBase,
      opacity: widget.dimmed ? 0.36 : 1,
      child: Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: accent),
                child: SizedBox(width: accentWidth),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isChip ? 14 : 13),
                child: Row(
                  children: [
                    if (!isChip) ...[
                      _IconBox(icon: widget.node.kind.icon, color: accent),
                      const SizedBox(width: 9),
                    ] else ...[
                      _Dot(color: accent),
                      const SizedBox(width: 9),
                    ],
                    Expanded(child: content),
                    if (!widget.editing) _statusLock(t),
                    if (widget.showData && !widget.editing)
                      _dataBadge(t, accent, isChip),
                    if (widget.showNote) ...[
                      const SizedBox(width: 6),
                      _NoteButton(
                        has: widget.node.note != null,
                        onTap: () => widget.onNote?.call(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor:
          widget.editMode ? SystemMouseCursors.move : SystemMouseCursors.grab,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        onDoubleTap: widget.editMode ? widget.onDoubleTap : null,
        onPanStart: (_) => widget.onDragStart(),
        onPanUpdate: (d) => widget.onDragUpdate(d.delta),
        onPanEnd: (_) => widget.onDragEnd(),
        onLongPressStart: (d) => widget.onContextMenu(d.globalPosition),
        onSecondaryTapDown: (d) => widget.onContextMenu(d.globalPosition),
        child: card,
      ),
    );
  }

  // Small workflow-status dot + audit-lock glyph cluster (v1.0.0). Renders
  // nothing when the node is in the default state and unlocked.
  Widget _statusLock(SuperThemeData t) {
    final node = widget.node;
    final showStatus = !node.status.isNone;
    if (!showStatus && !node.locked) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStatus)
            Tooltip(
              message: node.status.tag,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: node.status.colorOf(t),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (showStatus && node.locked) const SizedBox(width: 5),
          if (node.locked)
            Tooltip(
              message: 'Locked',
              child: Icon(Icons.lock_rounded, size: 13, color: t.fg3),
            ),
        ],
      ),
    );
  }

  Widget _dataBadge(SuperThemeData t, Color accent, bool isChip) {
    final value = widget.node.value;
    final s = widget.stats;
    final showDegree = !isChip && s != null && (s.inCount + s.outCount) > 0;
    if (value == null && !showDegree) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (value != null)
            Text(_compact(value),
                style: SuperText.mono.copyWith(
                    fontSize: isChip ? 10.5 : 11,
                    fontWeight: FontWeight.w700,
                    color: accent)),
          if (showDegree)
            Text('${s.inCount}→${s.outCount}',
                style: SuperText.mono.copyWith(fontSize: 9.5, color: t.fg4)),
        ],
      ),
    );
  }

  Widget _label(SuperThemeData t, Color accent) {
    final node = widget.node;
    final isChip = widget.style != MapNodeStyle.card;
    final secondary = node.ar != null
        ? Text(
            node.ar!,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SuperText.caption.copyWith(
              fontFamily: SuperTokens.arabicFont,
              fontSize: 11.5,
              color: t.fg4,
            ),
          )
        : (node.sub != null
            ? Text(
                node.sub!.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SuperText.pill.copyWith(fontSize: 10, color: t.fg4),
              )
            : null);

    final title = Text(
      node.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (isChip
              ? SuperText.caption.copyWith(fontSize: 12.5)
              : SuperText.body.copyWith(fontSize: 13.5))
          .copyWith(fontWeight: FontWeight.w700, color: t.fg1),
    );

    if (isChip || secondary == null) return title;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, const SizedBox(height: 1), secondary],
    );
  }

  Widget _editor(SuperThemeData t, Color accent) {
    return SizedBox(
      height: 26,
      child: TextField(
        controller: _ctl,
        focusNode: _focus,
        autofocus: true,
        cursorColor: accent,
        style: SuperText.body.copyWith(fontSize: 13, color: t.fg1),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          filled: true,
          fillColor: t.inputBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
        ),
        onSubmitted: widget.onCommitRename,
        onEditingComplete: () =>
            widget.onCommitRename(_ctl?.text ?? widget.node.label),
        onTapOutside: (_) =>
            widget.onCommitRename(_ctl?.text ?? widget.node.label),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
        ),
        child: Icon(icon, size: 16, color: color),
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// The small note button pinned to a node's top-(end) corner. Filled amber when
/// the node carries a note, hollow when empty (an affordance to add one).
class _NoteButton extends StatefulWidget {
  const _NoteButton({required this.has, required this.onTap});
  final bool has;
  final VoidCallback onTap;

  @override
  State<_NoteButton> createState() => _NoteButtonState();
}

class _NoteButtonState extends State<_NoteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // swallow drag so the note button never moves the node
        onPanStart: (_) {},
        child: Tooltip(
          message: widget.has ? 'View note' : 'Add note',
          child: Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.has
                  ? SuperTokens.warning
                  : (_hover ? t.hover : t.surface),
              shape: BoxShape.circle,
              border: Border.all(
                  color: widget.has ? SuperTokens.warning : t.borderStrong),
              boxShadow: t.cardShadow,
            ),
            child: Icon(Icons.sticky_note_2_outlined,
                size: 11, color: widget.has ? Colors.white : t.fg3),
          ),
        ),
      ),
    );
  }
}
