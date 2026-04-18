import 'package:flutter/material.dart';

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
  ThemeMode _themeMode = ThemeMode.light;
  Color _themeSeedColor = const Color(0xFF1D4ED8);

  void _setDarkMode(bool enabled) {
    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setThemeSeedColor(Color color) {
    setState(() {
      _themeSeedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '$appDisplayName $appVersion',
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: _themeSeedColor,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: _themeSeedColor,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: MainShell(
        isDarkMode: _themeMode == ThemeMode.dark,
        onDarkModeChanged: _setDarkMode,
        themeSeedColor: _themeSeedColor,
        onThemeSeedColorChanged: _setThemeSeedColor,
      ),
    );
  }
}
