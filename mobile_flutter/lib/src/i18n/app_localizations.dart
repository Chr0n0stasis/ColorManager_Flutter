import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum AppLanguagePreference {
  system,
  zhCn,
  enUs,
}

class AppLocalizations {
  AppLocalizations({
    required this.locale,
    required Map<String, String> values,
    required Map<String, String> fallbackValues,
  })  : _values = values,
        _fallbackValues = fallbackValues;

  final Locale locale;
  final Map<String, String> _values;
  final Map<String, String> _fallbackValues;

  static const Locale zhCnLocale = Locale('zh', 'CN');
  static const Locale enUsLocale = Locale('en', 'US');
  static const Locale fallbackLocale = enUsLocale;

  static const List<Locale> supportedLocales = <Locale>[
    zhCnLocale,
    enUsLocale,
  ];

  static const AppLocalizationsDelegate delegate = AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localization != null, 'AppLocalizations not found in context');
    return localization!;
  }

  String tr(String key, {Map<String, String> params = const <String, String>{}}) {
    final template = _values[key] ?? _fallbackValues[key] ?? key;
    if (params.isEmpty) {
      return template;
    }

    var resolved = template;
    for (final entry in params.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', entry.value);
    }
    return resolved;
  }

  static Locale normalizedLocaleForPreference(AppLanguagePreference preference) {
    return switch (preference) {
      AppLanguagePreference.system => fallbackLocale,
      AppLanguagePreference.zhCn => zhCnLocale,
      AppLanguagePreference.enUs => enUsLocale,
    };
  }

  static Locale resolveSystemLocale(Locale? systemLocale) {
    if (systemLocale == null) {
      return fallbackLocale;
    }

    final language = systemLocale.languageCode.toLowerCase();
    if (language == 'zh') {
      return zhCnLocale;
    }
    if (language == 'en') {
      return enUsLocale;
    }
    return fallbackLocale;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    return language == 'zh' || language == 'en';
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final resolvedLocale = AppLocalizations.resolveSystemLocale(locale);
    final resolvedMap = await _loadLocaleMap(resolvedLocale);
    final fallbackMap = resolvedLocale == AppLocalizations.enUsLocale
        ? resolvedMap
        : await _loadLocaleMap(AppLocalizations.enUsLocale);

    return AppLocalizations(
      locale: resolvedLocale,
      values: resolvedMap,
      fallbackValues: fallbackMap,
    );
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }

  Future<Map<String, String>> _loadLocaleMap(Locale locale) async {
    final tag = '${locale.languageCode}-${locale.countryCode}';
    final path = 'assets/i18n/$tag.json';
    try {
      final content = await rootBundle.loadString(path);
      final raw = jsonDecode(content);
      if (raw is! Map<String, dynamic>) {
        return <String, String>{};
      }

      final result = <String, String>{};
      raw.forEach((key, value) {
        result[key] = value.toString();
      });
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }
}

extension AppLocalizationBuildContextX on BuildContext {
  String tr(String key, {Map<String, String> params = const <String, String>{}}) {
    return AppLocalizations.of(this).tr(key, params: params);
  }
}
