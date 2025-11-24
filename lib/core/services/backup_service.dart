import 'dart:convert';
import 'dart:io';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/core/services/data_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class BackupService {
  static const String _backupFileName = 'flux_backup';
  static const String _dbBackupFileName = 'flux_db_backup';
  
  // Create backup with file save dialog
  static Future<bool> createBackup(List<Habit> habits, {String? customName}) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          throw Exception('Storage permission required to save backup');
        }
      }
      
      // Generate backup data
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filename = customName ?? '${_backupFileName}_$timestamp.json';
      final jsonData = await DataService.exportToJson(habits);
      
      // Show save file dialog
      String? selectedDirectory;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, use downloads directory
        final directory = await getExternalStorageDirectory();
        selectedDirectory = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
      } else {
        // For desktop, show file picker
        selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose backup location',
        );
      }
      
      if (selectedDirectory == null) {
        throw Exception('No location selected for backup');
      }
      
      // Save the backup file
      final file = File('$selectedDirectory/$filename');
      await file.writeAsString(jsonData);
      
      return true;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }
  
  // Create database backup with file save dialog
  static Future<bool> createDatabaseBackup({String? customName}) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          throw Exception('Storage permission required to save backup');
        }
      }
      
      // Generate backup data
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filename = customName ?? '${_dbBackupFileName}_$timestamp.db';
      final dbPath = await DataService.exportToSql();
      
      // Show save file dialog
      String? selectedDirectory;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, use downloads directory
        final directory = await getExternalStorageDirectory();
        selectedDirectory = directory?.path ?? (await getApplicationDocumentsDirectory()).path;
      } else {
        // For desktop, show file picker
        selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose backup location',
        );
      }
      
      if (selectedDirectory == null) {
        throw Exception('No location selected for backup');
      }
      
      // Copy the database file
      final sourceFile = File(dbPath);
      final targetFile = File('$selectedDirectory/$filename');
      await sourceFile.copy(targetFile.path);
      
      return true;
    } catch (e) {
      throw Exception('Failed to create database backup: $e');
    }
  }
  
  // Import backup with file picker dialog
  static Future<ImportBackupResult> importBackup() async {
    try {
      // Pick backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select backup file to import',
      );
      
      if (result == null || result.files.single.path == null) {
        throw Exception('No file selected');
      }
      
      final file = File(result.files.single.path!);
      final jsonData = await file.readAsString();
      
      // Import the data
      final importResult = await DataService.importFromJson(jsonData);
      
      if (importResult.hasErrors && !importResult.hasHabits) {
        throw Exception('Invalid backup file: ${importResult.errors.join(', ')}');
      }
      
      return ImportBackupResult(
        success: true,
        habits: importResult.habits,
        errors: importResult.errors,
        fileName: result.files.single.name,
      );
      
    } catch (e) {
      return ImportBackupResult(
        success: false,
        habits: [],
        errors: [e.toString()],
        fileName: null,
      );
    }
  }
  
  // Import database backup with file picker dialog
  static Future<ImportBackupResult> importDatabaseBackup() async {
    try {
      // Pick backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Select database backup file to import',
      );
      
      if (result == null || result.files.single.path == null) {
        throw Exception('No file selected');
      }
      
      final filePath = result.files.single.path!;
      
      // Import the data
      final importResult = await DataService.importFromDatabase(filePath);
      
      if (importResult.hasErrors) {
        throw Exception('Invalid database backup file: ${importResult.errors.join(', ')}');
      }
      
      return ImportBackupResult(
        success: true,
        habits: importResult.habits,
        errors: importResult.errors,
        fileName: result.files.single.name,
      );
      
    } catch (e) {
      return ImportBackupResult(
        success: false,
        habits: [],
        errors: [e.toString()],
        fileName: null,
      );
    }
  }
  
  // Restore backup by merging with existing habits
  static Future<RestoreResult> restoreBackup(
    List<Habit> currentHabits,
    List<Habit> backupHabits,
    MergeStrategy strategy,
  ) async {
    try {
      final mergeResult = await DataService.mergeHabits(
        currentHabits,
        backupHabits,
        strategy,
      );
      
      // Save merged habits
      for (final habit in mergeResult.habits) {
        await StorageService.save(habit);
      }
      
      return RestoreResult(
        success: true,
        totalHabits: mergeResult.habits.length,
        added: mergeResult.added,
        updated: mergeResult.updated,
        conflicts: mergeResult.conflicts,
      );
      
    } catch (e) {
      return RestoreResult(
        success: false,
        totalHabits: 0,
        added: [],
        updated: [],
        conflicts: [],
        error: e.toString(),
      );
    }
  }
  
  // Validate backup file
  static Future<BackupValidationResult> validateBackup(String filePath) async {
    try {
      final file = File(filePath);
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData);
      
      List<String> issues = [];
      
      // Check required fields
      if (data['version'] == null) {
        issues.add('Missing version information');
      }
      
      if (data['exportDate'] == null) {
        issues.add('Missing export date');
      }
      
      if (data['habits'] == null && data['habit'] == null) {
        issues.add('No habit data found');
      }
      
      // Check habits structure
      final habits = data['habits'] ?? [data['habit']];
      for (int i = 0; i < habits.length; i++) {
        final habit = habits[i];
        if (habit['name'] == null || habit['name'].toString().trim().isEmpty) {
          issues.add('Habit ${i + 1} has no name');
        }
        if (habit['type'] == null) {
          issues.add('Habit ${i + 1} has no type');
        }
      }
      
      return BackupValidationResult(
        isValid: issues.isEmpty,
        issues: issues,
        habitCount: habits.length,
        version: data['version']?.toString(),
        exportDate: data['exportDate']?.toString(),
      );
      
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        issues: ['File is not a valid JSON backup: $e'],
        habitCount: 0,
        version: null,
        exportDate: null,
      );
    }
  }
  
  // Get backup directory
  static Future<String> getBackupDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
  
  // List available backups in default directory
  static Future<List<BackupFileInfo>> listAvailableBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final directory = Directory(backupDir);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      List<BackupFileInfo> backups = [];
      
      for (final file in files) {
        try {
          final validation = await validateBackup(file.path);
          final stats = await file.stat();
          
          backups.add(BackupFileInfo(
            name: file.uri.pathSegments.last,
            path: file.path,
            size: stats.size,
            modified: stats.modified,
            isValid: validation.isValid,
            habitCount: validation.habitCount,
            version: validation.version,
          ));
        } catch (e) {
          // Skip invalid files
        }
      }
      
      // Sort by modification date, newest first
      backups.sort((a, b) => b.modified.compareTo(a.modified));
      
      return backups;
    } catch (e) {
      return [];
    }
  }
}

// Result classes
class ImportBackupResult {
  final bool success;
  final List<Habit> habits;
  final List<String> errors;
  final String? fileName;
  
  ImportBackupResult({
    required this.success,
    required this.habits,
    required this.errors,
    this.fileName,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasHabits => habits.isNotEmpty;
}

class RestoreResult {
  final bool success;
  final int totalHabits;
  final List<String> added;
  final List<String> updated;
  final List<String> conflicts;
  final String? error;
  
  RestoreResult({
    required this.success,
    required this.totalHabits,
    required this.added,
    required this.updated,
    required this.conflicts,
    this.error,
  });
}

class BackupValidationResult {
  final bool isValid;
  final List<String> issues;
  final int habitCount;
  final String? version;
  final String? exportDate;
  
  BackupValidationResult({
    required this.isValid,
    required this.issues,
    required this.habitCount,
    this.version,
    this.exportDate,
  });
}

class BackupFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final bool isValid;
  final int habitCount;
  final String? version;
  
  BackupFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.isValid,
    required this.habitCount,
    this.version,
  });
  
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
} 