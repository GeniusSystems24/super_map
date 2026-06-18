// ============================================================
// features/super_map/presentation/pages/super_map_demo.dart
// ------------------------------------------------------------
// A ready-to-route showcase page for SuperMap. Switches between the five
// bundled sample graphs, toggles node style (card / chip / pill), edge routing
// (curved / orthogonal / straight) and the animated flow, and shows the active
// graph's subtitle + a kind legend. The SuperMap toolbar carries Read/Edit.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/datasources/map_graph_data.dart';
import '../../domain/entities/map_graph.dart';
import '../controllers/super_map_controller.dart';
import '../widgets/super_map.dart';

class SuperMapDemo extends StatefulWidget {
  const SuperMapDemo({super.key});

  @override
  State<SuperMapDemo> createState() => _SuperMapDemoState();
}

class _SuperMapDemoState extends State<SuperMapDemo> {
  late final SuperMapController _controller = SuperMapController(graph: MapGraphData.all.first);
  int _seedIndex = 0;
  bool _flow = false;
  bool _showData = false;

  MapGraph get _graph => MapGraphData.all[_seedIndex];

  void _selectSeed(int i) {
    setState(() => _seedIndex = i);
    _controller.loadGraph(MapGraphData.all[i]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: t.border)),
        iconTheme: IconThemeData(color: t.fg2),
        title: Text('Super Map', style: SuperText.heading.copyWith(color: t.fg1)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SuperTokens.space8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SUPER MAP \u2022 SHOWCASE',
                      style: SuperText.eyebrow.copyWith(color: SuperTokens.accent)),
                  const SizedBox(height: SuperTokens.space2),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: _graph.title, style: SuperText.h1.copyWith(color: t.fg1)),
                      if (_graph.ar != null)
                        TextSpan(
                            text: '  ${_graph.ar}',
                            style: SuperText.h1.copyWith(
                                fontFamily: SuperTokens.arabicFont, fontSize: 20, color: t.fg3)),
                    ]),
                  ),
                  if (_graph.subtitle != null) ...[
                    const SizedBox(height: SuperTokens.space2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(_graph.subtitle!, style: SuperText.body.copyWith(color: t.fg3)),
                    ),
                  ],
                  const SizedBox(height: SuperTokens.space6),
                  _seedChips(t),
                  const SizedBox(height: SuperTokens.space6),
                  SuperMap(
                    controller: _controller,
                    height: 560,
                    animateFlow: _flow,
                    showData: _showData,
                  ),
                  const SizedBox(height: SuperTokens.space6),
                  _settings(t),
                  const SizedBox(height: SuperTokens.space6),
                  _legend(t),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _seedChips(SuperThemeData t) {
    return Wrap(
      spacing: SuperTokens.space2,
      runSpacing: SuperTokens.space2,
      children: [
        for (var i = 0; i < MapGraphData.all.length; i++)
          _Chip(
            label: MapGraphData.all[i].title,
            selected: _seedIndex == i,
            onTap: () => _selectSeed(i),
          ),
      ],
    );
  }

  Widget _settings(SuperThemeData t) {
    return Wrap(
      spacing: SuperTokens.space6,
      runSpacing: SuperTokens.space3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _OptionGroup<MapNodeStyle>(
          label: 'Node',
          value: _controller.nodeStyle,
          options: const {
            MapNodeStyle.card: 'Card',
            MapNodeStyle.chip: 'Chip',
            MapNodeStyle.pill: 'Pill',
          },
          onChanged: (v) => setState(() => _controller.setNodeStyle(v)),
        ),
        _OptionGroup<MapEdgeStyle>(
          label: 'Edge',
          value: _controller.edgeStyle,
          options: const {
            MapEdgeStyle.curved: 'Curved',
            MapEdgeStyle.orthogonal: 'Ortho',
            MapEdgeStyle.straight: 'Straight',
          },
          onChanged: (v) => setState(() => _controller.setEdgeStyle(v)),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('DATA', style: SuperText.label.copyWith(color: t.fg3)),
          const SizedBox(width: SuperTokens.space2),
          Switch(
            value: _showData,
            activeColor: SuperTokens.accent,
            onChanged: (v) => setState(() => _showData = v),
          ),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('FLOW', style: SuperText.label.copyWith(color: t.fg3)),
          const SizedBox(width: SuperTokens.space2),
          Switch(
            value: _flow,
            activeColor: SuperTokens.accent,
            onChanged: (v) => setState(() => _flow = v),
          ),
        ]),
      ],
    );
  }

  Widget _legend(SuperThemeData t) {
    return Wrap(
      spacing: SuperTokens.space4,
      runSpacing: SuperTokens.space2,
      children: [
        for (final k in _graph.legend)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: k.colorOf(t), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(k.tag, style: SuperText.caption.copyWith(color: t.fg2)),
          ]),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: SuperTokens.durBase,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.selectionFill(0.14) : t.surface,
          border: Border.all(color: selected ? SuperTokens.accent : t.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: SuperText.button.copyWith(
                fontSize: 13, color: selected ? SuperTokens.accent : t.fg2)),
      ),
    );
  }
}

class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label.toUpperCase(), style: SuperText.label.copyWith(color: t.fg3)),
      const SizedBox(width: SuperTokens.space2),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: t.inputBg,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final entry in options.entries)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: SuperTokens.durBase,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: value == entry.key ? SuperTokens.accent : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(SuperTokens.radiusControl - 1),
                ),
                child: Text(entry.value,
                    style: SuperText.button.copyWith(
                        fontSize: 12.5,
                        color: value == entry.key ? Colors.white : t.fg2)),
              ),
            ),
        ]),
      ),
    ]);
  }
}
