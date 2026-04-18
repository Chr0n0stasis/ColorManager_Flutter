import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'src/core/branding/upstream_branding.dart';
import 'src/ui/main_shell.dart';

void main() {
  runApp(const ColorManagerMobileApp());
}

class ColorManagerMobileApp extends StatefulWidget {
  const ColorManagerMobileApp({super.key});

  @override
  State<ColorManagerMobileApp> createState() => _ColorManagerMobileAppState();
}

class _ColorManagerMobileAppState extends State<ColorManagerMobileApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeSeedColor = const Color(0xFF1D4ED8);
  bool _useMaterialDynamicColor = false;

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _setThemeSeedColor(Color color) {
    setState(() {
      _themeSeedColor = color;
    });
  }

  void _setUseMaterialDynamicColor(bool enabled) {
    setState(() {
      _useMaterialDynamicColor = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final hasDynamicColor = lightDynamic != null || darkDynamic != null;
        final useDynamic = _useMaterialDynamicColor && hasDynamicColor;

        final lightScheme = useDynamic && lightDynamic != null
            ? lightDynamic.harmonized()
            : ColorScheme.fromSeed(
                seedColor: _themeSeedColor,
                brightness: Brightness.light,
              );

        final darkScheme = useDynamic && darkDynamic != null
            ? darkDynamic.harmonized()
            : ColorScheme.fromSeed(
                seedColor: _themeSeedColor,
                brightness: Brightness.dark,
              );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '$appDisplayName $appVersion',
          themeMode: _themeMode,
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
          ),
          home: MainShell(
            themeMode: _themeMode,
            onThemeModeChanged: _setThemeMode,
            themeSeedColor: _themeSeedColor,
            onThemeSeedColorChanged: _setThemeSeedColor,
            useMaterialDynamicColor: _useMaterialDynamicColor,
            onUseMaterialDynamicColorChanged: _setUseMaterialDynamicColor,
            materialDynamicColorAvailable: hasDynamicColor,
          ),
        );
      },
    );
  }
}
