import 'dart:convert';
import 'dart:io';
import 'package:flux/core/services/database_service.dart';
import 'package:flux/data/models/habit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class DataService {
  static const String _dateFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Export all data as JSON
  static Future<String> exportToJson(List<Habit> habits) async {
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'habits': habits.map((h) => h.toJson()).toList(),
      'metadata': {
        'totalHabits': habits.length,
        'totalEntries': habits.fold(0, (sum, h) => sum + h.entries.length),
        'exportedBy': 'Flux Habit Tracker',
      }
    };
    
    return jsonEncode(exportData);
  }
  
  // Export database as SQL
  static Future<String> exportToSql() async {
    final db = await DatabaseService.instance.database;
    final path = db.path;
    final file = File(path);
    
    if (await file.exists()) {
      return file.path;
    } else {
      throw Exception('Database file not found');
    }
  }
  
  // Export all data as CSV
  static Future<String> exportToCsv(List<Habit> habits) async {
    List<List<dynamic>> csvData = [];
    
    // Headers
    csvData.add([
      'Habit Name',
      'Habit Type',
      'Category',
      'Frequency',
      'Target Value',
      'Unit',
      'Entry Date',
      'Day Number',
      'Count',
      'Value',
      'Notes',
      'Is Skipped',
      'Success Rate',
      'Current Streak',
      'Best Streak'
    ]);
    
    for (var habit in habits) {
      for (var entry in habit.entries) {
        csvData.add([
          habit.name,
          habit.type.toString().split('.').last,
          habit.category ?? '',
          habit.frequency.toString().split('.').last,
          habit.targetValue ?? '',
          habit.unit.toString().split('.').last,
          DateFormat(_dateFormat).format(entry.date),
          entry.dayNumber,
          entry.count,
          entry.value ?? '',
          entry.notes ?? '',
          entry.isSkipped,
          habit.successRate.toStringAsFixed(2),
          habit.currentStreak,
          habit.bestStreak,
        ]);
      }
      
      // Add habit row even if no entries
      if (habit.entries.isEmpty) {
        csvData.add([
          habit.name,
          habit.type.toString().split('.').last,
          habit.category ?? '',
          habit.frequency.toString().split('.').last,
          habit.targetValue ?? '',
          habit.unit.toString().split('.').last,
          '', // No entry date
          '', // No day number
          '', // No count
          '', // No value
          '', // No notes
          '', // No skip status
          habit.successRate.toStringAsFixed(2),
          habit.currentStreak,
          habit.bestStreak,
        ]);
      }
    }
    
    return ListToCsvConverter().convert(csvData);
  }
  
  // Export specific habit data
  static Future<String> exportHabitToJson(Habit habit) async {
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'habit': habit.toJson(),
      'metadata': {
        'habitName': habit.name,
        'totalEntries': habit.entries.length,
        'successRate': habit.successRate,
        'currentStreak': habit.currentStreak,
        'exportedBy': 'Flux Habit Tracker',
      }
    };
    
    return jsonEncode(exportData);
  }
  
  // Share data file
  static Future<void> shareData(String data, String filename, String mimeType) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(data);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Flux Habit Tracker Data Export',
        text: 'Here is your habit tracking data from Flux!',
      );
    } catch (e) {
      throw Exception('Failed to share data: $e');
    }
  }
  
  // Share database file
  static Future<void> shareDatabaseFile() async {
    try {
      final dbPath = await exportToSql();
      final file = File(dbPath);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Flux Habit Tracker Database Export',
        text: 'Here is your habit tracking database from Flux!',
      );
    } catch (e) {
      throw Exception('Failed to share database: $e');
    }
  }
  
  // Import data from JSON
  static Future<ImportResult> importFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      List<Habit> importedHabits = [];
      List<String> errors = [];
      
      if (data['habits'] != null) {
        for (var habitJson in data['habits']) {
          try {
            final habit = Habit.fromJson(habitJson);
            importedHabits.add(habit);
            await DatabaseService.instance.saveHabit(habit);
          } catch (e) {
            errors.add('Failed to import habit: ${habitJson['name']} - $e');
          }
        }
      } else if (data['habit'] != null) {
        // Single habit export
        try {
          final habit = Habit.fromJson(data['habit']);
          importedHabits.add(habit);
          await DatabaseService.instance.saveHabit(habit);
        } catch (e) {
          errors.add('Failed to import habit: $e');
        }
      }
      
      return ImportResult(
        habits: importedHabits,
        errors: errors,
        totalProcessed: importedHabits.length + errors.length,
      );
    } catch (e) {
      return ImportResult(
        habits: [],
        errors: ['Invalid JSON format: $e'],
        totalProcessed: 0,
      );
    }
  }
  
  // Import database file
  static Future<ImportResult> importFromDatabase(String databasePath) async {
    try {
      // Open the imported database
      final importedDb = await openDatabase(databasePath, readOnly: true);
      
      // Get the current database
      final currentDb = await DatabaseService.instance.database;
      
      // Begin transaction
      await currentDb.transaction((txn) async {
        // Get all habits from imported database
        final List<Map<String, dynamic>> habitMaps = await importedDb.query('habits');
        
        int importedCount = 0;
        List<String> errors = [];
        
        // Import each habit and its related data
        for (var habitMap in habitMaps) {
          try {
            final habitId = habitMap['id'];
            
            // Insert the habit
            await txn.insert(
              'habits',
              habitMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            
            // Import entries
            final List<Map<String, dynamic>> entryMaps = await importedDb.query(
              'entries',
              where: 'habitId = ?',
              whereArgs: [habitId],
            );
            
            for (var entryMap in entryMaps) {
              await txn.insert(
                'entries',
                entryMap,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            
            // Import custom days
            final List<Map<String, dynamic>> dayMaps = await importedDb.query(
              'custom_days',
              where: 'habitId = ?',
              whereArgs: [habitId],
            );
            
            for (var dayMap in dayMaps) {
              await txn.insert(
                'custom_days',
                dayMap,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            
            // Import unlocked achievements
            final List<Map<String, dynamic>> achievementMaps = await importedDb.query(
              'unlocked_achievements',
              where: 'habitId = ?',
              whereArgs: [habitId],
            );
            
            for (var achievementMap in achievementMaps) {
              await txn.insert(
                'unlocked_achievements',
                achievementMap,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            
            // Import unlocked themes
            final List<Map<String, dynamic>> themeMaps = await importedDb.query(
              'unlocked_themes',
              where: 'habitId = ?',
              whereArgs: [habitId],
            );
            
            for (var themeMap in themeMaps) {
              await txn.insert(
                'unlocked_themes',
                themeMap,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            
            // Import unlocked icons
            final List<Map<String, dynamic>> iconMaps = await importedDb.query(
              'unlocked_icons',
              where: 'habitId = ?',
              whereArgs: [habitId],
            );
            
            for (var iconMap in iconMaps) {
              await txn.insert(
                'unlocked_icons',
                iconMap,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            
            // Import motivational messages
            final List<Map<String, dynamic>> messageMaps = await importedDb.query(
              'motivational_messages',
              where: 'habitId = ?',
              whereArgs: [habitId],
            );
            
            for (var messageMap in messageMaps) {
              await txn.insert(
                'motivational_messages',
                messageMap,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            
            importedCount++;
          } catch (e) {
            errors.add('Failed to import habit: ${habitMap['name']} - $e');
          }
        }
        
        // Close the imported database
        await importedDb.close();
        
        return ImportResult(
          habits: [], // We don't return the habits here as they're already in the database
          errors: errors,
          totalProcessed: importedCount + errors.length,
        );
      });
      
      return ImportResult(
        habits: [],
        errors: [],
        totalProcessed: 0,
      );
    } catch (e) {
      return ImportResult(
        habits: [],
        errors: ['Failed to import database: $e'],
        totalProcessed: 0,
      );
    }
  }
  
  // Generate backup
  static Future<void> createBackup(List<Habit> habits) async {
    try {
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filename = 'flux_backup_$timestamp.json';
      final jsonData = await exportToJson(habits);
      
      await shareData(jsonData, filename, 'application/json');
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }
  
  // Generate database backup
  static Future<void> createDatabaseBackup() async {
    try {
      await shareDatabaseFile();
    } catch (e) {
      throw Exception('Failed to create database backup: $e');
    }
  }
  
  // Generate habit summary report
  static Future<String> generateSummaryReport(List<Habit> habits, {DateTime? startDate, DateTime? endDate}) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(Duration(days: 30));
    final end = endDate ?? now;
    
    final dateFormatter = DateFormat('MMM d, yyyy');
    final report = StringBuffer();
    
    report.writeln('FLUX HABIT TRACKER SUMMARY REPORT');
    report.writeln('=' * 50);
    report.writeln('Generated: ${dateFormatter.format(now)}');
    report.writeln('Period: ${dateFormatter.format(start)} - ${dateFormatter.format(end)}');
    report.writeln();
    
    // Overall statistics
    final totalHabits = habits.length;
    final activeHabits = habits.where((h) => !h.isArchived).length;
    final totalEntries = habits.fold(0, (sum, h) => sum + h.entries.length);
    final avgSuccessRate = habits.isEmpty ? 0.0 : habits.fold(0.0, (sum, h) => sum + h.successRate) / habits.length;
    
    report.writeln('OVERVIEW');
    report.writeln('-' * 20);
    report.writeln('Total Habits: $totalHabits');
    report.writeln('Active Habits: $activeHabits');
    report.writeln('Total Entries: $totalEntries');
    report.writeln('Average Success Rate: ${avgSuccessRate.toStringAsFixed(1)}%');
    report.writeln();
    
    // Top performers
    if (habits.isNotEmpty) {
      final sortedBySuccess = [...habits]..sort((a, b) => b.successRate.compareTo(a.successRate));
      report.writeln('TOP PERFORMERS');
      report.writeln('-' * 20);
      for (int i = 0; i < sortedBySuccess.length && i < 5; i++) {
        final habit = sortedBySuccess[i];
        report.writeln('${i + 1}. ${habit.formattedName} - ${habit.successRate.toStringAsFixed(1)}%');
      }
      report.writeln();
      
      // Longest streaks
      final sortedByStreak = [...habits]..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
      report.writeln('LONGEST CURRENT STREAKS');
      report.writeln('-' * 20);
      for (int i = 0; i < sortedByStreak.length && i < 5; i++) {
        final habit = sortedByStreak[i];
        if (habit.currentStreak > 0) {
          report.writeln('${i + 1}. ${habit.formattedName} - ${habit.currentStreak} days');
        }
      }
      report.writeln();
    }
    
    // Habit details
    report.writeln('HABIT DETAILS');
    report.writeln('-' * 20);
    for (var habit in habits) {
      report.writeln();
      report.writeln(habit.formattedName);
      report.writeln('  Type: ${habit.type.toString().split('.').last}');
      if (habit.category != null) report.writeln('  Category: ${habit.category}');
      report.writeln('  Frequency: ${habit.frequency.toString().split('.').last}');
      if (habit.targetValue != null) report.writeln('  Target: ${habit.targetValue} ${habit.getUnitDisplayName()}');
      report.writeln('  Success Rate: ${habit.successRate.toStringAsFixed(1)}%');
      report.writeln('  Current Streak: ${habit.currentStreak} days');
      report.writeln('  Best Streak: ${habit.bestStreak} days');
      report.writeln('  Total Entries: ${habit.entries.length}');
      if (habit.notes != null && habit.notes!.isNotEmpty) {
        report.writeln('  Notes: ${habit.notes}');
      }
      
      // Recent entries (last 5)
      final recentEntries = [...habit.entries]..sort((a, b) => b.date.compareTo(a.date));
      if (recentEntries.isNotEmpty) {
        report.writeln('  Recent Entries:');
        for (int i = 0; i < recentEntries.length && i < 5; i++) {
          final entry = recentEntries[i];
          final status = entry.isSkipped ? 'Skipped' : habit.isPositiveDay(entry) ? 'Success' : 'Failed';
          final dateStr = DateFormat('MMM d').format(entry.date);
          String entryDetails = '    $dateStr - $status';
          
          if (entry.value != null) {
            entryDetails += ' (${entry.value} ${entry.unit ?? habit.getUnitDisplayName()})';
          } else if (entry.count > 0) {
            entryDetails += ' (${entry.count})';
          }
          
          report.writeln(entryDetails);
        }
      }
    }
    
    report.writeln();
    report.writeln('=' * 50);
    report.writeln('End of Report');
    
    return report.toString();
  }
  
  // Merge imported habits with existing ones
  static Future<MergeResult> mergeHabits(List<Habit> existingHabits, List<Habit> importedHabits, MergeStrategy strategy) async {
    List<Habit> mergedHabits = [...existingHabits];
    List<String> conflicts = [];
    List<String> added = [];
    List<String> updated = [];
    
    for (var importedHabit in importedHabits) {
      final existingIndex = mergedHabits.indexWhere((h) => h.name.toLowerCase() == importedHabit.name.toLowerCase());
      
      if (existingIndex == -1) {
        // New habit
        mergedHabits.add(importedHabit);
        added.add(importedHabit.name);
      } else {
        // Conflict detected
        final existingHabit = mergedHabits[existingIndex];
        conflicts.add('${importedHabit.name}: Habit already exists');
        
        switch (strategy) {
          case MergeStrategy.Replace:
            mergedHabits[existingIndex] = importedHabit;
            updated.add(importedHabit.name);
            break;
          case MergeStrategy.MergeEntries:
            // Merge entries, avoiding duplicates
            final existingDates = existingHabit.entries.map((e) => e.date.toIso8601String()).toSet();
            final newEntries = importedHabit.entries.where((e) => !existingDates.contains(e.date.toIso8601String())).toList();
            existingHabit.entries.addAll(newEntries);
            updated.add(importedHabit.name);
            break;
          case MergeStrategy.Skip:
            // Do nothing, keep existing
            break;
          case MergeStrategy.Rename:
            // Add with new name
            importedHabit.name = '${importedHabit.name} (Imported)';
            mergedHabits.add(importedHabit);
            added.add(importedHabit.name);
            break;
        }
      }
    }
    
    return MergeResult(
      habits: mergedHabits,
      conflicts: conflicts,
      added: added,
      updated: updated,
    );
  }
  
  // Validate data integrity
  static DataValidationResult validateData(List<Habit> habits) {
    List<String> warnings = [];
    List<String> errors = [];
    
    for (var habit in habits) {
      // Check for empty habit names
      if (habit.name.trim().isEmpty) {
        errors.add('Habit has empty name');
      }
      
      // Check for invalid entries
      for (var entry in habit.entries) {
        if (entry.dayNumber <= 0) {
          warnings.add('${habit.name}: Entry has invalid day number (${entry.dayNumber})');
        }
        
        if (entry.date.isAfter(DateTime.now().add(Duration(days: 1)))) {
          warnings.add('${habit.name}: Entry date is in the future (${entry.date})');
        }
        
        if (entry.value != null && entry.value! < 0) {
          warnings.add('${habit.name}: Entry has negative value (${entry.value})');
        }
      }
      
      // Check for duplicate entries on same day
      final entryDates = habit.entries.map((e) => '${e.date.year}-${e.date.month}-${e.date.day}').toList();
      final uniqueDates = entryDates.toSet();
      if (entryDates.length != uniqueDates.length) {
        warnings.add('${habit.name}: Has duplicate entries on the same day');
      }
    }
    
    return DataValidationResult(
      warnings: warnings,
      errors: errors,
      isValid: errors.isEmpty,
    );
  }
}

// Data classes
class ImportResult {
  final List<Habit> habits;
  final List<String> errors;
  final int totalProcessed;
  
  ImportResult({
    required this.habits,
    required this.errors,
    required this.totalProcessed,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasHabits => habits.isNotEmpty;
}

class MergeResult {
  final List<Habit> habits;
  final List<String> conflicts;
  final List<String> added;
  final List<String> updated;
  
  MergeResult({required this.habits, required this.conflicts, required this.added, required this.updated});
}

class DataValidationResult {
  final List<String> warnings;
  final List<String> errors;
  final bool isValid;
  
  DataValidationResult({required this.warnings, required this.errors, required this.isValid});
  
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

enum MergeStrategy {
  Replace,      // Replace existing habit with imported one
  MergeEntries, // Merge entries from both habits
  Skip,         // Keep existing, ignore imported
  Rename,       // Add imported with different name
} 