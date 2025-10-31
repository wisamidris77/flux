import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'selected_language';
  static const String _missingTranslationsFile = 'Documents/missing_localization.txt';
  
  // Supported languages
  static const Map<String, Locale> supportedLocales = {
    'en': Locale('en', 'US'), // English
    'ar': Locale('ar', 'SA'), // Arabic
    'zh': Locale('zh', 'CN'), // Chinese (Simplified)
    'es': Locale('es', 'ES'), // Spanish
    'hi': Locale('hi', 'IN'), // Hindi
    'pr': Locale('pr', 'IR'), // Persian/Farsi
    'de': Locale('de', 'DE'), // German
  };

  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
    'zh': '中文',
    'es': 'Español',
    'hi': 'हिन्दी',
    'pr': 'فارسی',
    'de': 'Deutsch',
  };

  static const Map<String, String> languageNamesInEnglish = {
    'en': 'English',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'es': 'Spanish',
    'hi': 'Hindi',
    'pr': 'Persian',
    'de': 'German',
  };

  Locale? _currentLocale;
  bool _isInitialized = false;

  // Get current locale
  Locale get currentLocale => _currentLocale ?? const Locale('en', 'US');
  
  // Get current language code
  String get currentLanguageCode => _currentLocale?.languageCode ?? 'en';
  
  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString(_languageKey);
    
    if (savedLanguage != null && supportedLocales.containsKey(savedLanguage)) {
      _currentLocale = supportedLocales[savedLanguage];
    } else {
      // Auto-detect device language
      _currentLocale = await _detectDeviceLanguage();
    }
    
    _isInitialized = true;
  }

  // Detect device language
  Future<Locale> _detectDeviceLanguage() async {
    try {
      final String deviceLanguage = Platform.localeName.split('_')[0];
      
      if (supportedLocales.containsKey(deviceLanguage)) {
        return supportedLocales[deviceLanguage]!;
      }
    } catch (e) {
      debugPrint('Error detecting device language: $e');
    }
    
    // Fallback to English
    return const Locale('en', 'US');
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    if (!supportedLocales.containsKey(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }

    _currentLocale = supportedLocales[languageCode];
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Get supported locales list
  List<Locale> get supportedLocalesList => supportedLocales.values.toList();

  // Get language names for selection
  Map<String, String> getLanguageNames(bool inEnglish) {
    return inEnglish ? languageNamesInEnglish : languageNames;
  }

  // Check if language is RTL
  bool isRTL(String languageCode) {
    return languageCode == 'ar' || languageCode == 'pr';
  }

  // Check if current language is RTL
  bool get isCurrentLanguageRTL => isRTL(currentLanguageCode);

  // Get text direction
  ui.TextDirection get textDirection => isCurrentLanguageRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

  // Track missing translations (debug only)
  static void trackMissingTranslation(String key, String languageCode) {
    assert(() {
      _writeMissingTranslation(key, languageCode);
      return true;
    }());
  }

  // Write missing translation to file
  static void _writeMissingTranslation(String key, String languageCode) {
    try {
      final file = File(_missingTranslationsFile);
      final directory = file.parent;
      
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String();
      final entry = '$timestamp - $languageCode: $key\n';
      
      if (file.existsSync()) {
        file.writeAsStringSync(entry, mode: FileMode.append);
      } else {
        file.writeAsStringSync(entry);
      }
    } catch (e) {
      debugPrint('Error writing missing translation: $e');
    }
  }

  // Clear missing translations file
  static void clearMissingTranslationsFile() {
    try {
      final file = File(_missingTranslationsFile);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error clearing missing translations file: $e');
    }
  }

  // Get missing translations
  static List<String> getMissingTranslations() {
    try {
      final file = File(_missingTranslationsFile);
      if (file.existsSync()) {
        return file.readAsLinesSync();
      }
    } catch (e) {
      debugPrint('Error reading missing translations: $e');
    }
    return [];
  }
}