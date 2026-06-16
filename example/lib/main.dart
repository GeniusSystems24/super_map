// ============================================================
// example/lib/main.dart
// ------------------------------------------------------------
// Showcase launcher for super_map. Registers the SuperThemeData extension (so
// the canvas themes light/dark in parity), exposes a global Light/Dark + LTR/RTL
// toggle, and links two demos that share ONE engine:
//   • Sample Graphs  — the five bundled MapGraphData seeds + style toggles
//   • Custom Graph   — a hand-built MapGraph wired straight into SuperMap
// ============================================================

import 'package:flutter/material.dart';
import 'package:super_map/super_map.dart';

import 'custom_map_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.dark;
  TextDirection _dir = TextDirection.ltr;

  ThemeData _theme(SuperThemeData s) => ThemeData(
        brightness: s.brightness,
        scaffoldBackgroundColor: s.bg,
        extensions: [s],
      );

  void _toggleTheme() =>
      setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  void _toggleDir() =>
      setState(() => _dir = _dir == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Super Map',
      themeMode: _mode,
      theme: _theme(SuperThemeData.light),
      darkTheme: _theme(SuperThemeData.dark),
      builder: (context, child) => Directionality(textDirection: _dir, child: child!),
      home: _Launcher(
        mode: _mode,
        dir: _dir,
        onToggleTheme: _toggleTheme,
        onToggleDir: _toggleDir,
      ),
    );
  }
}

class _Demo {
  const _Demo(this.title, this.subtitle, this.icon, this.builder);
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

class _Launcher extends StatelessWidget {
  const _Launcher({
    required this.mode,
    required this.dir,
    required this.onToggleTheme,
    required this.onToggleDir,
  });

  final ThemeMode mode;
  final TextDirection dir;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleDir;

  static final List<_Demo> _demos = [
    _Demo('Sample Graphs', 'Five MapGraphData seeds · read/edit · card/chip/pill · curved/ortho/straight',
        Icons.account_tree_outlined, (_) => const SuperMapDemo()),
    _Demo('Custom Graph', 'A hand-built MapGraph wired straight into SuperMap',
        Icons.hub_outlined, (_) => const CustomMapDemo()),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SuperTokens.space10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SuperTokens.contentColumn),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SUPER MAP \u2022 GALLERY',
                      style: SuperText.eyebrow.copyWith(color: SuperTokens.accent)),
                  const SizedBox(height: SuperTokens.space2),
                  Text('Component Demos مكتبة المكونات',
                      style: SuperText.h1.copyWith(color: t.fg1)),
                  const SizedBox(height: SuperTokens.space8),
                  for (final d in _demos) ...[
                    _DemoCard(demo: d),
                    const SizedBox(height: SuperTokens.space3),
                  ],
                  const SizedBox(height: SuperTokens.space6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SuperButton(
                        label: mode == ThemeMode.dark ? 'Light Theme' : 'Dark Theme',
                        variant: SuperButtonVariant.secondary,
                        onPressed: onToggleTheme,
                      ),
                      const SizedBox(width: SuperTokens.space3),
                      SuperButton(
                        label: dir == TextDirection.ltr ? 'العربية (RTL)' : 'English (LTR)',
                        variant: SuperButtonVariant.secondary,
                        onPressed: onToggleDir,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.demo});
  final _Demo demo;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: demo.builder)),
        child: Container(
          padding: const EdgeInsets.all(SuperTokens.space4),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(SuperTokens.radiusCard),
            border: Border.all(color: t.border),
            boxShadow: t.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(SuperTokens.accent.withOpacity(0.14), t.surface),
                  borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
                ),
                child: Icon(demo.icon, size: 22, color: SuperTokens.accent),
              ),
              const SizedBox(width: SuperTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(demo.title, style: SuperText.heading.copyWith(color: t.fg1)),
                    const SizedBox(height: 2),
                    Text(demo.subtitle, style: SuperText.caption.copyWith(color: t.fg3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.fg4),
            ],
          ),
        ),
      ),
    );
  }
}
