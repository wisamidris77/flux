import 'package:flutter/material.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:intl/intl.dart';

class ReportsService {
  // Generate Year in Review report
  static YearInReviewData generateYearInReview(List<Habit> habits, int year) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    
    // Filter entries for the year
    final yearHabits = habits.map((habit) {
      final yearEntries = habit.entries.where((entry) =>
          entry.date.year == year).toList();
      
      return Habit(
        name: habit.name,
        type: habit.type,
        displayMode: habit.displayMode,
        icon: habit.icon,
        color: habit.color,
        isArchived: habit.isArchived,
        notes: habit.notes,
        reminderHour: habit.reminderHour,
        reminderMinute: habit.reminderMinute,
        hasReminder: habit.hasReminder,
        category: habit.category,
        frequency: habit.frequency,
        customDays: habit.customDays,
        targetFrequency: habit.targetFrequency,
        targetValue: habit.targetValue,
        unit: habit.unit,
        customUnit: habit.customUnit,
        entries: yearEntries,
      );
    }).where((h) => h.entries.isNotEmpty).toList();
    
    if (yearHabits.isEmpty) {
      return YearInReviewData.empty(year);
    }
    
    // Calculate statistics
    final totalEntries = yearHabits.fold(0, (sum, h) => sum + h.entries.length);
    final totalDaysTracked = yearHabits
        .expand((h) => h.entries)
        .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
        .toSet()
        .length;
    
    // Find best habit
    final bestHabit = yearHabits.reduce((a, b) => 
        a.successRate > b.successRate ? a : b);
    
    // Find longest streak
    var longestStreak = 0;
    Habit? longestStreakHabit;
    for (var habit in yearHabits) {
      if (habit.bestStreak > longestStreak) {
        longestStreak = habit.bestStreak;
        longestStreakHabit = habit;
      }
    }
    
    // Most consistent habit (highest number of entries)
    final mostConsistent = yearHabits.reduce((a, b) => 
        a.entries.length > b.entries.length ? a : b);
    
    // Monthly breakdown
    final monthlyData = <int, MonthlyData>{};
    for (int month = 1; month <= 12; month++) {
      final monthEntries = yearHabits
          .expand((h) => h.entries)
          .where((e) => e.date.month == month)
          .toList();
      
      final successfulEntries = monthEntries.where((e) {
        final habit = yearHabits.firstWhere((h) => h.entries.contains(e));
        return habit.isPositiveDay(e);
      }).length;
      
      monthlyData[month] = MonthlyData(
        month: month,
        totalEntries: monthEntries.length,
        successfulEntries: successfulEntries,
        successRate: monthEntries.isEmpty ? 0.0 : (successfulEntries / monthEntries.length) * 100,
      );
    }
    
    // Category breakdown
    final categoryStats = <String, CategoryStats>{};
    for (var habit in yearHabits) {
      final category = habit.category ?? 'Uncategorized';
      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = CategoryStats(
          name: category,
          habits: [],
          totalEntries: 0,
          successfulEntries: 0,
        );
      }
      
