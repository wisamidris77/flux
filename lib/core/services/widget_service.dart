import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';

class WidgetService {
  static const String _widgetName = 'FluxHabitWidget';
  
  // Initialize home widget
  static Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await HomeWidget.setAppGroupId('group.flux.habittracker');
      } catch (e) {
        debugPrint('Error initializing home widget: $e');
      }
    }
  }
  
  // Update all home screen widgets
  static Future<void> updateHomeWidgets() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    
    try {
      final habits = await StorageService.loadAll();
      final activeHabits = habits.where((h) => !h.isArchived && !h.isPaused).toList();
      
      // Get today's progress
      final today = DateTime.now();
      final dueToday = activeHabits.where((h) => h.isDueToday()).length;
      final completedToday = activeHabits.where((h) {
        final todayEntries = h.entries.where((e) => 
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day &&
          h.isPositiveDay(e)
        );
        return todayEntries.isNotEmpty;
      }).length;
      
      // Calculate completion percentage
      final completionPercentage = dueToday > 0 ? (completedToday / dueToday * 100).round() : 100;
      
      // Prepare widget data
      final widgetData = {
        'totalHabits': activeHabits.length,
        'dueToday': dueToday,
        'completedToday': completedToday,
        'completionPercentage': completionPercentage,
        'streakAverage': _calculateAverageStreak(activeHabits),
        'topHabits': _getTopHabits(activeHabits),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      // Save data for widget
      await HomeWidget.saveWidgetData<int>('totalHabits', widgetData['totalHabits'] as int);
      await HomeWidget.saveWidgetData<int>('dueToday', widgetData['dueToday'] as int);
      await HomeWidget.saveWidgetData<int>('completedToday', widgetData['completedToday'] as int);
      await HomeWidget.saveWidgetData<int>('completionPercentage', widgetData['completionPercentage'] as int);
      await HomeWidget.saveWidgetData<double>('streakAverage', widgetData['streakAverage'] as double);
      await HomeWidget.saveWidgetData<String>('topHabits', jsonEncode(widgetData['topHabits']));
      await HomeWidget.saveWidgetData<String>('lastUpdated', widgetData['lastUpdated'] as String);
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: 'FluxHabitWidget',
        iOSName: 'FluxHabitWidget',
      );
      
    } catch (e) {
      debugPrint('Error updating home widgets: $e');
    }
  }
  
  // Calculate average streak across all habits
  static double _calculateAverageStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0.0;
    
    final totalStreak = habits.fold<int>(0, (sum, habit) => sum + habit.currentStreak);
    return totalStreak / habits.length;
  }
  
  // Get top 3 habits by streak
  static List<Map<String, dynamic>> _getTopHabits(List<Habit> habits) {
    if (habits.isEmpty) return [];
    
    final sortedHabits = List<Habit>.from(habits)
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    
    return sortedHabits.take(3).map((habit) => {
      'name': habit.name,
      'streak': habit.currentStreak,
      'icon': habit.icon?.codePoint ?? Icons.star.codePoint,
      'color': habit.color?.value ?? Colors.blue.value,
    }).toList();
  }
  
  // Get widget layout for small widget
  static Map<String, dynamic> getSmallWidgetData(List<Habit> habits) {
    final today = DateTime.now();
    final dueToday = habits.where((h) => h.isDueToday() && !h.isArchived && !h.isPaused).length;
    final completedToday = habits.where((h) {
      final todayEntries = h.entries.where((e) => 
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day &&
        h.isPositiveDay(e)
      );
      return todayEntries.isNotEmpty && !h.isArchived && !h.isPaused;
    }).length;
    
    return {
      'title': 'Today\'s Progress',
      'progress': '$completedToday/$dueToday',
      'percentage': dueToday > 0 ? (completedToday / dueToday * 100).round() : 100,
      'subtitle': dueToday == completedToday ? 'All done! 🎉' : 'Keep going! 💪',
    };
  }
  
  // Get widget layout for medium widget
  static Map<String, dynamic> getMediumWidgetData(List<Habit> habits) {
    final smallData = getSmallWidgetData(habits);
    final activeHabits = habits.where((h) => !h.isArchived && !h.isPaused).toList();
    
    return {
      ...smallData,
      'totalHabits': activeHabits.length,
      'averageStreak': _calculateAverageStreak(activeHabits).toStringAsFixed(1),
      'longestStreak': activeHabits.isEmpty ? 0 : activeHabits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b),
    };
  }
  
  // Get widget layout for large widget
  static Map<String, dynamic> getLargeWidgetData(List<Habit> habits) {
    final mediumData = getMediumWidgetData(habits);
    final topHabits = _getTopHabits(habits.where((h) => !h.isArchived && !h.isPaused).toList());
    
    return {
      ...mediumData,
      'topHabits': topHabits,
      'weekProgress': _getWeekProgress(habits),
    };
  }
  
  // Get this week's progress
  static List<Map<String, dynamic>> _getWeekProgress(List<Habit> habits) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {
        'day': ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
        'date': date,
      };
    });
    
    return weekDays.map((dayInfo) {
      final date = dayInfo['date'] as DateTime;
      final dayHabits = habits.where((h) => !h.isArchived && !h.isPaused).where((h) {
        // Check if habit was due on this day
        final dayOfWeek = date.weekday % 7; // Convert to Sunday = 0 format
        switch (h.frequency) {
          case HabitFrequency.Daily:
            return true;
          case HabitFrequency.Weekdays:
            return date.weekday <= 5;
          case HabitFrequency.Weekends:
            return date.weekday > 5;
          case HabitFrequency.CustomDays:
            return h.customDays.contains(dayOfWeek);
          default:
            return true; // For other frequencies, assume due
        }
      }).toList();
      
      final completedOnDay = dayHabits.where((h) {
        final dayEntries = h.entries.where((e) => 
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day &&
          h.isPositiveDay(e)
        );
        return dayEntries.isNotEmpty;
      }).length;
      
      return {
        'day': dayInfo['day'],
        'completed': completedOnDay,
        'total': dayHabits.length,
        'percentage': dayHabits.isEmpty ? 100 : (completedOnDay / dayHabits.length * 100).round(),
      };
    }).toList();
  }
  
  // Update widget when habit is completed
  static Future<void> onHabitCompleted(Habit habit) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    
    await updateHomeWidgets();
    
    // Show notification if all habits are completed
    final habits = await StorageService.loadAll();
    final today = DateTime.now();
    final dueToday = habits.where((h) => h.isDueToday() && !h.isArchived && !h.isPaused).length;
    final completedToday = habits.where((h) {
      final todayEntries = h.entries.where((e) => 
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day &&
        h.isPositiveDay(e)
      );
      return todayEntries.isNotEmpty && !h.isArchived && !h.isPaused;
    }).length;
    
    if (dueToday > 0 && completedToday == dueToday) {
      try {
        await HomeWidget.saveWidgetData<String>('celebrationMessage', '🎉 All habits completed today!');
        await HomeWidget.updateWidget(name: _widgetName);
      } catch (e) {
        debugPrint('Error updating celebration widget: $e');
      }
    }
  }
  
  // Handle widget tap actions
  static Future<void> handleWidgetTap(String action) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    
    switch (action) {
      case 'open_app':
        // This would typically open the main app
        break;
      case 'quick_log':
        // This could trigger a quick log dialog
        break;
      case 'view_progress':
        // Open progress/analytics screen
        break;
    }
  }
  
  // Check if widgets are supported on this platform
  static Future<bool> isWidgetSupported() async {
    return Platform.isAndroid || Platform.isIOS;
  }
  
  // Get widget configuration options
  static List<WidgetConfig> getWidgetConfigs() {
    return [
      WidgetConfig(
        name: 'Small Progress',
        description: 'Shows today\'s completion progress',
        size: WidgetSize.small,
        supportedActions: ['open_app'],
      ),
      WidgetConfig(
        name: 'Medium Dashboard',
        description: 'Progress with statistics',
        size: WidgetSize.medium,
        supportedActions: ['open_app', 'quick_log'],
      ),
      WidgetConfig(
        name: 'Large Overview',
        description: 'Full week progress and top habits',
        size: WidgetSize.large,
        supportedActions: ['open_app', 'quick_log', 'view_progress'],
      ),
    ];
  }
}

// Data classes for widget configuration
class WidgetConfig {
  final String name;
  final String description;
  final WidgetSize size;
  final List<String> supportedActions;
  
  WidgetConfig({
    required this.name,
    required this.description,
    required this.size,
    required this.supportedActions,
  });
}

enum WidgetSize { small, medium, large }

// Widget themes
class WidgetTheme {
  final Color backgroundColor;
  final Color primaryColor;
  final Color textColor;
  final Color accentColor;
  
  const WidgetTheme({
    required this.backgroundColor,
    required this.primaryColor,
    required this.textColor,
    required this.accentColor,
  });
  
  static const light = WidgetTheme(
    backgroundColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF1DB954),
    textColor: Color(0xFF000000),
    accentColor: Color(0xFF666666),
  );
  
  static const dark = WidgetTheme(
    backgroundColor: Color(0xFF1C1C1E),
    primaryColor: Color(0xFF1DB954),
    textColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFF999999),
  );
} 