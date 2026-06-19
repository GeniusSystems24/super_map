// ============================================================
// features/super_map/presentation/widgets/map_details_panel.dart
// ------------------------------------------------------------
// The selection inspector — a 240px floating card that appears when a node is
// selected. Shows the kind accent bar, icon, English + Arabic labels, the kind
// tag pill, an In / Out stat grid (count + value sum), the Net figure, and (in
// edit mode) rename / clone / delete actions. A port of the React details panel.
//
// v1.0.0 adds the ERP overlay: a workflow status pill, the source-record `ref`
// (monospace), the audit `meta` rows, a configurable `currency` code, and (in
// edit mode) a lock toggle + a status picker.
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
    this.currency = 'SAR',
    this.onToggleLock,
    this.onSetStatus,
  });

  final MapNode node;
  final NodeStats stats;
  final bool editMode;
  final VoidCallback onClose;
  final VoidCallback onRename;
  final VoidCallback onClone;
  final VoidCallback onDelete;
  final VoidCallback? onNote;

  /// Currency code appended to value sums (v1.0.0). Defaults to `SAR`.
  final String currency;

  /// Edit-mode hook to flip the node's audit lock (v1.0.0).
  final VoidCallback? onToggleLock;

  /// Edit-mode hook to set the node's workflow status (v1.0.0).
  final ValueChanged<MapNodeStatus>? onSetStatus;

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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(node.kind.tag, tone: _toneFor(node.kind, accent)),
                    if (!node.status.isNone)
                      StatusPill(node.status.tag, tone: _statusTone(node.status)),
                    if (node.locked)
                      StatusPill('Locked', tone: PillTone.neutral),
                  ],
                ),
                if (node.ref != null) ...[
                  const SizedBox(height: 9),
                  _RefRow(reference: node.ref!),
                ],
                if (node.meta != null && node.meta!.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  const Hairline(),
                  const SizedBox(height: 8),
                  ...node.meta!.entries.map((e) => _MetaRow(label: e.key, value: e.value)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _Stat(label: 'In', value: '${stats.inCount}', sub: stats.inSum > 0 ? '${mapCompact(stats.inSum)} $currency' : null)),
                    const SizedBox(width: 8),
                    Expanded(child: _Stat(label: 'Out', value: '${stats.outCount}', sub: stats.outSum > 0 ? '${mapCompact(stats.outSum)} $currency' : null)),
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
                  if (onSetStatus != null) ...[
                    _StatusPicker(current: node.status, onSet: onSetStatus!),
                    const SizedBox(height: 8),
                  ],
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
                      if (onToggleLock != null)
                        SuperIconButton(
                            icon: node.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            tooltip: node.locked ? 'Unlock' : 'Lock',
                            onPressed: onToggleLock!),
                      if (onToggleLock != null) const SizedBox(width: 7),
                      SuperIconButton(
                          icon: Icons.sticky_note_2_outlined,
                          tooltip: node.note != null ? 'Edit note' : 'Add note',
                          onPressed: onNote ?? () {}),
                      const SizedBox(width: 7),
                      SuperIconButton(icon: Icons.copy_rounded, tooltip: 'Clone', onPressed: onClone),
                      const SizedBox(width: 7),
                      SuperIconButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: node.locked ? 'Locked' : 'Delete',
                          danger: true,
                          onPressed: onDelete),
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

  PillTone _statusTone(MapNodeStatus s) => switch (s) {
        MapNodeStatus.approved => PillTone.success,
        MapNodeStatus.pending => PillTone.warning,
        MapNodeStatus.rejected => PillTone.danger,
        MapNodeStatus.posted => PillTone.accent,
        _ => PillTone.neutral,
      };
}

/// The source-record reference row — monospace, dot-segmented, with a copy-less
/// document glyph (GeniusLink renders serials like `JV-2024-0042` in mono).
class _RefRow extends StatelessWidget {
  const _RefRow({required this.reference});
  final String reference;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Row(
      children: [
        Icon(Icons.tag_rounded, size: 13, color: t.fg4),
        const SizedBox(width: 6),
        Expanded(
          child: Text(reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SuperText.mono.copyWith(fontSize: 11.5, color: t.fg2)),
        ),
      ],
    );
  }
}

/// One audit-metadata row: an uppercase label on the left, mono value right.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SuperText.pill.copyWith(fontSize: 9.5, color: t.fg3)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: SuperText.mono.copyWith(fontSize: 11, color: t.fg1)),
        ],
      ),
    );
  }
}

/// A compact segmented status picker shown in edit mode. Tapping a swatch sets
/// the node's [MapNodeStatus]; the active one is filled.
class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.current, required this.onSet});
  final MapNodeStatus current;
  final ValueChanged<MapNodeStatus> onSet;

  static const _choices = [
    MapNodeStatus.none,
    MapNodeStatus.draft,
    MapNodeStatus.pending,
    MapNodeStatus.approved,
    MapNodeStatus.posted,
    MapNodeStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('STATUS', style: SuperText.label.copyWith(color: t.fg3)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in _choices)
              _StatusSwatch(
                status: s,
                selected: s == current,
                onTap: () => onSet(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusSwatch extends StatelessWidget {
  const _StatusSwatch({required this.status, required this.selected, required this.onTap});
  final MapNodeStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final c = status.colorOf(t);
    final label = status.isNone ? 'None' : status.tag;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? t.tintFill(c, 0.16) : t.inputBg,
          border: Border.all(color: selected ? c : t.border),
          borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label,
                style: SuperText.pill.copyWith(
                    fontSize: 9.5, color: selected ? t.fg1 : t.fg3)),
          ],
        ),
      ),
    );
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
