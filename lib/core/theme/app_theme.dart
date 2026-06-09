import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _customThemeEnabledKey = 'custom_theme_enabled';
const _themeModeKey = 'custom_theme_mode';
const _displayPresetKey = 'custom_theme_display_preset';
const _primaryColorKey = 'custom_theme_primary_color';
const _accentColorKey = 'custom_theme_accent_color';
const _surfaceColorKey = 'custom_theme_surface_color';

final appThemeSettingsProvider =
    NotifierProvider<AppThemeSettingsNotifier, AppThemeSettings>(
      AppThemeSettingsNotifier.new,
    );

enum AppDisplayPreset {
  standard('Standard', Color(0xFFF5F7FA), Color(0xFF121212)),
  oled('OLED', Color(0xFFF7F8FB), Color(0xFF000000)),
  amoled('AMOLED', Color(0xFFF4F8F6), Color(0xFF020806)),
  miniLed('Mini-LED', Color(0xFFF7F9FC), Color(0xFF08111F));

  const AppDisplayPreset(this.label, this.lightSurface, this.darkSurface);

  final String label;
  final Color lightSurface;
  final Color darkSurface;
}

class AppThemeSettings {
  final bool customThemeEnabled;
  final ThemeMode themeMode;
  final AppDisplayPreset displayPreset;
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;

  const AppThemeSettings({
    this.customThemeEnabled = false,
    this.themeMode = ThemeMode.system,
    this.displayPreset = AppDisplayPreset.standard,
    this.primaryColor = AppTheme.primaryColor,
    this.accentColor = AppTheme.accentColor,
    this.surfaceColor = const Color(0xFFF5F7FA),
  });

  AppThemeSettings copyWith({
    bool? customThemeEnabled,
    ThemeMode? themeMode,
    AppDisplayPreset? displayPreset,
    Color? primaryColor,
    Color? accentColor,
    Color? surfaceColor,
  }) {
    return AppThemeSettings(
      customThemeEnabled: customThemeEnabled ?? this.customThemeEnabled,
      themeMode: themeMode ?? this.themeMode,
      displayPreset: displayPreset ?? this.displayPreset,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
    );
  }
}

class AppThemeSettingsNotifier extends Notifier<AppThemeSettings> {
  SharedPreferences? _preferences;

  @override
  AppThemeSettings build() {
    _load();
    return const AppThemeSettings();
  }

  Future<void> _load() async {
    _preferences = await SharedPreferences.getInstance();
    final presetName = _preferences?.getString(_displayPresetKey);
    final themeModeName = _preferences?.getString(_themeModeKey);
    state = AppThemeSettings(
      customThemeEnabled:
          _preferences?.getBool(_customThemeEnabledKey) ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeName,
        orElse: () => ThemeMode.system,
      ),
      displayPreset: AppDisplayPreset.values.firstWhere(
        (preset) => preset.name == presetName,
        orElse: () => AppDisplayPreset.standard,
      ),
      primaryColor: Color(
        _preferences?.getInt(_primaryColorKey) ??
            AppTheme.primaryColor.toARGB32(),
      ),
      accentColor: Color(
        _preferences?.getInt(_accentColorKey) ??
            AppTheme.accentColor.toARGB32(),
      ),
      surfaceColor: Color(
        _preferences?.getInt(_surfaceColorKey) ??
            const Color(0xFFF5F7FA).toARGB32(),
      ),
    );
  }

  Future<void> update(AppThemeSettings settings) async {
    state = settings;
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.setBool(
      _customThemeEnabledKey,
      settings.customThemeEnabled,
    );
    await preferences.setString(_themeModeKey, settings.themeMode.name);
    await preferences.setString(_displayPresetKey, settings.displayPreset.name);
    await preferences.setInt(
      _primaryColorKey,
      settings.primaryColor.toARGB32(),
    );
    await preferences.setInt(_accentColorKey, settings.accentColor.toARGB32());
    await preferences.setInt(
      _surfaceColorKey,
      settings.surfaceColor.toARGB32(),
    );
  }
}

class AppTheme {
  static const Color primaryColor = Colors.indigo;
  static const Color accentColor = Colors.deepOrangeAccent;

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      primary: primaryColor,
      accent: accentColor,
      surface: const Color(0xFFF5F7FA),
      card: Colors.white,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      accent: accentColor,
      surface: const Color(0xFF121212),
      card: const Color(0xFF1E1E1E),
    );
  }

  static ThemeData lightThemeFor(AppThemeSettings settings) {
    if (!settings.customThemeEnabled) return lightTheme;

    return _buildTheme(
      brightness: Brightness.light,
      primary: settings.primaryColor,
      accent: settings.accentColor,
      surface: settings.surfaceColor,
      card: Colors.white,
    );
  }

  static ThemeData darkThemeFor(AppThemeSettings settings) {
    if (!settings.customThemeEnabled) return darkTheme;

    final surface = settings.displayPreset.darkSurface;
    return _buildTheme(
      brightness: Brightness.dark,
      primary: settings.primaryColor,
      accent: settings.accentColor,
      surface: surface,
      card: surface == Colors.black ? const Color(0xFF080808) : null,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color accent,
    required Color surface,
    Color? card,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(secondary: accent);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color:
            card ??
            (brightness == Brightness.light
                ? Colors.white
                : colorScheme.surfaceContainer),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: brightness == Brightness.light
            ? Colors.black87
            : Colors.white,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
