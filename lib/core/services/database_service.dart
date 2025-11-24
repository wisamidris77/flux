import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  static Database? _database;
  
  DatabaseService._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flux_habits.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      // Enable foreign key support
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // Create habits table
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        displayMode INTEGER NOT NULL,
        icon INTEGER,
        color INTEGER,
        isArchived INTEGER NOT NULL,
        notes TEXT,
        reminderHour INTEGER,
        reminderMinute INTEGER,
        hasReminder INTEGER NOT NULL,
        category TEXT,
        frequency INTEGER NOT NULL,
        targetFrequency INTEGER,
        targetValue REAL,
        unit INTEGER NOT NULL,
        customUnit TEXT,
        pauseStartDate TEXT,
        pauseEndDate TEXT,
        isPaused INTEGER NOT NULL,
        totalPoints INTEGER NOT NULL,
        level INTEGER NOT NULL,
        experiencePoints REAL NOT NULL,
        locationReminder TEXT,
        reminderLatitude REAL,
        reminderLongitude REAL,
        reminderRadius REAL,
        difficultyMultiplier REAL NOT NULL,
        customSuccessMessage TEXT,
        customFailureMessage TEXT
      )
    ''');
    
    // Create entries table
    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        dayNumber INTEGER NOT NULL,
        count INTEGER NOT NULL,
        value REAL,
        unit TEXT,
        notes TEXT,
        isSkipped INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Create custom_days table for the many-to-many relationship
    await db.execute('''
      CREATE TABLE custom_days(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        dayIndex INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Create unlocked_achievements table
    await db.execute('''
      CREATE TABLE unlocked_achievements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        achievement TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Create unlocked_themes table
    await db.execute('''
      CREATE TABLE unlocked_themes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        theme TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Create unlocked_icons table
    await db.execute('''
      CREATE TABLE unlocked_icons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        iconCode INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    // Create motivational_messages table
    await db.execute('''
      CREATE TABLE motivational_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        message TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }
  
  // HABIT OPERATIONS
  
  Future<List<Habit>> loadAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> habitMaps = await db.query('habits');
    
    List<Habit> habits = [];
    for (var habitMap in habitMaps) {
      final habit = await _loadHabitWithRelations(habitMap);
      habits.add(habit);
    }
    
    return habits;
  }
  
  Future<Habit> _loadHabitWithRelations(Map<String, dynamic> habitMap) async {
    final db = await database;
    final String habitId = habitMap['id'];
    
    // Load entries
    final List<Map<String, dynamic>> entryMaps = await db.query(
      'entries',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    
    List<HabitEntry> entries = entryMaps.map((entryMap) {
      return HabitEntry(
        date: DateTime.parse(entryMap['date']),
        count: entryMap['count'],
        dayNumber: entryMap['dayNumber'],
        value: entryMap['value'],
        unit: entryMap['unit'],
        notes: entryMap['notes'],
        isSkipped: entryMap['isSkipped'] == 1,
      );
    }).toList();
    
    // Load custom days
    final List<Map<String, dynamic>> dayMaps = await db.query(
      'custom_days',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    List<int> customDays = dayMaps.map((dayMap) => dayMap['dayIndex'] as int).toList();
    
    // Load unlocked achievements
    final List<Map<String, dynamic>> achievementMaps = await db.query(
      'unlocked_achievements',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    List<String> unlockedAchievements = achievementMaps.map((map) => map['achievement'] as String).toList();
    
    // Load unlocked themes
    final List<Map<String, dynamic>> themeMaps = await db.query(
      'unlocked_themes',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    List<String> unlockedThemes = themeMaps.map((map) => map['theme'] as String).toList();
    if (unlockedThemes.isEmpty) {
      unlockedThemes = ['default'];
    }
    
    // Load unlocked icons
    final List<Map<String, dynamic>> iconMaps = await db.query(
      'unlocked_icons',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    List<IconData> unlockedIcons = iconMaps.map((map) {
      return IconData(map['iconCode'], fontFamily: 'MaterialIcons');
    }).toList();
    
    // Load motivational messages
    final List<Map<String, dynamic>> messageMaps = await db.query(
      'motivational_messages',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    List<String> motivationalMessages = messageMaps.map((map) => map['message'] as String).toList();
    if (motivationalMessages.isEmpty) {
      motivationalMessages = [
        "You've got this! 💪",
        "Every day is a new opportunity! ✨",
        "Small steps lead to big changes! 🚀",
        "Consistency is key! 🔑",
        "Believe in yourself! 🌟"
      ];
    }
    
    // Create the habit object
    return Habit(
      id: habitMap['id'],
      name: habitMap['name'],
      type: HabitType.values[habitMap['type']],
      displayMode: ReportDisplay.values[habitMap['displayMode']],
      icon: habitMap['icon'] != null ? IconData(habitMap['icon'], fontFamily: 'MaterialIcons') : null,
      color: habitMap['color'] != null ? Color(habitMap['color']) : null,
      isArchived: habitMap['isArchived'] == 1,
      notes: habitMap['notes'],
      reminderHour: habitMap['reminderHour'],
      reminderMinute: habitMap['reminderMinute'],
      hasReminder: habitMap['hasReminder'] == 1,
      category: habitMap['category'],
      frequency: HabitFrequency.values[habitMap['frequency']],
      customDays: customDays,
      targetFrequency: habitMap['targetFrequency'],
      targetValue: habitMap['targetValue'],
      unit: HabitUnit.values[habitMap['unit']],
      customUnit: habitMap['customUnit'],
      pauseStartDate: habitMap['pauseStartDate'] != null ? DateTime.parse(habitMap['pauseStartDate']) : null,
      pauseEndDate: habitMap['pauseEndDate'] != null ? DateTime.parse(habitMap['pauseEndDate']) : null,
      isPaused: habitMap['isPaused'] == 1,
      entries: entries,
      totalPoints: habitMap['totalPoints'],
      level: habitMap['level'],
      experiencePoints: habitMap['experiencePoints'],
      unlockedAchievements: unlockedAchievements,
      unlockedThemes: unlockedThemes,
      unlockedIcons: unlockedIcons,
      locationReminder: habitMap['locationReminder'],
      reminderLatitude: habitMap['reminderLatitude'],
      reminderLongitude: habitMap['reminderLongitude'],
      reminderRadius: habitMap['reminderRadius'],
      difficultyMultiplier: habitMap['difficultyMultiplier'],
      motivationalMessages: motivationalMessages,
      customSuccessMessage: habitMap['customSuccessMessage'],
      customFailureMessage: habitMap['customFailureMessage'],
    );
  }
  
  Future<void> saveHabit(Habit habit) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Save the habit
      await txn.insert(
        'habits',
        {
          'id': habit.id,
          'name': habit.name,
          'type': habit.type.index,
          'displayMode': habit.displayMode.index,
          'icon': habit.icon?.codePoint,
          'color': habit.color?.value,
          'isArchived': habit.isArchived ? 1 : 0,
          'notes': habit.notes,
          'reminderHour': habit.reminderHour,
          'reminderMinute': habit.reminderMinute,
          'hasReminder': habit.hasReminder ? 1 : 0,
          'category': habit.category,
          'frequency': habit.frequency.index,
          'targetFrequency': habit.targetFrequency,
          'targetValue': habit.targetValue,
          'unit': habit.unit.index,
          'customUnit': habit.customUnit,
          'pauseStartDate': habit.pauseStartDate?.toIso8601String(),
          'pauseEndDate': habit.pauseEndDate?.toIso8601String(),
          'isPaused': habit.isPaused ? 1 : 0,
          'totalPoints': habit.totalPoints,
          'level': habit.level,
          'experiencePoints': habit.experiencePoints,
          'locationReminder': habit.locationReminder,
          'reminderLatitude': habit.reminderLatitude,
          'reminderLongitude': habit.reminderLongitude,
          'reminderRadius': habit.reminderRadius,
          'difficultyMultiplier': habit.difficultyMultiplier,
          'customSuccessMessage': habit.customSuccessMessage,
          'customFailureMessage': habit.customFailureMessage,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Save entries
      for (var entry in habit.entries) {
        await txn.insert(
          'entries',
          {
            'habitId': habit.id,
            'date': entry.date.toIso8601String(),
            'dayNumber': entry.dayNumber,
            'count': entry.count,
            'value': entry.value,
            'unit': entry.unit,
            'notes': entry.notes,
            'isSkipped': entry.isSkipped ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Delete and re-insert custom days
      await txn.delete(
        'custom_days',
        where: 'habitId = ?',
        whereArgs: [habit.id],
      );
      
      for (var day in habit.customDays) {
        await txn.insert(
          'custom_days',
          {
            'habitId': habit.id,
            'dayIndex': day,
          },
        );
      }
      
      // Delete and re-insert unlocked achievements
      await txn.delete(
        'unlocked_achievements',
        where: 'habitId = ?',
        whereArgs: [habit.id],
      );
      
      for (var achievement in habit.unlockedAchievements) {
        await txn.insert(
          'unlocked_achievements',
          {
            'habitId': habit.id,
            'achievement': achievement,
          },
        );
      }
      
      // Delete and re-insert unlocked themes
      await txn.delete(
        'unlocked_themes',
        where: 'habitId = ?',
        whereArgs: [habit.id],
      );
      
      for (var theme in habit.unlockedThemes) {
        await txn.insert(
          'unlocked_themes',
          {
            'habitId': habit.id,
            'theme': theme,
          },
        );
      }
      
      // Delete and re-insert unlocked icons
      await txn.delete(
        'unlocked_icons',
        where: 'habitId = ?',
        whereArgs: [habit.id],
      );
      
      for (var icon in habit.unlockedIcons) {
        await txn.insert(
          'unlocked_icons',
          {
            'habitId': habit.id,
            'iconCode': icon.codePoint,
          },
        );
      }
      
      // Delete and re-insert motivational messages
      await txn.delete(
        'motivational_messages',
        where: 'habitId = ?',
        whereArgs: [habit.id],
      );
      
      for (var message in habit.motivationalMessages) {
        await txn.insert(
          'motivational_messages',
          {
            'habitId': habit.id,
            'message': message,
          },
        );
      }
    });
  }
  
  Future<void> deleteHabit(Habit habit) async {
    final db = await database;
    await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }
  
  Future<void> updateEntry(Habit habit, HabitEntry oldEntry, HabitEntry newEntry) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Find the entry
      final List<Map<String, dynamic>> entries = await txn.query(
        'entries',
        where: 'habitId = ? AND dayNumber = ?',
        whereArgs: [habit.id, oldEntry.dayNumber],
      );
      
      if (entries.isNotEmpty) {
        // Update the entry
        await txn.update(
          'entries',
          {
            'date': newEntry.date.toIso8601String(),
            'dayNumber': newEntry.dayNumber,
            'count': newEntry.count,
            'value': newEntry.value,
            'unit': newEntry.unit,
            'notes': newEntry.notes,
            'isSkipped': newEntry.isSkipped ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [entries.first['id']],
        );
        
        // Update the habit object
        final index = habit.entries.indexWhere((e) => e.dayNumber == oldEntry.dayNumber);
        if (index != -1) {
          habit.entries[index] = newEntry;
        }
      }
    });
  }
  
  Future<void> deleteEntry(Habit habit, HabitEntry entry) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(
        'entries',
        where: 'habitId = ? AND dayNumber = ?',
        whereArgs: [habit.id, entry.dayNumber],
      );
      
      // Update the habit object
      habit.entries.removeWhere((e) => e.dayNumber == entry.dayNumber);
    });
  }
  
  // Method to migrate data from JSON to SQLite
  Future<void> migrateFromJson(List<Habit> habits) async {
    for (var habit in habits) {
      await saveHabit(habit);
    }
  }
} 