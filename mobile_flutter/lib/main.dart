import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/core/branding/upstream_branding.dart';
import 'src/i18n/app_localizations.dart';
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
  AppLanguagePreference _languagePreference = AppLanguagePreference.system;

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

  void _setLanguagePreference(AppLanguagePreference preference) {
    setState(() {
      _languagePreference = preference;
    });
  }

  Locale? get _localeOverride {
    return switch (_languagePreference) {
      AppLanguagePreference.system => null,
      AppLanguagePreference.zhCn => AppLocalizations.zhCnLocale,
      AppLanguagePreference.enUs => AppLocalizations.enUsLocale,
    };
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
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).tr(appDisplayName),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _localeOverride,
          localeResolutionCallback: (systemLocale, _) {
            if (_languagePreference != AppLanguagePreference.system) {
              return _localeOverride;
            }
            return AppLocalizations.resolveSystemLocale(systemLocale);
          },
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
            languagePreference: _languagePreference,
            onLanguagePreferenceChanged: _setLanguagePreference,
          ),
        );
      },
    );
  }
}
