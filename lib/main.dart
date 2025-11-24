// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/features/home/home_screen.dart';
import 'package:flux/core/services/settings_service.dart';
import 'package:flux/core/services/notification_service.dart';
import 'package:flux/core/services/widget_service.dart';
import 'package:flux/core/services/theme_service.dart';
import 'package:flux/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/core/services/keyboard_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_ffi for Windows
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize services
  await NotificationService.initialize();
  await WidgetService.initialize();
  
  // Initialize keyboard service
  KeyboardService().initialize();
  
  // Check if first launch
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;
  
  // Check if database migration has been done
  final dbMigrationDone = prefs.getBool('db_migration_done') ?? false;
  
  // Perform database migration if not done yet
  if (!dbMigrationDone) {
    await migrateToDatabase();
    await prefs.setBool('db_migration_done', true);
  }
  
  // Load theme settings
  final isDarkMode = await SettingsService.isDarkMode();
  final selectedTheme = await ThemeService.getCurrentTheme();
  
  runApp(HabitTrackerApp(
    isDarkMode: isDarkMode,
    selectedTheme: selectedTheme,
    isFirstLaunch: isFirstLaunch,
  ));
}

// Function to migrate data from JSON to SQLite
Future<void> migrateToDatabase() async {
  try {
    print('Starting database migration...');
    await StorageService.migrateFromJsonToDatabase();
    print('Database migration completed successfully!');
  } catch (e) {
    print('Error during database migration: $e');
  }
}

class HabitTrackerApp extends StatefulWidget {
  final bool isDarkMode;
  final String selectedTheme;
  final bool isFirstLaunch;
  
  const HabitTrackerApp({super.key, 
    required this.isDarkMode,
    required this.selectedTheme,
    required this.isFirstLaunch,
  });

  @override
  _HabitTrackerAppState createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late bool _isDarkMode;
  late String _selectedTheme;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _selectedTheme = widget.selectedTheme;
  }
  
  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      SettingsService.setDarkMode(_isDarkMode);
    });
  }

  void changeTheme(String themeName) {
    setState(() {
      _selectedTheme = themeName;
      ThemeService.setCurrentTheme(themeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeService.createTheme(
      themeName: _selectedTheme,
      isDarkMode: false,
    );
    final darkTheme = ThemeService.createTheme(
      themeName: _selectedTheme,
      isDarkMode: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: widget.isFirstLaunch 
          ? Builder(
            builder: (context) {
              return OnboardingScreen(
                  onComplete: (themePreference) {
                    if (themePreference != null) {
                      changeTheme(themePreference);
                    }
                    _completeOnboarding(context);
                  },
                );
            }
          )
          : HomeScreen(
              toggleTheme: toggleTheme,
              isDarkMode: _isDarkMode,
              changeTheme: changeTheme,
            ),
    );
  }

  void _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    
    setState(() {
      // Navigate to main app
    });
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          toggleTheme: toggleTheme,
          isDarkMode: _isDarkMode,
          changeTheme: changeTheme,
        ),
      ),
    );
  }
}

class HabitListItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  
  const HabitListItem({super.key, required this.habit, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDisplaySettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildBasicCard(context);
        }
        
        final settings = snapshot.data!;
        return _buildConfigurableCard(context, settings);
      },
    );
  }
  
  Future<Map<String, dynamic>> _getDisplaySettings() async {
    return {
      'showIcons': await SettingsService.getShowHabitIcons(),
      'showSuccessRate': await SettingsService.getShowSuccessRate(),
      'showCurrentStreak': await SettingsService.getShowCurrentStreak(),
      'compactMode': await SettingsService.getCompactMode(),
    };
  }
  
  Widget _buildBasicCard(BuildContext context) {
    return _buildConfigurableCard(context, {
      'showIcons': true,
      'showSuccessRate': true,
      'showCurrentStreak': true,
      'compactMode': false,
    });
  }
  
  Widget _buildConfigurableCard(BuildContext context, Map<String, dynamic> settings) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400 || settings['compactMode'] == true;
    final showIcons = settings['showIcons'] == true;
    final showSuccessRate = settings['showSuccessRate'] == true;
    final showCurrentStreak = settings['showCurrentStreak'] == true;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 10 : 16),
          child: Column(
            children: [
              Row(
                children: [
                  if (showIcons) ...[
                    Container(
                      padding: EdgeInsets.all(isCompact ? 6 : 12),
                      decoration: BoxDecoration(
                        color: habit.color?.withValues(alpha: 0.1) ?? 
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        habit.icon ?? Icons.star,
                        color: habit.color ?? Theme.of(context).colorScheme.primary,
                        size: isCompact ? 20 : 28,
                      ),
                    ),
                    SizedBox(width: isCompact ? 10 : 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.formattedName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCompact ? 13 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (habit.isDueToday()) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 6 : 8, 
                                  vertical: isCompact ? 2 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Due',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact ? 9 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (habit.category != null) ...[
                          SizedBox(height: 2),
                          Text(
                            habit.category!,
                            style: TextStyle(
                              fontSize: isCompact ? 9 : 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (habit.type == HabitType.FailBased && habit.hasEntries) ...[
                        Text(
                          habit.getTimeSinceLastFailure(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: habit.color ?? Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 13 : 16,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ] else if (showSuccessRate) ...[
                        Text(
                          '${habit.successRate.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: habit.color ?? Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 14 : 20,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                      if (showCurrentStreak) ...[
                        SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up, 
                              size: isCompact ? 10 : 14, 
                              color: Colors.grey
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${habit.currentStreak} day${habit.currentStreak != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: isCompact ? 9 : 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    habit.notes!,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12, 
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (!isCompact) ...[
                SizedBox(height: 8),
                Text(
                  _getHabitStatusText(habit),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _getHabitStatusText(Habit habit) {
    switch (habit.type) {
      case HabitType.FailBased:
        final total = habit.entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble()));
        return 'Failures: ${total.toStringAsFixed(1)} ${habit.getUnitDisplayName()}';
      case HabitType.SuccessBased:
        final total = habit.entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble()));
        return 'Successes: ${total.toStringAsFixed(1)} ${habit.getUnitDisplayName()}';
      case HabitType.DoneBased:
        final total = habit.entries.fold(0, (sum, e) => sum + e.count);
        return 'Completed $total time${total != 1 ? 's' : ''}';
    }
  }
}

class DetailItem {
  final String label;
  final String value;
  
  DetailItem({required this.label, required this.value});
}
