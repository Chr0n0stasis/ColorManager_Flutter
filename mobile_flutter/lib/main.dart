import 'package:flutter/material.dart';

import 'src/core/branding/upstream_branding.dart';
import 'src/ui/main_shell.dart';

void main() {
  runApp(const ColorManagerMobileApp());
}

class ColorManagerMobileApp extends StatelessWidget {
  const ColorManagerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '$appDisplayName $appVersion',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1D4ED8),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
