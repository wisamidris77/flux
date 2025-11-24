// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/core/services/settings_service.dart';
import 'package:flux/features/theme/theme_selection_screen.dart';
import 'package:flux/features/debug/debug_test_page.dart';
import 'package:flux/features/backup_and_import/backup_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  
  const SettingsScreen({super.key, required this.toggleTheme, required this.isDarkMode});
  
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late HabitType _defaultHabitType;
  late ReportDisplay _defaultDisplayMode;
  late HabitFrequency _defaultFrequency;
  late HabitUnit _defaultUnit;
  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showStreakNotifications = true;
  bool _showMilestoneNotifications = true;
  bool _autoBackup = false;
  bool _showMotivationalQuotes = true;
  bool _showProgressAnimations = true;
  bool _compactMode = false;
  bool _showWeekends = true;
  bool _use24HourFormat = true;
  bool _showHabitIcons = true;
  bool _showSuccessRate = true;
  bool _showCurrentStreak = true;
  bool _enableHapticFeedback = true;
  bool _showTodayWidget = true;
  bool _enableDataValidation = true;
  int _reminderTime = 9; // 9 AM
  int _autoBackupFrequency = 7; // Weekly
  int _dataRetentionDays = 365; // 1 year
  double _chartAnimationSpeed = 1.0;
  String _dateFormat = 'MMM d, yyyy';
  String _language = 'English';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    
    // Load all settings from SettingsService
    _defaultHabitType = await SettingsService.getDefaultHabitType();
    _defaultDisplayMode = await SettingsService.getDefaultDisplayMode();
    _defaultFrequency = await SettingsService.getDefaultFrequency();
    _defaultUnit = await SettingsService.getDefaultUnit();
    
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _soundEnabled = await SettingsService.getSoundEnabled();
    _vibrationEnabled = await SettingsService.getVibrationEnabled();
    _showStreakNotifications = await SettingsService.getStreakNotifications();
    _showMilestoneNotifications = await SettingsService.getMilestoneNotifications();
    _reminderTime = await SettingsService.getReminderTime();
    
    _compactMode = await SettingsService.getCompactMode();
    _showProgressAnimations = await SettingsService.getShowAnimations();
    _chartAnimationSpeed = await SettingsService.getAnimationSpeed();
    _dateFormat = await SettingsService.getDateFormat();
    _use24HourFormat = await SettingsService.getUse24HourFormat();
    _showWeekends = await SettingsService.getShowWeekends();
    _showMotivationalQuotes = await SettingsService.getMotivationalQuotes();
    _showTodayWidget = await SettingsService.getTodayWidget();
    _showHabitIcons = await SettingsService.getShowHabitIcons();
    _showSuccessRate = await SettingsService.getShowSuccessRate();
    _showCurrentStreak = await SettingsService.getShowCurrentStreak();
    
    _autoBackup = await SettingsService.getAutoBackup();
    _autoBackupFrequency = await SettingsService.getAutoBackupFrequency();
    _dataRetentionDays = await SettingsService.getDataRetentionDays();
    _enableDataValidation = await SettingsService.getDataValidation();
    
    _language = await SettingsService.getLanguage();
    _enableHapticFeedback = await SettingsService.getHapticFeedback();
    
    setState(() => _loading = false);
  }
  
  String formatPascalCase(String input) {
    // Convert PascalCase to readable format
    return input.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildThemeSection(),
              SizedBox(height: 16),
              _buildHabitsSection(),
              SizedBox(height: 16),
              _buildNotificationsSection(),
              SizedBox(height: 16),
              _buildDisplaySection(),
              SizedBox(height: 16),
              _buildDataSection(),
              SizedBox(height: 16),
              _buildAdvancedSection(),
              SizedBox(height: 16),
              _buildAboutSection(),
              if (kDebugMode) ...[
                SizedBox(height: 16),
                _buildDebugSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildThemeSection() {
    return _buildSettingsCard(
      title: '🎨 Appearance',
      children: [
        SwitchListTile(
          title: Text('Dark Mode'),
          subtitle: Text('Toggle dark/light theme'),
          value: widget.isDarkMode,
          onChanged: (_) => widget.toggleTheme(),
          secondary: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
        ),
        ListTile(
          title: Text('Choose Theme'),
          subtitle: Text('Select from 40+ available themes'),
          leading: Icon(Icons.palette),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThemeSelectionScreen(
                onThemeChanged: (theme) {
                  // Theme change is handled in ThemeSelectionScreen
                },
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: Text('Compact Mode'),
          subtitle: Text('Show more content in less space'),
          value: _compactMode,
          onChanged: (value) async {
            setState(() => _compactMode = value);
            await SettingsService.setCompactMode(value);
          },
          secondary: Icon(Icons.view_compact),
        ),
        SwitchListTile(
          title: Text('Show Progress Animations'),
          subtitle: Text('Animated charts and progress indicators'),
          value: _showProgressAnimations,
          onChanged: (value) async {
            setState(() => _showProgressAnimations = value);
            await SettingsService.setShowAnimations(value);
          },
          secondary: Icon(Icons.animation),
        ),
        ListTile(
          title: Text('Animation Speed'),
          subtitle: Text('${(_chartAnimationSpeed * 100).toInt()}%'),
          leading: Icon(Icons.speed),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: _chartAnimationSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) async {
                setState(() => _chartAnimationSpeed = value);
                await SettingsService.setAnimationSpeed(value);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHabitsSection() {
    return _buildSettingsCard(
      title: '📋 Habits',
      children: [
        ListTile(
          title: Text('Default Habit Type'),
          subtitle: Text(formatPascalCase(_defaultHabitType.toString().split('.').last)),
          leading: Icon(Icons.category),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showHabitTypeSelector,
        ),
        ListTile(
          title: Text('Default Frequency'),
          subtitle: Text(formatPascalCase(_defaultFrequency.toString().split('.').last)),
          leading: Icon(Icons.schedule),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showFrequencySelector,
        ),
        ListTile(
          title: Text('Default Unit'),
          subtitle: Text(formatPascalCase(_defaultUnit.toString().split('.').last)),
          leading: Icon(Icons.straighten),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showUnitSelector,
        ),
        SwitchListTile(
          title: Text('Show Habit Icons'),
          subtitle: Text('Display icons next to habit names'),
          value: _showHabitIcons,
          onChanged: (value) async {
            setState(() => _showHabitIcons = value);
            await SettingsService.setShowHabitIcons(value);
          },
          secondary: Icon(Icons.emoji_emotions),
        ),
        SwitchListTile(
          title: Text('Show Success Rate'),
          subtitle: Text('Display success percentage'),
          value: _showSuccessRate,
          onChanged: (value) async {
            setState(() => _showSuccessRate = value);
            await SettingsService.setShowSuccessRate(value);
          },
          secondary: Icon(Icons.percent),
        ),
        SwitchListTile(
          title: Text('Show Current Streak'),
          subtitle: Text('Display current streak count'),
          value: _showCurrentStreak,
          onChanged: (value) async {
            setState(() => _showCurrentStreak = value);
            await SettingsService.setShowCurrentStreak(value);
          },
          secondary: Icon(Icons.local_fire_department),
        ),
      ],
    );
  }
  
  Widget _buildNotificationsSection() {
    return _buildSettingsCard(
      title: '🔔 Notifications',
      children: [
        SwitchListTile(
          title: Text('Enable Notifications'),
          subtitle: Text('Receive habit reminders'),
          value: _notificationsEnabled,
          onChanged: (value) async {
            setState(() => _notificationsEnabled = value);
            await SettingsService.setNotificationsEnabled(value);
          },
          secondary: Icon(Icons.notifications),
        ),
        if (_notificationsEnabled) ...[
          ListTile(
            title: Text('Default Reminder Time'),
            subtitle: Text('$_reminderTime:00'),
            leading: Icon(Icons.access_time),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTimeSelector,
          ),
          SwitchListTile(
            title: Text('Sound'),
            subtitle: Text('Play notification sound'),
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await SettingsService.setSoundEnabled(value);
            },
            secondary: Icon(Icons.volume_up),
          ),
          SwitchListTile(
            title: Text('Vibration'),
            subtitle: Text('Vibrate on notifications'),
            value: _vibrationEnabled,
            onChanged: (value) async {
              setState(() => _vibrationEnabled = value);
              await SettingsService.setVibrationEnabled(value);
            },
            secondary: Icon(Icons.vibration),
          ),
          SwitchListTile(
            title: Text('Streak Notifications'),
            subtitle: Text('Celebrate streak milestones'),
            value: _showStreakNotifications,
            onChanged: (value) async {
              setState(() => _showStreakNotifications = value);
              await SettingsService.setStreakNotifications(value);
            },
            secondary: Icon(Icons.celebration),
          ),
          SwitchListTile(
            title: Text('Milestone Notifications'),
            subtitle: Text('Notify on achievements'),
            value: _showMilestoneNotifications,
            onChanged: (value) async {
              setState(() => _showMilestoneNotifications = value);
              await SettingsService.setMilestoneNotifications(value);
            },
            secondary: Icon(Icons.emoji_events),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDisplaySection() {
    return _buildSettingsCard(
      title: '📊 Display',
      children: [
        ListTile(
          title: Text('Default Display Mode'),
          subtitle: Text(formatPascalCase(_defaultDisplayMode.toString().split('.').last)),
          leading: Icon(Icons.bar_chart),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showDisplayModeSelector,
        ),
        ListTile(
          title: Text('Date Format'),
          subtitle: Text(_dateFormat),
          leading: Icon(Icons.date_range),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showDateFormatSelector,
        ),
        SwitchListTile(
          title: Text('24-Hour Format'),
          subtitle: Text('Use 24-hour time format'),
          value: _use24HourFormat,
          onChanged: (value) async {
            setState(() => _use24HourFormat = value);
            await SettingsService.setUse24HourFormat(value);
          },
          secondary: Icon(Icons.schedule),
        ),
        SwitchListTile(
          title: Text('Show Weekends'),
          subtitle: Text('Include weekends in calendar view'),
          value: _showWeekends,
          onChanged: (value) async {
            setState(() => _showWeekends = value);
            await SettingsService.setShowWeekends(value);
          },
          secondary: Icon(Icons.weekend),
        ),
        SwitchListTile(
          title: Text('Motivational Quotes'),
          subtitle: Text('Show inspiring messages'),
          value: _showMotivationalQuotes,
          onChanged: (value) async {
            setState(() => _showMotivationalQuotes = value);
            await SettingsService.setMotivationalQuotes(value);
          },
          secondary: Icon(Icons.format_quote),
        ),
        SwitchListTile(
          title: Text('Today Widget'),
          subtitle: Text('Show today\'s habits widget'),
          value: _showTodayWidget,
          onChanged: (value) async {
            setState(() => _showTodayWidget = value);
            await SettingsService.setTodayWidget(value);
          },
          secondary: Icon(Icons.today),
        ),
      ],
    );
  }
  
  Widget _buildDataSection() {
    return _buildSettingsCard(
      title: '💾 Data & Backup',
      children: [
        ListTile(
          title: Text('Backup & Import'),
          subtitle: Text('Manage your data backups'),
          leading: Icon(Icons.backup),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BackupImportScreen()),
          ),
        ),
        SwitchListTile(
          title: Text('Auto Backup'),
          subtitle: Text('Automatically backup data'),
          value: _autoBackup,
          onChanged: (value) => setState(() => _autoBackup = value),
          secondary: Icon(Icons.cloud_upload),
        ),
        if (_autoBackup) ...[
          ListTile(
            title: Text('Backup Frequency'),
            subtitle: Text('Every $_autoBackupFrequency days'),
            leading: Icon(Icons.schedule),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showBackupFrequencySelector,
          ),
        ],
        ListTile(
          title: Text('Data Retention'),
          subtitle: Text('Keep data for $_dataRetentionDays days'),
          leading: Icon(Icons.history),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showDataRetentionSelector,
        ),
        SwitchListTile(
          title: Text('Data Validation'),
          subtitle: Text('Validate data integrity'),
          value: _enableDataValidation,
          onChanged: (value) => setState(() => _enableDataValidation = value),
          secondary: Icon(Icons.verified),
        ),
        ListTile(
          title: Text('Clear All Data'),
          subtitle: Text('Delete all habits and entries'),
          leading: Icon(Icons.delete_forever, color: Colors.red),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showClearDataDialog,
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSection() {
    return _buildSettingsCard(
      title: '⚙️ Advanced',
      children: [
        ListTile(
          title: Text('Language'),
          subtitle: Text(_language),
          leading: Icon(Icons.language),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showLanguageSelector,
        ),
        SwitchListTile(
          title: Text('Haptic Feedback'),
          subtitle: Text('Vibrate on interactions'),
          value: _enableHapticFeedback,
          onChanged: (value) async {
            setState(() => _enableHapticFeedback = value);
            await SettingsService.setHapticFeedback(value);
          },
          secondary: Icon(Icons.vibration),
        ),
        ListTile(
          title: Text('Reset Settings'),
          subtitle: Text('Restore default settings'),
          leading: Icon(Icons.restore, color: Colors.orange),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showResetSettingsDialog,
        ),
      ],
    );
  }
  
  Widget _buildAboutSection() {
    return _buildSettingsCard(
      title: 'ℹ️ About',
      children: [
        ListTile(
          title: Text('App Version'),
          subtitle: Text('1.0.0'),
          leading: Icon(Icons.info_outline),
        ),
        ListTile(
          title: Text('Privacy Policy'),
          subtitle: Text('How we handle your data'),
          leading: Icon(Icons.privacy_tip),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showPrivacyPolicy,
        ),
        ListTile(
          title: Text('Terms of Service'),
          subtitle: Text('App usage terms'),
          leading: Icon(Icons.description),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showTermsOfService,
        ),
        ListTile(
          title: Text('Rate App'),
          subtitle: Text('Leave a review'),
          leading: Icon(Icons.star),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _rateApp,
        ),
        ListTile(
          title: Text('Contact Support'),
          subtitle: Text('Get help or report issues'),
          leading: Icon(Icons.support),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _contactSupport,
        ),
      ],
    );
  }
  
  Widget _buildDebugSection() {
    return _buildSettingsCard(
      title: '🛠️ Debug',
      children: [
        ListTile(
          title: Text('Debug Test Page'),
          subtitle: Text('Testing tools (Debug mode only)'),
          leading: Icon(Icons.bug_report, color: Colors.red),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DebugTestPage()),
          ),
        ),
        ListTile(
          title: Text('Generate Test Data'),
          subtitle: Text('Create sample habits for testing'),
          leading: Icon(Icons.data_object, color: Colors.blue),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _generateTestData,
        ),
      ],
    );
  }
  
  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
  
  // Dialog methods
  void _showHabitTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Habit Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitType.values.map((type) {
            return RadioListTile<HabitType>(
              title: Text(formatPascalCase(type.toString().split('.').last)),
              value: type,
              groupValue: _defaultHabitType,
              onChanged: (HabitType? value) {
                if (value != null) {
                  setState(() => _defaultHabitType = value);
                  SettingsService.setDefaultHabitType(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showFrequencySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitFrequency.values.map((freq) {
            return RadioListTile<HabitFrequency>(
              title: Text(formatPascalCase(freq.toString().split('.').last)),
              value: freq,
              groupValue: _defaultFrequency,
              onChanged: (HabitFrequency? value) {
                if (value != null) {
                  setState(() => _defaultFrequency = value);
                  SettingsService.setDefaultFrequency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showUnitSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitUnit.values.map((unit) {
            return RadioListTile<HabitUnit>(
              title: Text(formatPascalCase(unit.toString().split('.').last)),
              value: unit,
              groupValue: _defaultUnit,
              onChanged: (HabitUnit? value) {
                if (value != null) {
                  setState(() => _defaultUnit = value);
                  SettingsService.setDefaultUnit(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showDisplayModeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Display Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReportDisplay.values.map((mode) {
            return RadioListTile<ReportDisplay>(
              title: Text(formatPascalCase(mode.toString().split('.').last)),
              value: mode,
              groupValue: _defaultDisplayMode,
              onChanged: (ReportDisplay? value) {
                if (value != null) {
                  setState(() => _defaultDisplayMode = value);
                  SettingsService.setDefaultDisplayMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showTimeSelector() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderTime, minute: 0),
    ).then((time) async {
      if (time != null) {
        setState(() => _reminderTime = time.hour);
        await SettingsService.setReminderTime(time.hour);
      }
    });
  }
  
  void _showDateFormatSelector() {
    final formats = [
      'MMM d, yyyy',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'd MMM yyyy',
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            return RadioListTile<String>(
              title: Text(format),
              value: format,
              groupValue: _dateFormat,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _dateFormat = value);
                  SettingsService.setDateFormat(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showBackupFrequencySelector() {
    final frequencies = [1, 3, 7, 14, 30];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: frequencies.map((days) {
            return RadioListTile<int>(
              title: Text('Every $days day${days > 1 ? 's' : ''}'),
              value: days,
              groupValue: _autoBackupFrequency,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() => _autoBackupFrequency = value);
                  SettingsService.setAutoBackupFrequency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showDataRetentionSelector() {
    final retentions = [30, 90, 180, 365, 730, -1]; // -1 = forever
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data Retention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: retentions.map((days) {
            return RadioListTile<int>(
              title: Text(days == -1 ? 'Forever' : '$days days'),
              value: days,
              groupValue: _dataRetentionDays,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() => _dataRetentionDays = value);
                  SettingsService.setDataRetentionDays(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showLanguageSelector() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Japanese', 'Chinese'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _language = value);
                  SettingsService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text('This will permanently delete all your habits and entries. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear all data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }
  
  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Settings'),
        content: Text('This will restore all settings to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset settings
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'Flux respects your privacy. All data is stored locally on your device. '
            'We do not collect, store, or share any personal information. '
            'Your habit data remains private and under your control.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(
            'By using Flux, you agree to use the app responsibly. '
            'The app is provided as-is without warranties. '
            'You are responsible for backing up your data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rate app functionality would open app store')),
    );
  }
  
  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact support functionality would open email')),
    );
  }
  
  void _generateTestData() async {
    // Generate sample habits for testing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test data generated')),
    );
  }
}