      categoryStats[category]!.habits.add(habit);
      categoryStats[category]!.totalEntries += habit.entries.length;
      categoryStats[category]!.successfulEntries += habit.positiveCount;
    }
    
    // Milestones achieved
    final milestones = _calculateMilestones(yearHabits);
    
    // Challenges overcome
    final challenges = _identifyChallenges(yearHabits);
    
    // Growth insights
    final insights = _generateGrowthInsights(yearHabits);
    
    return YearInReviewData(
      year: year,
      totalHabits: yearHabits.length,
      totalEntries: totalEntries,
      totalDaysTracked: totalDaysTracked,
      overallSuccessRate: yearHabits.fold(0.0, (sum, h) => sum + h.successRate) / yearHabits.length,
      bestHabit: bestHabit,
      longestStreak: longestStreak,
      longestStreakHabit: longestStreakHabit,
      mostConsistentHabit: mostConsistent,
      monthlyData: monthlyData,
      categoryStats: categoryStats,
      milestones: milestones,
      challenges: challenges,
      insights: insights,
    );
  }
  
  // Generate Monthly Report
  static MonthlyReportData generateMonthlyReport(List<Habit> habits, int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month
    
    final monthHabits = habits.map((habit) {
      final monthEntries = habit.entries.where((entry) =>
          entry.date.year == year && entry.date.month == month).toList();
      
      return Habit(
        name: habit.name,
        type: habit.type,
        displayMode: habit.displayMode,
        icon: habit.icon,
        color: habit.color,
        isArchived: habit.isArchived,
        notes: habit.notes,
        reminderHour: habit.reminderHour,
        reminderMinute: habit.reminderMinute,
        hasReminder: habit.hasReminder,
        category: habit.category,
        frequency: habit.frequency,
        customDays: habit.customDays,
        targetFrequency: habit.targetFrequency,
        targetValue: habit.targetValue,
        unit: habit.unit,
        customUnit: habit.customUnit,
        entries: monthEntries,
      );
    }).toList();
    
    // Weekly breakdown
    final weeklyData = <int, WeeklyData>{};
    final calendar = List.generate(endDate.day, (i) => DateTime(year, month, i + 1));
    
    for (int week = 1; week <= 5; week++) {
      final weekDays = calendar.where((date) {
        final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
        return weekOfMonth == week;
      }).toList();
      
      if (weekDays.isEmpty) continue;
      
      final weekEntries = monthHabits
          .expand((h) => h.entries)
          .where((e) => weekDays.any((d) => 
              d.year == e.date.year && d.month == e.date.month && d.day == e.date.day))
          .toList();
      
      final successfulEntries = weekEntries.where((e) {
        final habit = monthHabits.firstWhere((h) => h.entries.contains(e));
        return habit.isPositiveDay(e);
      }).length;
      
      weeklyData[week] = WeeklyData(
        week: week,
        startDate: weekDays.first,
        endDate: weekDays.last,
        totalEntries: weekEntries.length,
        successfulEntries: successfulEntries,
        successRate: weekEntries.isEmpty ? 0.0 : (successfulEntries / weekEntries.length) * 100,
      );
    }
    
    // Top performing habits
    final activeHabits = monthHabits.where((h) => h.entries.isNotEmpty).toList();
    activeHabits.sort((a, b) => b.successRate.compareTo(a.successRate));
    
    // Identify trends
    final trends = _identifyMonthlyTrends(monthHabits);
    
    return MonthlyReportData(
      year: year,
      month: month,
      monthName: DateFormat('MMMM').format(DateTime(year, month)),
      totalHabits: activeHabits.length,
      totalEntries: activeHabits.fold(0, (sum, h) => sum + h.entries.length),
      averageSuccessRate: activeHabits.isEmpty ? 0.0 : 
          activeHabits.fold(0.0, (sum, h) => sum + h.successRate) / activeHabits.length,
      topPerformers: activeHabits.take(3).toList(),
      weeklyData: weeklyData,
      trends: trends,
    );
  }
  
  // Generate Weekly Report
  static WeeklyReportData generateWeeklyReport(List<Habit> habits, DateTime weekStart) {
    final weekEnd = weekStart.add(Duration(days: 6));
    
    final weekHabits = habits.map((habit) {
      final weekEntries = habit.entries.where((entry) =>
          entry.date.isAfter(weekStart.subtract(Duration(days: 1))) &&
          entry.date.isBefore(weekEnd.add(Duration(days: 1)))).toList();
      
      return Habit(
        name: habit.name,
        type: habit.type,
        displayMode: habit.displayMode,
        icon: habit.icon,
        color: habit.color,
        isArchived: habit.isArchived,
        notes: habit.notes,
        reminderHour: habit.reminderHour,
        reminderMinute: habit.reminderMinute,
        hasReminder: habit.hasReminder,
        category: habit.category,
        frequency: habit.frequency,
        customDays: habit.customDays,
        targetFrequency: habit.targetFrequency,
        targetValue: habit.targetValue,
        unit: habit.unit,
        customUnit: habit.customUnit,
        entries: weekEntries,
      );
    }).toList();
    
    // Daily breakdown
    final dailyData = <DateTime, DailyData>{};
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dayEntries = weekHabits
          .expand((h) => h.entries)
          .where((e) => 
              e.date.year == date.year && 
              e.date.month == date.month && 
              e.date.day == date.day)
          .toList();
      
      final successfulEntries = dayEntries.where((e) {
        final habit = weekHabits.firstWhere((h) => h.entries.contains(e));
        return habit.isPositiveDay(e);
      }).length;
      
      dailyData[date] = DailyData(
        date: date,
        totalEntries: dayEntries.length,
        successfulEntries: successfulEntries,
        successRate: dayEntries.isEmpty ? 0.0 : (successfulEntries / dayEntries.length) * 100,
      );
    }
    
    // Find best and worst days
    final activeDays = dailyData.values.where((d) => d.totalEntries > 0).toList();
    activeDays.sort((a, b) => b.successRate.compareTo(a.successRate));
    
    return WeeklyReportData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalEntries: dailyData.values.fold(0, (sum, d) => sum + d.totalEntries),
      averageSuccessRate: activeDays.isEmpty ? 0.0 :
          activeDays.fold(0.0, (sum, d) => sum + d.successRate) / activeDays.length,
      bestDay: activeDays.isNotEmpty ? activeDays.first : null,
      worstDay: activeDays.isNotEmpty ? activeDays.last : null,
      dailyData: dailyData,
    );
  }
  
  // Private helper methods
  static List<MilestoneData> _calculateMilestones(List<Habit> habits) {
    List<MilestoneData> milestones = [];
    
    for (var habit in habits) {
      // First entry milestone
      if (habit.entries.isNotEmpty) {
        milestones.add(MilestoneData(
          title: 'Started "${habit.formattedName}"',
          description: 'Began tracking this habit',
          date: habit.entries.first.date,
          type: MilestoneType.FirstEntry,
          habit: habit,
        ));
      }
      
      // Streak milestones
      if (habit.bestStreak >= 30) {
        milestones.add(MilestoneData(
          title: '30-Day Streak!',
          description: '${habit.formattedName} - ${habit.bestStreak} days',
          date: _estimateStreakDate(habit, habit.bestStreak),
          type: MilestoneType.LongStreak,
          habit: habit,
        ));
      }
      
      if (habit.bestStreak >= 100) {
        milestones.add(MilestoneData(
          title: '100-Day Streak! 🎉',
          description: '${habit.formattedName} - Amazing consistency!',
          date: _estimateStreakDate(habit, 100),
          type: MilestoneType.MajorStreak,
          habit: habit,
        ));
      }
      
      // Entry count milestones
      if (habit.entries.length >= 50) {
        milestones.add(MilestoneData(
          title: '50 Entries',
          description: '${habit.formattedName} - Half century!',
          date: habit.entries.length >= 50 ? habit.entries[49].date : habit.entries.last.date,
          type: MilestoneType.EntryCount,
          habit: habit,
        ));
      }
      
      if (habit.entries.length >= 100) {
        milestones.add(MilestoneData(
          title: '100 Entries! 🔥',
          description: '${habit.formattedName} - Incredible dedication!',
          date: habit.entries.length >= 100 ? habit.entries[99].date : habit.entries.last.date,
          type: MilestoneType.MajorEntryCount,
          habit: habit,
        ));
      }
    }
    
    milestones.sort((a, b) => a.date.compareTo(b.date));
    return milestones;
  }
  
  static DateTime _estimateStreakDate(Habit habit, int streakLength) {
    final sortedEntries = [...habit.entries]..sort((a, b) => a.date.compareTo(b.date));
    if (sortedEntries.length >= streakLength) {
      return sortedEntries[streakLength - 1].date;
    }
    return sortedEntries.last.date;
  }
  
  static List<ChallengeData> _identifyChallenges(List<Habit> habits) {
    List<ChallengeData> challenges = [];
    
    for (var habit in habits) {
      // Low success rate challenge
      if (habit.successRate < 50 && habit.entries.length >= 10) {
        challenges.add(ChallengeData(
          title: 'Struggled with ${habit.formattedName}',
          description: 'Only ${habit.successRate.toStringAsFixed(1)}% success rate',
          severity: ChallengeSeverity.High,
          habit: habit,
        ));
      }
      
      // Long gaps in tracking
      final gaps = _findLargestGaps(habit.entries);
      if (gaps.isNotEmpty && gaps.first > 7) {
        challenges.add(ChallengeData(
          title: 'Tracking Gap',
          description: '${gaps.first} days without tracking ${habit.formattedName}',
          severity: ChallengeSeverity.Medium,
          habit: habit,
        ));
      }
      
      // Declined performance
      if (_hasDeclinedPerformance(habit)) {
        challenges.add(ChallengeData(
          title: 'Performance Decline',
          description: '${habit.formattedName} success rate decreased over time',
          severity: ChallengeSeverity.Medium,
          habit: habit,
        ));
      }
    }
    
    return challenges;
  }
  
  static List<int> _findLargestGaps(List<HabitEntry> entries) {
    if (entries.length < 2) return [];
    
    final sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    List<int> gaps = [];
    
    for (int i = 1; i < sortedEntries.length; i++) {
      final gap = sortedEntries[i].date.difference(sortedEntries[i - 1].date).inDays - 1;
      if (gap > 0) {
        gaps.add(gap);
      }
    }
    
    gaps.sort((a, b) => b.compareTo(a)); // Largest first
    return gaps;
  }
  
  static bool _hasDeclinedPerformance(Habit habit) {
    if (habit.entries.length < 10) return false;
    
    final sortedEntries = [...habit.entries]..sort((a, b) => a.date.compareTo(b.date));
    final firstHalf = sortedEntries.take(sortedEntries.length ~/ 2).toList();
    final secondHalf = sortedEntries.skip(sortedEntries.length ~/ 2).toList();
    
    final firstHalfSuccessRate = firstHalf.where((e) => habit.isPositiveDay(e)).length / firstHalf.length;
    final secondHalfSuccessRate = secondHalf.where((e) => habit.isPositiveDay(e)).length / secondHalf.length;
    
    return secondHalfSuccessRate < firstHalfSuccessRate - 0.2; // 20% decline
  }
  
  static List<InsightData> _generateGrowthInsights(List<Habit> habits) {
    List<InsightData> insights = [];
    
    // Overall growth
    final totalHabits = habits.length;
    if (totalHabits > 0) {
      insights.add(InsightData(
        title: 'Habit Portfolio',
        description: 'You tracked $totalHabits different habits this year',
        icon: Icons.trending_up,
        color: Colors.blue,
      ));
    }
    
    // Category insights
    final categories = habits.where((h) => h.category != null).map((h) => h.category!).toSet();
    if (categories.length > 1) {
      insights.add(InsightData(
        title: 'Well-Rounded',
        description: 'You worked on ${categories.length} different areas of your life',
        icon: Icons.balance,
        color: Colors.green,
      ));
    }
    
    // Consistency insights
    final consistentHabits = habits.where((h) => h.successRate > 80).length;
    if (consistentHabits > 0) {
      insights.add(InsightData(
        title: 'Consistency Master',
        description: '$consistentHabits habit(s) with over 80% success rate',
        icon: Icons.stars,
        color: Colors.orange,
      ));
    }
    
    return insights;
  }
  
  static List<TrendData> _identifyMonthlyTrends(List<Habit> habits) {
    List<TrendData> trends = [];
    
    // Check for improving habits
    final improvingHabits = habits.where((h) => _isImproving(h)).toList();
    if (improvingHabits.isNotEmpty) {
      trends.add(TrendData(
        title: 'Improving Trends',
        description: '${improvingHabits.length} habit(s) showing improvement',
        type: TrendType.Positive,
        habits: improvingHabits,
      ));
    }
    
    // Check for declining habits
    final decliningHabits = habits.where((h) => _isDecline(h)).toList();
    if (decliningHabits.isNotEmpty) {
      trends.add(TrendData(
        title: 'Needs Attention',
        description: '${decliningHabits.length} habit(s) showing decline',
        type: TrendType.Negative,
        habits: decliningHabits,
      ));
    }
    
    return trends;
  }
  
  static bool _isImproving(Habit habit) {
    if (habit.entries.length < 6) return false;
    
    final recent = habit.entries.take(habit.entries.length ~/ 2).where((e) => habit.isPositiveDay(e)).length;
    final older = habit.entries.skip(habit.entries.length ~/ 2).where((e) => habit.isPositiveDay(e)).length;
    
    return recent > older;
  }
  
  static bool _isDecline(Habit habit) {
    if (habit.entries.length < 6) return false;
    
    final recent = habit.entries.take(habit.entries.length ~/ 2).where((e) => habit.isPositiveDay(e)).length;
    final older = habit.entries.skip(habit.entries.length ~/ 2).where((e) => habit.isPositiveDay(e)).length;
    
    return recent < older * 0.8; // 20% decline
  }
}

