// ============================================================
// features/super_map/presentation/widgets/map_details_panel.dart
// ------------------------------------------------------------
// The selection inspector — a 240px floating card that appears when a node is
// selected. Shows the kind accent bar, icon, English + Arabic labels, the kind
// tag pill, an In / Out stat grid (count + value sum), the Net figure, and (in
// edit mode) rename / clone / delete actions. A port of the React details panel.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/usecases/map_logic.dart';

/// Compact SAR-style value formatter: 642000 → "642K", 1.2M → "1.20M".
String mapCompact(num n) {
  final neg = n < 0 ? '-' : '';
  final a = n.abs();
  if (a >= 1e6) return '$neg${(a / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e3) return '$neg${(a / 1e3).round()}K';
  return '$neg${a.toStringAsFixed(0)}';
}

class MapDetailsPanel extends StatelessWidget {
  const MapDetailsPanel({
    super.key,
    required this.node,
    required this.stats,
    required this.editMode,
    required this.onClose,
    required this.onRename,
    required this.onClone,
    required this.onDelete,
    this.onNote,
  });

  final MapNode node;
  final NodeStats stats;
  final bool editMode;
  final VoidCallback onClose;
  final VoidCallback onRename;
  final VoidCallback onClone;
  final VoidCallback onDelete;
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final accent = node.accentOf(t);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(SuperTokens.radiusMd),
        boxShadow: t.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
                      ),
                      child: Icon(node.kind.icon, size: 16, color: accent),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node.label,
                              style: SuperText.body
                                  .copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: t.fg1)),
                          if (node.ar != null)
                            Text(node.ar!,
                                textDirection: TextDirection.rtl,
                                style: SuperText.caption.copyWith(
                                    fontFamily: SuperTokens.arabicFont, color: t.fg3)),
                        ],
                      ),
                    ),
                    SuperIconButton(icon: Icons.close_rounded, onPressed: onClose),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusPill(node.kind.tag, tone: _toneFor(node.kind, accent)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _Stat(label: 'In', value: '${stats.inCount}', sub: stats.inSum > 0 ? '${mapCompact(stats.inSum)} SAR' : null)),
                    const SizedBox(width: 8),
                    Expanded(child: _Stat(label: 'Out', value: '${stats.outCount}', sub: stats.outSum > 0 ? '${mapCompact(stats.outSum)} SAR' : null)),
                  ],
                ),
                if (stats.inSum > 0 || stats.outSum > 0) ...[
                  const SizedBox(height: 9),
                  const Hairline(),
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NET', style: SuperText.label.copyWith(color: t.fg3)),
                      Text(mapCompact(stats.net),
                          style: SuperText.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: t.fg1)),
                    ],
                  ),
                ],
                if (node.note != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.tintFill(SuperTokens.warning, 0.08),
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sticky_note_2_outlined, size: 13, color: SuperTokens.warning),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(node.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SuperText.caption.copyWith(fontSize: 11.5, color: t.fg2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (editMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SuperButton(
                          label: 'Rename',
                          variant: SuperButtonVariant.secondary,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: onRename,
                        ),
                      ),
                      const SizedBox(width: 7),
                      SuperIconButton(
                          icon: Icons.sticky_note_2_outlined,
                          tooltip: node.note != null ? 'Edit note' : 'Add note',
                          onPressed: onNote ?? () {}),
                      const SizedBox(width: 7),
                      SuperIconButton(icon: Icons.copy_rounded, tooltip: 'Clone', onPressed: onClone),
                      const SizedBox(width: 7),
                      SuperIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', danger: true, onPressed: onDelete),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PillTone _toneFor(MapNodeKind kind, Color accent) {
    if (accent == SuperTokens.success) return PillTone.success;
    if (accent == SuperTokens.warning) return PillTone.warning;
    if (accent == SuperTokens.danger) return PillTone.danger;
    if (accent == SuperTokens.accent) return PillTone.accent;
    return PillTone.neutral;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.inputBg,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: SuperText.pill.copyWith(fontSize: 9.5, color: t.fg3)),
          Text(value, style: SuperText.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: t.fg1)),
          if (sub != null) Text(sub!, style: SuperText.mono.copyWith(fontSize: 10, color: t.fg4)),
        ],
      ),
    );
  }
}
