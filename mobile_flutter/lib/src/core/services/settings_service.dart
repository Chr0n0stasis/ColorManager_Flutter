import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_models.dart';
import '../../i18n/app_localizations.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyThemeSeedColor = 'theme_seed_color';
  static const String _keyUseMaterialDynamic = 'use_material_dynamic';
  static const String _keyLanguagePref = 'language_pref';
  static const String _keyCloudStorage = 'cloud_storage';
  static const String _keyWebdavUrl = 'webdav_url';
  static const String _keyWebdavUser = 'webdav_user';
  static const String _keyWebdavPassword = 'webdav_password';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getters
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Color getThemeSeedColor() {
    final value = _prefs.getInt(_keyThemeSeedColor);
    if (value == null) return const Color(0xFF1D4ED8);
    return Color(value);
  }

  bool getUseMaterialDynamicColor() {
    return _prefs.getBool(_keyUseMaterialDynamic) ?? false;
  }

  AppLanguagePreference getLanguagePreference() {
    final value = _prefs.getString(_keyLanguagePref);
    if (value == null) return AppLanguagePreference.system;
    return AppLanguagePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppLanguagePreference.system,
    );
  }

  CloudStorageType getCloudStorageType() {
    final value = _prefs.getString(_keyCloudStorage);
    if (value == null) return CloudStorageType.disabled;
    return CloudStorageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CloudStorageType.disabled,
    );
  }

  String getWebdavUrl() => _prefs.getString(_keyWebdavUrl) ?? '';
  String getWebdavUser() => _prefs.getString(_keyWebdavUser) ?? '';
  String getWebdavPassword() => _prefs.getString(_keyWebdavPassword) ?? '';

  // Setters
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  Future<void> saveThemeSeedColor(Color color) async {
    await _prefs.setInt(_keyThemeSeedColor, color.value);
  }

  Future<void> saveUseMaterialDynamicColor(bool enabled) async {
    await _prefs.setBool(_keyUseMaterialDynamic, enabled);
  }

  Future<void> saveLanguagePreference(AppLanguagePreference pref) async {
    await _prefs.setString(_keyLanguagePref, pref.name);
  }

  Future<void> saveCloudStorageType(CloudStorageType type) async {
    await _prefs.setString(_keyCloudStorage, type.name);
  }

  Future<void> saveWebdavUrl(String value) async {
    await _prefs.setString(_keyWebdavUrl, value);
  }

  Future<void> saveWebdavUser(String value) async {
    await _prefs.setString(_keyWebdavUser, value);
  }

  Future<void> saveWebdavPassword(String value) async {
    await _prefs.setString(_keyWebdavPassword, value);
  }
}
