import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/core/branding/upstream_branding.dart';
import 'src/core/services/settings_service.dart';
import 'src/i18n/app_localizations.dart';
import 'src/ui/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();
  runApp(const ColorManagerMobileApp());
}

class ColorManagerMobileApp extends StatefulWidget {
  const ColorManagerMobileApp({super.key});

  @override
  State<ColorManagerMobileApp> createState() => _ColorManagerMobileAppState();
}

class _ColorManagerMobileAppState extends State<ColorManagerMobileApp> {
  late ThemeMode _themeMode;
  late Color _themeSeedColor;
  late bool _useMaterialDynamicColor;
  late AppLanguagePreference _languagePreference;

  @override
  void initState() {
    super.initState();
    _themeMode = SettingsService.instance.getThemeMode();
    _themeSeedColor = SettingsService.instance.getThemeSeedColor();
    _useMaterialDynamicColor = SettingsService.instance.getUseMaterialDynamicColor();
    _languagePreference = SettingsService.instance.getLanguagePreference();
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    SettingsService.instance.saveThemeMode(mode);
  }

  void _setThemeSeedColor(Color color) {
    setState(() {
      _themeSeedColor = color;
    });
    SettingsService.instance.saveThemeSeedColor(color);
  }

  void _setUseMaterialDynamicColor(bool enabled) {
    setState(() {
      _useMaterialDynamicColor = enabled;
    });
    SettingsService.instance.saveUseMaterialDynamicColor(enabled);
  }

  void _setLanguagePreference(AppLanguagePreference preference) {
    setState(() {
      _languagePreference = preference;
    });
    SettingsService.instance.saveLanguagePreference(preference);
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
