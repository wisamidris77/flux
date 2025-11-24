// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart'; // Import enums from the new file
import 'package:flux/data/models/habit_entry.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class Habit {
  String id; // Unique identifier
  String name;
  HabitType type;
  ReportDisplay displayMode;
  IconData? icon;
  List<HabitEntry> entries;
  Color? color;
  bool isArchived;
  String? notes;
  int? reminderHour;
  int? reminderMinute;
  bool hasReminder;
  
  // New fields for enhanced functionality
  String? category; // Habit category/group
  HabitFrequency frequency; // How often the habit should occur
  List<int> customDays; // For CustomDays frequency (0=Sunday, 6=Saturday)
  int? targetFrequency; // For XTimesPerWeek/Month
  double? targetValue; // Target value for measurable goals
  HabitUnit unit; // Unit of measurement
  String? customUnit; // Custom unit name
  DateTime? pauseStartDate; // When habit was paused
  DateTime? pauseEndDate; // When pause ends
  bool isPaused; // Whether habit is currently paused
  
  // Gamification fields
  int totalPoints;
  int level;
  double experiencePoints;
  List<String> unlockedAchievements;
  List<String> unlockedThemes;
  List<IconData> unlockedIcons;
  
  // Location-based reminder
  String? locationReminder;
  double? reminderLatitude;
  double? reminderLongitude;
  double? reminderRadius;
  
  // Difficulty multiplier for points
  double difficultyMultiplier;
  
  // Custom motivational messages
  List<String> motivationalMessages;
  String? customSuccessMessage;
  String? customFailureMessage;
  
  Habit({
    String? id,
    required this.name, 
    this.type = HabitType.DoneBased,
    this.displayMode = ReportDisplay.Rate, 
    this.icon, 
    this.color,
    this.isArchived = false,
    this.notes,
    this.reminderHour,
    this.reminderMinute,
    this.hasReminder = false,
    this.category,
    this.frequency = HabitFrequency.Daily,
    this.customDays = const [],
    this.targetFrequency,
    this.targetValue,
    this.unit = HabitUnit.Count,
    this.customUnit,
    this.pauseStartDate,
    this.pauseEndDate,
    this.isPaused = false,
    List<HabitEntry>? entries,
    this.totalPoints = 0,
    this.level = 1,
    this.experiencePoints = 0.0,
    List<String>? unlockedAchievements,
    List<String>? unlockedThemes,
    List<IconData>? unlockedIcons,
    this.locationReminder,
    this.reminderLatitude,
    this.reminderLongitude,
    this.reminderRadius,
    this.difficultyMultiplier = 1.0,
    List<String>? motivationalMessages,
    this.customSuccessMessage,
    this.customFailureMessage,
  }) : 
    id = id ?? const Uuid().v4(),
    entries = entries ?? [],
    unlockedAchievements = unlockedAchievements ?? [],
    unlockedThemes = unlockedThemes ?? ['default'],
    unlockedIcons = unlockedIcons ?? [],
    motivationalMessages = motivationalMessages ?? [
      "You've got this! 💪",
      "Every day is a new opportunity! ✨",
      "Small steps lead to big changes! 🚀",
      "Consistency is key! 🔑",
      "Believe in yourself! 🌟"
    ];
  
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'displayMode': displayMode.index,
        'icon': icon?.codePoint,
        'color': color?.value,
        'isArchived': isArchived,
        'notes': notes,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'hasReminder': hasReminder,
        'category': category,
        'frequency': frequency.index,
        'customDays': customDays,
        'targetFrequency': targetFrequency,
        'targetValue': targetValue,
        'unit': unit.index,
        'customUnit': customUnit,
        'pauseStartDate': pauseStartDate?.toIso8601String(),
        'pauseEndDate': pauseEndDate?.toIso8601String(),
        'isPaused': isPaused,
        'entries': entries.map((e) => e.toJson()).toList(),
        'totalPoints': totalPoints,
        'level': level,
        'experiencePoints': experiencePoints,
        'unlockedAchievements': unlockedAchievements,
        'unlockedThemes': unlockedThemes,
        'unlockedIcons': unlockedIcons.map((i) => i.codePoint).toList(),
        'locationReminder': locationReminder,
        'reminderLatitude': reminderLatitude,
        'reminderLongitude': reminderLongitude,
        'reminderRadius': reminderRadius,
        'difficultyMultiplier': difficultyMultiplier,
        'motivationalMessages': motivationalMessages,
        'customSuccessMessage': customSuccessMessage,
        'customFailureMessage': customFailureMessage,
      };
      
  static Habit fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        type: HabitType.values[json['type'] ?? 1],
        displayMode: ReportDisplay.values[json['displayMode'] ?? 0],
        icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
        color: json['color'] != null ? Color(json['color']) : null,
        isArchived: json['isArchived'] ?? false,
        notes: json['notes'],
        reminderHour: json['reminderHour'],
        reminderMinute: json['reminderMinute'],
        hasReminder: json['hasReminder'] ?? false,
        category: json['category'],
        frequency: HabitFrequency.values[json['frequency'] ?? 0],
        customDays: List<int>.from(json['customDays'] ?? []),
        targetFrequency: json['targetFrequency'],
        targetValue: json['targetValue']?.toDouble(),
        unit: HabitUnit.values[json['unit'] ?? 0],
        customUnit: json['customUnit'],
        pauseStartDate: json['pauseStartDate'] != null ? DateTime.parse(json['pauseStartDate']) : null,
        pauseEndDate: json['pauseEndDate'] != null ? DateTime.parse(json['pauseEndDate']) : null,
        isPaused: json['isPaused'] ?? false,
        entries: (json['entries'] as List?)
            ?.map((e) => HabitEntry.fromJson(e))
            .toList() ?? [],
        totalPoints: json['totalPoints'] ?? 0,
        level: json['level'] ?? 1,
        experiencePoints: json['experiencePoints']?.toDouble() ?? 0.0,
        unlockedAchievements: List<String>.from(json['unlockedAchievements'] ?? []),
        unlockedThemes: List<String>.from(json['unlockedThemes'] ?? ['default']),
        unlockedIcons: (json['unlockedIcons'] as List?)
            ?.map((i) => IconData(i, fontFamily: 'MaterialIcons'))
            .toList() ?? [],
        locationReminder: json['locationReminder'],
        reminderLatitude: json['reminderLatitude']?.toDouble(),
        reminderLongitude: json['reminderLongitude']?.toDouble(),
        reminderRadius: json['reminderRadius']?.toDouble(),
        difficultyMultiplier: json['difficultyMultiplier']?.toDouble() ?? 1.0,
        motivationalMessages: List<String>.from(json['motivationalMessages'] ?? [
          "You've got this! 💪",
          "Every day is a new opportunity! ✨",
          "Small steps lead to big changes! 🚀",
          "Consistency is key! 🔑",
          "Believe in yourself! 🌟"
        ]),
        customSuccessMessage: json['customSuccessMessage'],
        customFailureMessage: json['customFailureMessage'],
      );
      
  int getNextDayNumber() {
    return entries.isEmpty ? 1 : entries.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
  }
  
  bool isPositiveDay(HabitEntry entry) {
    if (entry.isSkipped) return true; // Skipped days don't break streaks
    
    switch (type) {
      case HabitType.FailBased:
        if (targetValue != null && entry.value != null) {
          return entry.value! <= targetValue!; // Success if under target for avoid habits
        }
        return entry.count == 0;
      case HabitType.SuccessBased:
        if (targetValue != null && entry.value != null) {
          return entry.value! >= targetValue!; // Success if meeting target
        }
        return entry.count > 0;
      case HabitType.DoneBased:
        return entry.count > 0;
    }
  }
  
  // Check if habit is due today based on frequency
  bool isDueToday() {
    if (isPaused) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (frequency) {
      case HabitFrequency.Daily:
        return true;
      case HabitFrequency.Weekdays:
        return now.weekday <= 5; // Monday = 1, Friday = 5
      case HabitFrequency.Weekends:
        return now.weekday > 5; // Saturday = 6, Sunday = 7
      case HabitFrequency.CustomDays:
        final todayIndex = now.weekday % 7; // Convert to 0=Sunday format
        return customDays.contains(todayIndex);
      case HabitFrequency.XTimesPerWeek:
      case HabitFrequency.XTimesPerMonth:
        return _checkFrequencyTarget(today);
    }
  }
  
  bool _checkFrequencyTarget(DateTime today) {
    if (targetFrequency == null) return true;
    
    if (frequency == HabitFrequency.XTimesPerWeek) {
      final weekStart = today.subtract(Duration(days: today.weekday % 7));
      final weekEnd = weekStart.add(Duration(days: 6));
      final weekEntries = entries.where((e) => 
        e.date.isAfter(weekStart.subtract(Duration(days: 1))) && 
        e.date.isBefore(weekEnd.add(Duration(days: 1))) &&
        isPositiveDay(e)
      ).length;
      return weekEntries < targetFrequency!;
    } else if (frequency == HabitFrequency.XTimesPerMonth) {
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      final monthEntries = entries.where((e) => 
        e.date.isAfter(monthStart.subtract(Duration(days: 1))) && 
        e.date.isBefore(monthEnd.add(Duration(days: 1))) &&
        isPositiveDay(e)
      ).length;
      return monthEntries < targetFrequency!;
    }
    
    return true;
  }
  
  // Get time since last failure for avoid habits
  String getTimeSinceLastFailure() {
    if (type != HabitType.FailBased || entries.isEmpty) return "No data";
    
    final failureEntries = entries.where((e) => !isPositiveDay(e) && !e.isSkipped).toList();
    if (failureEntries.isEmpty) {
      // Never failed, show time since first entry
      final firstEntry = entries.first;
      final duration = DateTime.now().difference(firstEntry.date);
      return _formatDuration(duration);
    }
    
    failureEntries.sort((a, b) => b.date.compareTo(a.date));
    final lastFailure = failureEntries.first;
    final duration = DateTime.now().difference(lastFailure.date);
    return _formatDuration(duration);
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays}d clean";
    } else if (duration.inHours > 0) {
      return "${duration.inHours}h clean";
    } else {
      return "${duration.inMinutes}m clean";
    }
  }
  
  int get positiveCount => entries.where((e) => isPositiveDay(e)).length;
  int get negativeCount => entries.length - positiveCount;
  double get successRate => entries.isEmpty ? 0 : (positiveCount / entries.length) * 100;
  
  // Calculate streaks considering frequency
  int get currentStreak {
    int streak = 0;
    if (entries.isEmpty) return 0;
    
    var sortedEntries = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    
    // For frequency-based habits, we need to check expected days
    if (frequency != HabitFrequency.Daily) {
      return _calculateFrequencyStreak(sortedEntries);
    }
    
    // Daily habit streak calculation
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  int _calculateFrequencyStreak(List<HabitEntry> sortedEntries) {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        streak++;
        currentDate = entry.date;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  int get bestStreak {
    if (entries.isEmpty) return 0;
    
    int currentBest = 0;
    int current = 0;
    
    var sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        current++;
        if (current > currentBest) {
          currentBest = current;
        }
      } else {
        current = 0;
      }
    }
    
    return currentBest;
  }
  
  // Add extra utility methods
  
  String get formattedName {
    return formatPascalCase(name);
  }
  
  bool get hasEntries => entries.isNotEmpty;
  
  // Get total value/count aggregated
  double getTotalValue() {
    return entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble()));
  }
  
  // Get average value per entry
  double getAverageValue() {
    if (entries.isEmpty) return 0.0;
    return getTotalValue() / entries.length;
  }
  
  // Get unit display name
  String getUnitDisplayName() {
    switch (unit) {
      case HabitUnit.Count:
        return 'times';
      case HabitUnit.Minutes:
        return 'min';
      case HabitUnit.Hours:
        return 'hrs';
      case HabitUnit.Pages:
        return 'pages';
      case HabitUnit.Kilometers:
        return 'km';
      case HabitUnit.Miles:
        return 'miles';
      case HabitUnit.Grams:
        return 'g';
      case HabitUnit.Pounds:
        return 'lbs';
      case HabitUnit.Dollars:
        return '\$';
      case HabitUnit.Custom:
        return customUnit ?? 'units';
    }
  }
  
  // Negative streak
  int get longestNegativeStreak {
    if (entries.isEmpty) return 0;
    
    int currentNegative = 0;
    int maxNegative = 0;
    
    var sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    
    for (var entry in sortedEntries) {
      if (!isPositiveDay(entry)) {
        currentNegative++;
        if (currentNegative > maxNegative) {
          maxNegative = currentNegative;
        }
      } else {
        currentNegative = 0;
      }
    }
    
    return maxNegative;
  }

  // Gamification Methods
  
  // Calculate points for an entry
  int calculatePoints(HabitEntry entry) {
    if (entry.isSkipped) return 0;
    
    int basePoints = 10;
    
    // Bonus for positive days
    if (isPositiveDay(entry)) {
      basePoints += 20;
    }
    
    // Streak bonus
    final streakMultiplier = (currentStreak / 7).floor() + 1; // Bonus every 7 days
    basePoints += streakMultiplier * 5;
    
    // Difficulty multiplier
    basePoints = (basePoints * difficultyMultiplier).round();
    
    // Type-based bonus
    switch (type) {
      case HabitType.FailBased:
        basePoints += 15; // Harder to avoid than to do
        break;
      case HabitType.SuccessBased:
        basePoints += 10;
        break;
      case HabitType.DoneBased:
        basePoints += 5;
        break;
    }
    
    return basePoints;
  }
  
  // Add points and check for level up
  List<String> addPoints(int points) {
    totalPoints += points;
    experiencePoints += points.toDouble();
    
    List<String> levelUpMessages = [];
    int newLevel = calculateLevel();
    
    while (level < newLevel) {
      level++;
      levelUpMessages.add("🎉 Level $level reached!");
      
      // Unlock rewards based on level
      final rewards = getLevelRewards(level);
      for (var reward in rewards) {
        levelUpMessages.add("🎁 Unlocked: $reward");
      }
    }
    
    return levelUpMessages;
  }
  
  // Calculate current level based on experience points
  int calculateLevel() {
    // Level formula: level = sqrt(experiencePoints / 100) + 1
    // This means: Level 2 = 100 XP, Level 3 = 400 XP, Level 4 = 900 XP, etc.
    return sqrt(experiencePoints / 100).floor() + 1;
  }
  
  // Get experience points needed for next level
  int getXPForNextLevel() {
    final nextLevel = level + 1;
    return (nextLevel - 1) * (nextLevel - 1) * 100;
  }
  
  // Get current level progress as percentage
  double getLevelProgress() {
    final currentLevelXP = (level - 1) * (level - 1) * 100;
    final nextLevelXP = getXPForNextLevel();
    final currentProgress = experiencePoints - currentLevelXP;
    final totalNeeded = nextLevelXP - currentLevelXP;
    
    return totalNeeded > 0 ? (currentProgress / totalNeeded).clamp(0.0, 1.0) : 1.0;
  }
  
  // Get rewards for reaching a level
  List<String> getLevelRewards(int level) {
    List<String> rewards = [];
    
    // Every 5 levels: new theme
    if (level % 5 == 0) {
      final newTheme = "theme_level_$level";
      if (!unlockedThemes.contains(newTheme)) {
        unlockedThemes.add(newTheme);
        rewards.add("New Theme: Level $level");
      }
    }
    
    // Every 3 levels: new icon
    if (level % 3 == 0) {
      final iconOptions = [
        Icons.star_border, Icons.favorite_border, Icons.diamond,
        Icons.local_fire_department, Icons.emoji_events, Icons.military_tech,
        Icons.workspace_premium, Icons.verified, Icons.trending_up,
      ];
      
      final iconIndex = (level ~/ 3 - 1) % iconOptions.length;
      final newIcon = iconOptions[iconIndex];
      
      if (!unlockedIcons.any((i) => i.codePoint == newIcon.codePoint)) {
        unlockedIcons.add(newIcon);
        rewards.add("New Icon unlocked");
      }
    }
    
    return rewards;
  }
  
  // Check for new achievements
  List<String> checkAchievements() {
    List<String> newAchievements = [];
    
    // Streak achievements
    final streakAchievements = {
      7: "first_week",
      30: "first_month", 
      100: "centurion",
      365: "year_warrior"
    };
    
    for (var entry in streakAchievements.entries) {
      final achievementId = entry.value;
      if (currentStreak >= entry.key && !unlockedAchievements.contains(achievementId)) {
        unlockedAchievements.add(achievementId);
        newAchievements.add("🏆 ${_getAchievementName(achievementId)}");
      }
    }
    
    // Entry count achievements
    final entryAchievements = {
      10: "getting_started",
      50: "half_century",
      100: "century_club",
      500: "dedication_master"
    };
    
    for (var entry in entryAchievements.entries) {
      final achievementId = entry.value;
      if (entries.length >= entry.key && !unlockedAchievements.contains(achievementId)) {
        unlockedAchievements.add(achievementId);
        newAchievements.add("🏆 ${_getAchievementName(achievementId)}");
      }
    }
    
    // Success rate achievements
    if (successRate >= 80 && entries.length >= 20 && !unlockedAchievements.contains("consistency_king")) {
      unlockedAchievements.add("consistency_king");
      newAchievements.add("🏆 ${_getAchievementName("consistency_king")}");
    }
    
    if (successRate >= 95 && entries.length >= 50 && !unlockedAchievements.contains("perfectionist")) {
      unlockedAchievements.add("perfectionist");
      newAchievements.add("🏆 ${_getAchievementName("perfectionist")}");
    }
    
    // Points achievements
    final pointsAchievements = {
      1000: "first_thousand",
      5000: "point_collector", 
      10000: "point_master",
      25000: "legend"
    };
    
    for (var entry in pointsAchievements.entries) {
      final achievementId = entry.value;
      if (totalPoints >= entry.key && !unlockedAchievements.contains(achievementId)) {
        unlockedAchievements.add(achievementId);
        newAchievements.add("🏆 ${_getAchievementName(achievementId)}");
      }
    }
    
    return newAchievements;
  }
  
  String _getAchievementName(String achievementId) {
    final names = {
      "first_week": "First Week Warrior",
      "first_month": "Month Master", 
      "centurion": "100-Day Centurion",
      "year_warrior": "Year Warrior",
      "getting_started": "Getting Started",
      "half_century": "Half Century",
      "century_club": "Century Club",
      "dedication_master": "Dedication Master",
      "consistency_king": "Consistency King",
      "perfectionist": "Perfectionist",
      "first_thousand": "First Thousand",
      "point_collector": "Point Collector",
      "point_master": "Point Master",
      "legend": "Legend"
    };
    
    return names[achievementId] ?? achievementId;
  }
  
  // Get a random motivational message
  String getRandomMotivationalMessage() {
    if (motivationalMessages.isEmpty) return "Keep going! 💪";
    motivationalMessages.shuffle();
    return motivationalMessages.first;
  }
  
  // Check if this is a milestone streak
  bool isStreakMilestone() {
    final milestones = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365];
    return milestones.contains(currentStreak);
  }
  
  // Get milestone message for current streak
  String getMilestoneMessage() {
    switch (currentStreak) {
      case 7:
        return "🔥 One week strong! You're building momentum!";
      case 14:
        return "⚡ Two weeks of excellence! You're unstoppable!";
      case 21:
        return "💎 Three weeks! This is becoming a real habit!";
      case 30:
        return "🏆 One month champion! You've proven your dedication!";
      case 50:
        return "🚀 Fifty days! You're in the elite zone now!";
      case 75:
        return "👑 Seventy-five days! You're absolutely crushing it!";
      case 100:
        return "🎖️ ONE HUNDRED DAYS! You're a true habit master!";
      case 150:
        return "🌟 150 days! Your consistency is inspirational!";
      case 200:
        return "🔥 200 days! You've transcended ordinary limits!";
      case 365:
        return "🏅 ONE FULL YEAR! You are a legend!";
      default:
        return "🎉 Amazing streak! Keep the momentum going!";
    }
  }
  
  // Update difficulty multiplier
  void updateDifficulty(double newMultiplier) {
    difficultyMultiplier = newMultiplier.clamp(0.5, 3.0);
  }
  
  // Get difficulty level name
  String getDifficultyName() {
    if (difficultyMultiplier <= 0.7) return "Easy";
    if (difficultyMultiplier <= 1.0) return "Normal";
    if (difficultyMultiplier <= 1.5) return "Hard";
    if (difficultyMultiplier <= 2.0) return "Expert";
    return "Master";
  }
}