// Data classes for reports
class YearInReviewData {
  final int year;
  final int totalHabits;
  final int totalEntries;
  final int totalDaysTracked;
  final double overallSuccessRate;
  final Habit bestHabit;
  final int longestStreak;
  final Habit? longestStreakHabit;
  final Habit mostConsistentHabit;
  final Map<int, MonthlyData> monthlyData;
  final Map<String, CategoryStats> categoryStats;
  final List<MilestoneData> milestones;
  final List<ChallengeData> challenges;
  final List<InsightData> insights;
  
  YearInReviewData({
    required this.year,
    required this.totalHabits,
    required this.totalEntries,
    required this.totalDaysTracked,
    required this.overallSuccessRate,
    required this.bestHabit,
    required this.longestStreak,
    required this.longestStreakHabit,
    required this.mostConsistentHabit,
    required this.monthlyData,
    required this.categoryStats,
    required this.milestones,
    required this.challenges,
    required this.insights,
  });
  
  static YearInReviewData empty(int year) {
    return YearInReviewData(
      year: year,
      totalHabits: 0,
      totalEntries: 0,
      totalDaysTracked: 0,
      overallSuccessRate: 0.0,
      bestHabit: Habit(name: 'None'),
      longestStreak: 0,
      longestStreakHabit: null,
      mostConsistentHabit: Habit(name: 'None'),
      monthlyData: {},
      categoryStats: {},
      milestones: [],
      challenges: [],
      insights: [],
    );
  }
}

