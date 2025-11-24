import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccentColor {
  final String colorName;
  final Color color;
  
  const AccentColor(this.colorName, this.color);
}

class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _accentColorKey = 'accent_color';
  static const String _customThemeKey = 'custom_theme';
  
  // Predefined accent colors with proper structure
  static final List<AccentColor> accentColors = [
    AccentColor('Green', Color(0xFF1DB954)),
    AccentColor('Blue', Color(0xFF2196F3)),
    AccentColor('Purple', Color(0xFF9C27B0)),
    AccentColor('Orange', Color(0xFFFF9800)),
    AccentColor('Red', Color(0xFFF44336)),
    AccentColor('Teal', Color(0xFF009688)),
    AccentColor('Indigo', Color(0xFF3F51B5)),
    AccentColor('Pink', Color(0xFFE91E63)),
    AccentColor('Deep Purple', Color(0xFF673AB7)),
    AccentColor('Cyan', Color(0xFF00BCD4)),
    AccentColor('Amber', Color(0xFFFFC107)),
    AccentColor('Deep Orange', Color(0xFFFF5722)),
    AccentColor('Light Blue', Color(0xFF03A9F4)),
    AccentColor('Lime', Color(0xFFCDDC39)),
    AccentColor('Yellow', Color(0xFFFFEB3B)),
    AccentColor('Brown', Color(0xFF795548)),
    AccentColor('Grey', Color(0xFF607D8B)),
  ];
  
  // Predefined theme presets
  static const Map<String, ThemePreset> themePresets = {
    'Default': ThemePreset(
      name: 'Default',
      primary: Color(0xFF1DB954),
      secondary: Color(0xFF1ED760),
      surface: Color(0xFFF8F9FA),
      background: Color(0xFFFFFFFF),
      description: 'Clean and modern green theme',
    ),
    'Ocean': ThemePreset(
      name: 'Ocean',
      primary: Color(0xFF006A88),
      secondary: Color(0xFF0088A8),
      surface: Color(0xFFE3F2FD),
      background: Color(0xFFF1F8FF),
      description: 'Calming ocean blue tones',
    ),
    'Sunset': ThemePreset(
      name: 'Sunset',
      primary: Color(0xFFFF6B35),
      secondary: Color(0xFFFF8C42),
      surface: Color(0xFFFFF3E0),
      background: Color(0xFFFFF8F3),
      description: 'Warm sunset orange colors',
    ),
    'Forest': ThemePreset(
      name: 'Forest',
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFF4CAF50),
      surface: Color(0xFFE8F5E8),
      background: Color(0xFFF1F8E9),
      description: 'Natural forest green palette',
    ),
    'Royal': ThemePreset(
      name: 'Royal',
      primary: Color(0xFF512DA8),
      secondary: Color(0xFF7C4DFF),
      surface: Color(0xFFEDE7F6),
      background: Color(0xFFF3E5F5),
      description: 'Elegant royal purple scheme',
    ),
    'Crimson': ThemePreset(
      name: 'Crimson',
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFFFF5252),
      surface: Color(0xFFFFEBEE),
      background: Color(0xFFFFFAFA),
      description: 'Bold crimson red design',
    ),
    'Mint': ThemePreset(
      name: 'Mint',
      primary: Color(0xFF26A69A),
      secondary: Color(0xFF4DB6AC),
      surface: Color(0xFFE0F2F1),
      background: Color(0xFFF0FDF4),
      description: 'Fresh mint green aesthetic',
    ),
    'Dark Ocean': ThemePreset(
      name: 'Dark Ocean',
      primary: Color(0xFF0077BE),
      secondary: Color(0xFF00A8E8),
      surface: Color(0xFF1E3A8A),
      background: Color(0xFF0F172A),
      description: 'Deep ocean dark theme',
      isDark: true,
    ),
    'Dark Purple': ThemePreset(
      name: 'Dark Purple',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFA78BFA),
      surface: Color(0xFF312E81),
      background: Color(0xFF1E1B4B),
      description: 'Mysterious dark purple',
      isDark: true,
    ),
    'Dark Green': ThemePreset(
      name: 'Dark Green',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF34D399),
      surface: Color(0xFF064E3B),
      background: Color(0xFF022C22),
      description: 'Matrix-inspired dark green',
      isDark: true,
    ),
  };
  
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }
  
  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
  
  static Future<Color> getAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_accentColorKey);
    return colorValue != null ? Color(colorValue) : accentColors[0].color;
  }
  
  static Future<void> setAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
  }
  
  static Future<String> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customThemeKey) ?? 'Default';
  }
  
  static Future<void> setCurrentTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customThemeKey, themeName);
  }
  
  static ThemeData createTheme({
    required String themeName,
    required bool isDarkMode,
  }) {
    final preset = themePresets[themeName] ?? themePresets['Default']!;
    final useDark = isDarkMode || preset.isDark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: useDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: preset.primary,
        brightness: useDark ? Brightness.dark : Brightness.light,
        primary: preset.primary,
        secondary: preset.secondary,
        surface: useDark ? preset.surface.withValues(alpha: 0.1) : preset.surface,
        background: useDark ? preset.background.withValues(alpha: 0.1) : preset.background,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: preset.primary.withValues(alpha: 0.1),
        foregroundColor: useDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: preset.primary, width: 2),
        ),
        filled: true,
        fillColor: useDark 
            ? preset.surface.withValues(alpha: 0.1) 
            : preset.surface.withValues(alpha: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: preset.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: preset.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: preset.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: preset.primary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: preset.primary,
        inactiveTrackColor: preset.primary.withValues(alpha: 0.3),
        thumbColor: preset.primary,
        overlayColor: preset.primary.withValues(alpha: 0.1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return preset.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return preset.primary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      // tabBarTheme: TabBarTheme(
      //   labelColor: preset.primary,
      //   unselectedLabelColor: Colors.grey,
      //   indicator: UnderlineTabIndicator(
      //     borderSide: BorderSide(color: preset.primary, width: 2),
      //   ),
      // ),
    );
  }
  
  static List<Color> getGradientColors(Color primary) {
    return [
      primary,
      HSLColor.fromColor(primary).withSaturation(0.8).withLightness(0.7).toColor(),
      HSLColor.fromColor(primary).withSaturation(0.6).withLightness(0.8).toColor(),
    ];
  }
  
  static Color getComplementaryColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }
  
  static Color getAnalogousColor(Color color, {double offset = 30}) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + offset) % 360).toColor();
  }
  
  static List<Color> generatePalette(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return [
      hsl.withLightness(0.9).toColor(),
      hsl.withLightness(0.7).toColor(),
      hsl.withLightness(0.5).toColor(),
      hsl.withLightness(0.3).toColor(),
      hsl.withLightness(0.1).toColor(),
    ];
  }
  
  // Get theme for achievements based on rarity
  static Color getAchievementColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'legendary':
        return Colors.purple;
      case 'mythic':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  // Apply theme to specific widgets
  static TextStyle getDisplayTextStyle(ThemeData theme) {
    return theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    ) ?? TextStyle();
  }
  
  static TextStyle getHeadlineTextStyle(ThemeData theme) {
    return theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    ) ?? TextStyle();
  }
  
  static TextStyle getBodyTextStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    ) ?? TextStyle();
  }
  
  static BoxDecoration getGradientDecoration(Color primary) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: getGradientColors(primary),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    );
  }
  
  static BoxDecoration getCardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
  
  // Preset themes map
  static final Map<String, ThemeData> presetThemes = {
    'ocean': _createOceanTheme(),
    'sunset': _createSunsetTheme(),
    'forest': _createForestTheme(),
    'royal': _createRoyalTheme(),
    'crimson': _createCrimsonTheme(),
    'mint': _createMintTheme(),
    'lavender': _createLavenderTheme(),
    'cosmic': _createCosmicTheme(),
    'autumn': _createAutumnTheme(),
    'neon': _createNeonTheme(),
  };
  
  // Generate theme from accent color
  static ThemeData generateThemeFromAccent(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: accentColor.withValues(alpha: 0.1),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Dark theme generators
  static ThemeData generateMinimalDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF6C63FF),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
    );
  }

  static ThemeData generateVibrantDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFFFF6B6B),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF2D1B69),
        elevation: 0,
      ),
    );
  }

  static ThemeData generateNatureDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF4ECDC4),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1A4A47),
        elevation: 0,
      ),
    );
  }

  // Preset theme creators
  static ThemeData _createOceanTheme() {
    return generateThemeFromAccent(Color(0xFF006A88));
  }

  static ThemeData _createSunsetTheme() {
    return generateThemeFromAccent(Color(0xFFFF6B35));
  }

  static ThemeData _createForestTheme() {
    return generateThemeFromAccent(Color(0xFF2E7D32));
  }

  static ThemeData _createRoyalTheme() {
    return generateThemeFromAccent(Color(0xFF512DA8));
  }

  static ThemeData _createCrimsonTheme() {
    return generateThemeFromAccent(Color(0xFFD32F2F));
  }

  static ThemeData _createMintTheme() {
    return generateThemeFromAccent(Color(0xFF26A69A));
  }

  static ThemeData _createLavenderTheme() {
    return generateThemeFromAccent(Color(0xFF9575CD));
  }

  static ThemeData _createCosmicTheme() {
    return generateThemeFromAccent(Color(0xFF3F51B5));
  }

  static ThemeData _createAutumnTheme() {
    return generateThemeFromAccent(Color(0xFFFF8A65));
  }

  static ThemeData _createNeonTheme() {
    return generateThemeFromAccent(Color(0xFF00E676));
  }
}

class ThemePreset {
  final String name;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final String description;
  final bool isDark;
  
  const ThemePreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.description,
    this.isDark = false,
  });
} 