// lib/main.dart

import 'package:flux/core/enums/app_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Keys for all settings
  static const String THEME_KEY = 'theme_mode';
  static const String SELECTED_THEME_KEY = 'selected_theme';
  static const String DEFAULT_HABIT_TYPE_KEY = 'default_habit_type';
  static const String DEFAULT_DISPLAY_MODE_KEY = 'default_display_mode';
  static const String DEFAULT_FREQUENCY_KEY = 'default_frequency';
  static const String DEFAULT_UNIT_KEY = 'default_unit';
  static const String NOTIFICATIONS_ENABLED_KEY = 'notifications_enabled';
  static const String SOUND_ENABLED_KEY = 'sound_enabled';
  static const String VIBRATION_ENABLED_KEY = 'vibration_enabled';
  static const String STREAK_NOTIFICATIONS_KEY = 'streak_notifications';
  static const String MILESTONE_NOTIFICATIONS_KEY = 'milestone_notifications';
  static const String REMINDER_TIME_KEY = 'reminder_time';
  static const String AUTO_BACKUP_KEY = 'auto_backup';
  static const String AUTO_BACKUP_FREQUENCY_KEY = 'auto_backup_frequency';
  static const String DATA_RETENTION_DAYS_KEY = 'data_retention_days';
  static const String COMPACT_MODE_KEY = 'compact_mode';
  static const String SHOW_ANIMATIONS_KEY = 'show_animations';
  static const String ANIMATION_SPEED_KEY = 'animation_speed';
  static const String DATE_FORMAT_KEY = 'date_format';
  static const String USE_24_HOUR_FORMAT_KEY = 'use_24_hour_format';
  static const String SHOW_WEEKENDS_KEY = 'show_weekends';
  static const String MOTIVATIONAL_QUOTES_KEY = 'motivational_quotes';
  static const String TODAY_WIDGET_KEY = 'today_widget';
  static const String DATA_VALIDATION_KEY = 'data_validation';
  static const String SHOW_HABIT_ICONS_KEY = 'show_habit_icons';
  static const String SHOW_SUCCESS_RATE_KEY = 'show_success_rate';
  static const String SHOW_CURRENT_STREAK_KEY = 'show_current_streak';
  static const String LANGUAGE_KEY = 'language';
  static const String HAPTIC_FEEDBACK_KEY = 'haptic_feedback';
  
  // Theme settings
  static Future<bool> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
    return prefs.setBool(THEME_KEY, isDarkMode);
  }
  
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }
  
  static Future<void> setSelectedTheme(String themeKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SELECTED_THEME_KEY, themeKey);
  }
  
  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SELECTED_THEME_KEY) ?? 'Default';
  }
  
  // Habit settings
  static Future<bool> setDefaultHabitType(HabitType type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(DEFAULT_HABIT_TYPE_KEY, type.index);
  }
  
  static Future<HabitType> getDefaultHabitType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_HABIT_TYPE_KEY) ?? HabitType.SuccessBased.index;
    return HabitType.values[index];
  }
  
  static Future<bool> setDefaultDisplayMode(ReportDisplay mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(DEFAULT_DISPLAY_MODE_KEY, mode.index);
  }
  
  static Future<ReportDisplay> getDefaultDisplayMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_DISPLAY_MODE_KEY) ?? ReportDisplay.Rate.index;
    return ReportDisplay.values[index];
  }
  
  static Future<void> setDefaultFrequency(HabitFrequency frequency) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DEFAULT_FREQUENCY_KEY, frequency.index);
  }
  
  static Future<HabitFrequency> getDefaultFrequency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_FREQUENCY_KEY) ?? HabitFrequency.Daily.index;
    return HabitFrequency.values[index];
  }
  
  static Future<void> setDefaultUnit(HabitUnit unit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DEFAULT_UNIT_KEY, unit.index);
  }
  
  static Future<HabitUnit> getDefaultUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_UNIT_KEY) ?? HabitUnit.Count.index;
    return HabitUnit.values[index];
  }
  
  // Notification settings
  static Future<void> setNotificationsEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NOTIFICATIONS_ENABLED_KEY, enabled);
  }
  
  static Future<bool> getNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NOTIFICATIONS_ENABLED_KEY) ?? true;
  }
  
  static Future<void> setSoundEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SOUND_ENABLED_KEY, enabled);
  }
  
  static Future<bool> getSoundEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SOUND_ENABLED_KEY) ?? true;
  }
  
  static Future<void> setVibrationEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(VIBRATION_ENABLED_KEY, enabled);
  }
  
  static Future<bool> getVibrationEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(VIBRATION_ENABLED_KEY) ?? true;
  }
  
  static Future<void> setStreakNotifications(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(STREAK_NOTIFICATIONS_KEY, enabled);
  }
  
  static Future<bool> getStreakNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(STREAK_NOTIFICATIONS_KEY) ?? true;
  }
  
  static Future<void> setMilestoneNotifications(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MILESTONE_NOTIFICATIONS_KEY, enabled);
  }
  
  static Future<bool> getMilestoneNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(MILESTONE_NOTIFICATIONS_KEY) ?? true;
  }
  
  static Future<void> setReminderTime(int hour) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(REMINDER_TIME_KEY, hour);
  }
  
  static Future<int> getReminderTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(REMINDER_TIME_KEY) ?? 9;
  }
  
  // Display settings
  static Future<void> setCompactMode(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(COMPACT_MODE_KEY, enabled);
  }
  
  static Future<bool> getCompactMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(COMPACT_MODE_KEY) ?? false;
  }
  
  static Future<void> setShowAnimations(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SHOW_ANIMATIONS_KEY, enabled);
  }
  
  static Future<bool> getShowAnimations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SHOW_ANIMATIONS_KEY) ?? true;
  }
  
  static Future<void> setAnimationSpeed(double speed) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(ANIMATION_SPEED_KEY, speed);
  }
  
  static Future<double> getAnimationSpeed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(ANIMATION_SPEED_KEY) ?? 1.0;
  }
  
  static Future<void> setDateFormat(String format) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(DATE_FORMAT_KEY, format);
  }
  
  static Future<String> getDateFormat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(DATE_FORMAT_KEY) ?? 'MMM d, yyyy';
  }
  
  static Future<void> setUse24HourFormat(bool use24Hour) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(USE_24_HOUR_FORMAT_KEY, use24Hour);
  }
  
  static Future<bool> getUse24HourFormat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(USE_24_HOUR_FORMAT_KEY) ?? true;
  }
  
  static Future<void> setShowWeekends(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SHOW_WEEKENDS_KEY, show);
  }
  
  static Future<bool> getShowWeekends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SHOW_WEEKENDS_KEY) ?? true;
  }
  
  static Future<void> setMotivationalQuotes(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MOTIVATIONAL_QUOTES_KEY, show);
  }
  
  static Future<bool> getMotivationalQuotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(MOTIVATIONAL_QUOTES_KEY) ?? true;
  }
  
  static Future<void> setTodayWidget(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TODAY_WIDGET_KEY, show);
  }
  
  static Future<bool> getTodayWidget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(TODAY_WIDGET_KEY) ?? true;
  }
  
  static Future<void> setShowHabitIcons(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SHOW_HABIT_ICONS_KEY, show);
  }
  
  static Future<bool> getShowHabitIcons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SHOW_HABIT_ICONS_KEY) ?? true;
  }
  
  static Future<void> setShowSuccessRate(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SHOW_SUCCESS_RATE_KEY, show);
  }
  
  static Future<bool> getShowSuccessRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SHOW_SUCCESS_RATE_KEY) ?? true;
  }
  
  static Future<void> setShowCurrentStreak(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SHOW_CURRENT_STREAK_KEY, show);
  }
  
  static Future<bool> getShowCurrentStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SHOW_CURRENT_STREAK_KEY) ?? true;
  }
  
  // Data settings
  static Future<void> setAutoBackup(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AUTO_BACKUP_KEY, enabled);
  }
  
  static Future<bool> getAutoBackup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AUTO_BACKUP_KEY) ?? false;
  }
  
  static Future<void> setAutoBackupFrequency(int days) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AUTO_BACKUP_FREQUENCY_KEY, days);
  }
  
  static Future<int> getAutoBackupFrequency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AUTO_BACKUP_FREQUENCY_KEY) ?? 7;
  }
  
  static Future<void> setDataRetentionDays(int days) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DATA_RETENTION_DAYS_KEY, days);
  }
  
  static Future<int> getDataRetentionDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(DATA_RETENTION_DAYS_KEY) ?? 365;
  }
  
  static Future<void> setDataValidation(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DATA_VALIDATION_KEY, enabled);
  }
  
  static Future<bool> getDataValidation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(DATA_VALIDATION_KEY) ?? true;
  }
  
  // Advanced settings
  static Future<void> setLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_KEY, language);
  }
  
  static Future<String> getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(LANGUAGE_KEY) ?? 'English';
  }
  
  static Future<void> setHapticFeedback(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HAPTIC_FEEDBACK_KEY, enabled);
  }
  
  static Future<bool> getHapticFeedback() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(HAPTIC_FEEDBACK_KEY) ?? true;
  }
  
  // Reset all settings
  static Future<void> resetAllSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