class MonthlyReportData {
  final int year;
  final int month;
  final String monthName;
  final int totalHabits;
  final int totalEntries;
  final double averageSuccessRate;
  final List<Habit> topPerformers;
  final Map<int, WeeklyData> weeklyData;
  final List<TrendData> trends;
  
  MonthlyReportData({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalHabits,
    required this.totalEntries,
    required this.averageSuccessRate,
    required this.topPerformers,
    required this.weeklyData,
    required this.trends,
  });
}

class WeeklyReportData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalEntries;
  final double averageSuccessRate;
  final DailyData? bestDay;
  final DailyData? worstDay;
  final Map<DateTime, DailyData> dailyData;
  
  WeeklyReportData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalEntries,
    required this.averageSuccessRate,
    required this.bestDay,
    required this.worstDay,
    required this.dailyData,
  });
}

class MonthlyData {
  final int month;
  final int totalEntries;
  final int successfulEntries;
  final double successRate;
  
  MonthlyData({
    required this.month,
    required this.totalEntries,
    required this.successfulEntries,
    required this.successRate,
  });
}

class WeeklyData {
  final int week;
  final DateTime startDate;
  final DateTime endDate;
  final int totalEntries;
  final int successfulEntries;
  final double successRate;
  
  WeeklyData({
    required this.week,
    required this.startDate,
    required this.endDate,
    required this.totalEntries,
    required this.successfulEntries,
    required this.successRate,
  });
}

class DailyData {
  final DateTime date;
  final int totalEntries;
  final int successfulEntries;
  final double successRate;
  
  DailyData({
    required this.date,
    required this.totalEntries,
    required this.successfulEntries,
    required this.successRate,
  });
}

class CategoryStats {
  final String name;
  final List<Habit> habits;
  int totalEntries;
  int successfulEntries;
  
  CategoryStats({
    required this.name,
    required this.habits,
    required this.totalEntries,
    required this.successfulEntries,
  });
  
  double get successRate => totalEntries > 0 ? (successfulEntries / totalEntries) * 100 : 0.0;
}

class MilestoneData {
  final String title;
  final String description;
  final DateTime date;
  final MilestoneType type;
  final Habit habit;
  
  MilestoneData({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.habit,
  });
}

class ChallengeData {
  final String title;
  final String description;
  final ChallengeSeverity severity;
  final Habit habit;
  
  ChallengeData({
    required this.title,
    required this.description,
    required this.severity,
    required this.habit,
  });
}

class InsightData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  InsightData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class TrendData {
  final String title;
  final String description;
  final TrendType type;
  final List<Habit> habits;
  
  TrendData({
    required this.title,
    required this.description,
    required this.type,
    required this.habits,
  });
}

enum MilestoneType {
  FirstEntry,
  LongStreak,
  MajorStreak,
  EntryCount,
  MajorEntryCount,
}

enum ChallengeSeverity {
  Low,
  Medium,
  High,
}

enum TrendType {
  Positive,
  Negative,
  Neutral,
} 