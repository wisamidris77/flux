// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/features/habits/add_habit_sheet.dart';
import 'package:flux/main.dart';
import 'package:flux/features/settings/settings_screen.dart';
import 'package:flux/features/analytics/analytics_dashboard.dart';
import 'package:flux/core/services/reports_service.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/features/habits/habit_detail_screen.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flux/features/habits/bulk_edit_screen.dart';
import 'package:flux/core/services/widget_service.dart';
import 'package:flux/features/achievements/achievements_view.dart';
import 'package:flux/features/backup_and_import/backup_import_screen.dart';
import 'package:flux/features/gamification/points_screen.dart';
import 'package:flux/core/services/keyboard_service.dart';
import 'package:flux/core/widgets/keyboard_aware_widget.dart';
import 'package:flux/core/widgets/focusable_button.dart';
import 'package:flux/core/widgets/keyboard_shortcuts_dialog.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final Function(String)? changeTheme;
  
  const HomeScreen({super.key, 
    required this.toggleTheme, 
    required this.isDarkMode,
    this.changeTheme,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Habit> _habits = [];
  List<Habit> _activeHabits = [];
  List<Habit> _archivedHabits = [];
  List<Habit> _filteredHabits = [];
  late TabController _tabController;
  bool _isLoading = true;
  int _totalPositiveDays = 0;
  int _totalNegativeDays = 0;
  double _overallSuccessRate = 0;
  int _totalEntries = 0;
  int _bestCurrentStreak = 0;
  String _bestStreakHabit = '';
  bool _showArchived = false;
  String? _selectedCategory;
  List<String> _categories = [];
  
  // Keyboard navigation
  late ScrollController _habitsScrollController;
  late ScrollController _dashboardScrollController;
  List<FocusNode> _focusableNodes = [];
  final KeyboardService _keyboardService = KeyboardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize scroll controllers
    _habitsScrollController = ScrollController();
    _dashboardScrollController = ScrollController();
    
    // Initialize focus nodes for keyboard navigation
    _initializeFocusNodes();
    
    // Add listener to update scroll controller when tab changes
    _tabController.addListener(_onTabChanged);
    
    _loadHabits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _habitsScrollController.dispose();
    _dashboardScrollController.dispose();
    
    // Dispose focus nodes
    for (var node in _focusableNodes) {
      node.dispose();
    }
    _focusableNodes.clear();
    
    super.dispose();
  }

  void _initializeFocusNodes() {
    // Create focus nodes for all interactive elements
    _focusableNodes = List.generate(20, (index) => FocusNode());
  }

  void _onTabChanged() {
    // Update the keyboard service with the current scroll controller
    if (_tabController.indexIsChanging) {
      final currentController = _tabController.index == 0 
          ? _habitsScrollController 
          : _dashboardScrollController;
      _keyboardService.setScrollController(currentController);
    }
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final all = await StorageService.loadAll();
    
    // Filter active and archived habits
    final active = all.where((h) => !h.isArchived).toList();
    final archived = all.where((h) => h.isArchived).toList();
    
    // Extract categories
    final categories = active
        .where((h) => h.category != null)
        .map((h) => h.category!)
        .toSet()
        .toList()
        ..sort();
    
    // Apply category filter
    final filtered = _selectedCategory == null 
        ? active 
        : active.where((h) => h.category == _selectedCategory).toList();
    
    // Calculate overall metrics (using filtered habits)
    int totalPositive = 0;
    int totalNegative = 0;
    int totalEntries = 0;
    int bestStreak = 0;
    String bestStreakHabit = '';
    
    for (var habit in filtered) {
      totalPositive += habit.positiveCount;
      totalNegative += habit.negativeCount;
      totalEntries += habit.entries.length;
      
      if (habit.currentStreak > bestStreak) {
        bestStreak = habit.currentStreak;
        bestStreakHabit = habit.formattedName;
      }
    }
    
    setState(() {
      _habits = all;
      _activeHabits = active;
      _archivedHabits = archived;
      _filteredHabits = filtered;
      _categories = categories;
      _totalPositiveDays = totalPositive;
      _totalNegativeDays = totalNegative;
      _totalEntries = totalEntries;
      
      int totalDays = totalPositive + totalNegative;
      _overallSuccessRate = totalDays > 0 ? (totalPositive / totalDays) * 100 : 0;
      
      _bestCurrentStreak = bestStreak;
      _bestStreakHabit = bestStreakHabit;
      _isLoading = false;
    });
    
    // Update home widgets
    await WidgetService.updateHomeWidgets();
  }

  void _showAddHabit() {
    // Get existing categories
    final existingCategories = _activeHabits
        .where((h) => h.category != null)
        .map((h) => h.category!)
        .toSet()
        .toList()
        ..sort();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(
        existingCategories: existingCategories,
        onSave: (h) async {
          if (h.name.isEmpty) return;
          await StorageService.save(h);
          Navigator.pop(context);
          _loadHabits();
        }
      ),
    );
  }
  
  void _openSettings() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => SettingsScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ))
    ).then((_) => _loadHabits());
  }
  
  void _toggleArchiveView() {
    setState(() {
      _showArchived = !_showArchived;
    });
  }
  
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All Categories'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadHabits();
                  Navigator.pop(context);
                },
              ),
            ),
            ..._categories.map((category) => ListTile(
              title: Text(category),
              leading: Radio<String?>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadHabits();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDashboard(habits: _filteredHabits),
      ),
    );
  }

  void _openBackupScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupImportScreen(),
      ),
    );
  }

  void _openPointsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointsScreen(),
      ),
    );
  }

  void _showYearInReview() {
    final currentYear = DateTime.now().year;
    final yearReview = ReportsService.generateYearInReview(_filteredHabits, currentYear);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$currentYear Year in Review'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (yearReview.totalHabits == 0) ...[
                Text('No data available for $currentYear'),
                SizedBox(height: 16),
                Text('Start tracking habits to see your year in review!'),
              ] else ...[
                Text('🎯 Total Habits: ${yearReview.totalHabits}'),
                Text('📅 Total Entries: ${yearReview.totalEntries}'),
                Text('📊 Success Rate: ${yearReview.overallSuccessRate.toStringAsFixed(1)}%'),
                Text('🔥 Longest Streak: ${yearReview.longestStreak} days'),
                SizedBox(height: 16),
                if (yearReview.milestones.isNotEmpty) ...[
                  Text('🏆 Key Milestones:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...yearReview.milestones.take(3).map((milestone) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${milestone.title}'),
                  )),
                ],
                if (yearReview.insights.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('💡 Insights:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...yearReview.insights.take(3).map((insight) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${insight.title}: ${insight.description}'),
                  )),
                ],
              ],
            ],
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

  void _openBulkEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkEditScreen(habits: _habits),
      ),
    ).then((_) => _loadHabits());
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementsView(),
      ),
    );
  }

  void _showKeyboardShortcuts() {
    showKeyboardShortcutsDialog(context);
  }

  void _handleClose() {
    // Close any open dialogs or navigate back
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _handleToggleFullscreen() {
    // This would need to be implemented based on the platform
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fullscreen toggle not implemented on this platform')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareWidget(
      scrollController: _tabController.index == 0 ? _habitsScrollController : _dashboardScrollController,
      onPreviousPage: () {
        if (_tabController.index > 0) {
          _tabController.animateTo(_tabController.index - 1);
        }
      },
      onNextPage: () {
        if (_tabController.index < _tabController.length - 1) {
          _tabController.animateTo(_tabController.index + 1);
        }
      },
      onClose: _handleClose,
      onToggleFullscreen: _handleToggleFullscreen,
      onAddHabit: _showAddHabit,
      onOpenSettings: _openSettings,
      onOpenAnalytics: _openAnalytics,
      onToggleArchive: _toggleArchiveView,
      onFilterByCategory: _showCategoryFilter,
      onBulkEdit: _openBulkEdit,
      onBackup: _openBackupScreen,
      onYearReview: _showYearInReview,
      onAchievements: _openAchievements,
      onPoints: _openPointsScreen,
      onShowKeyboardShortcuts: _showKeyboardShortcuts,
      focusableNodes: _focusableNodes,
      child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_showArchived ? 'Archived Habits' : 'Flux', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            if (!_showArchived && _selectedCategory != null)
              Text(
                'Category: $_selectedCategory',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (!_showArchived && _categories.isNotEmpty)
            FocusableIconButton(
              icon: Icon(_selectedCategory != null ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: _showCategoryFilter,
              tooltip: 'Filter by Category (F)',
              focusNode: _focusableNodes.length > 2 ? _focusableNodes[2] : null,
            ),
          if (!_showArchived)
            FocusableIconButton(
              icon: Icon(Icons.analytics),
              onPressed: _openAnalytics,
              tooltip: 'Analytics Dashboard (D)',
              focusNode: _focusableNodes.length > 3 ? _focusableNodes[3] : null,
            ),
          if (!_showArchived && _filteredHabits.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'bulk_edit':
                    _openBulkEdit();
                    break;
                  case 'points':
                    _openPointsScreen();
                    break;
                  case 'backup':
                    _openBackupScreen();
                    break;
                  case 'year_review':
                    _showYearInReview();
                    break;
                  case 'achievements':
                    _openAchievements();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'bulk_edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, size: 18),
                      SizedBox(width: 8),
                      Text('Bulk Edit'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'points',
                  child: Row(
                    children: [
                      Icon(Icons.stars, size: 18),
                      SizedBox(width: 8),
                      Text('Points & Rewards'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'backup',
                  child: Row(
                    children: [
                      Icon(Icons.backup, size: 18),
                      SizedBox(width: 8),
                      Text('Backup & Import'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'year_review',
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text('Year in Review'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'achievements',
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 18),
                      SizedBox(width: 8),
                      Text('Achievements'),
                    ],
                  ),
                ),
              ],
            ),
          FocusableIconButton(
            icon: Icon(_showArchived ? Icons.inventory_2_outlined : Icons.archive),
            onPressed: _toggleArchiveView,
            tooltip: _showArchived ? 'Show Active Habits' : 'Show Archived',
            focusNode: _focusableNodes.length > 4 ? _focusableNodes[4] : null,
          ),
          FocusableIconButton(
            icon: Icon(Icons.keyboard),
            onPressed: _showKeyboardShortcuts,
            tooltip: 'Keyboard Shortcuts (F1)',
            focusNode: _focusableNodes.isNotEmpty ? _focusableNodes[0] : null,
          ),
          FocusableIconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings (S)',
            focusNode: _focusableNodes.length > 1 ? _focusableNodes[1] : null,
          ),
        ],
        bottom: !_showArchived ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Habits'),
            Tab(text: 'Dashboard'),
          ],
        ) : null,
      ),
      floatingActionButton: !_showArchived ? FocusableButton(
        onPressed: _showAddHabit,
        focusNode: _focusableNodes.length > 5 ? _focusableNodes[5] : null,
        child: Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _showArchived 
              ? _buildArchivedList()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _filteredHabits.isEmpty ? _buildEmpty() : _buildHabitsList(_filteredHabits),
                    _buildDashboard(),
                  ],
                ),
      ),
    );
  }

  Widget _buildArchivedList() {
    if (_archivedHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No archived habits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Archived habits will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            TextButton.icon(
              onPressed: _toggleArchiveView,
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Active Habits'),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      controller: _habitsScrollController,
      padding: EdgeInsets.all(16),
      itemCount: _archivedHabits.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (_, i) {
        final habit = _archivedHabits[i];
        return HabitListItem(
          habit: habit,
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))
            );
            _loadHabits();
          },
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_circle_outline, size: 72, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No habits yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          'Start tracking your habits to build better routines',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAddHabit,
          icon: Icon(Icons.add),
          label: Text('Create Habit'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    ),
  );

  Widget _buildHabitsList(List<Habit> habits) {
    return ListView.separated(
      controller: _habitsScrollController,
      padding: EdgeInsets.all(16),
      itemCount: habits.length, // Add 1 for QuickEntryWidget
      separatorBuilder: (context, index) {
        if (index == 0) return SizedBox(height: 16); // Space after quick entry
        return SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        // if (index == 0) {
        //   // Quick entry widget at the top
        //   return QuickEntryWidget(
        //     habits: _habits,
        //     onUpdate: _loadHabits,
        //   );
        // }
        
        final habit = habits[index];
        return HabitListItem(
          habit: habit,
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))
            );
            _loadHabits();
          },
        );
      },
    );
  }
  
  Widget _buildDashboard() {
    if (_habits.isEmpty) {
      return Center(
        child: Text(
          'Add habits to see your statistics',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return SingleChildScrollView(
      controller: _dashboardScrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Overall Progress'),
          SizedBox(height: 12),
          _buildMetricsCards(),
          SizedBox(height: 24),
          
          _buildSectionTitle('Success Rate by Habit'),
          SizedBox(height: 12),
          _buildSuccessRateChart(),
          SizedBox(height: 24),
          
          _buildSectionTitle('Habit Streaks'),
          SizedBox(height: 12),
          _buildStreaksList(),
          SizedBox(height: 24),
          
          _buildSectionTitle('Recent Entries'),
          SizedBox(height: 12),
          _buildRecentEntries(),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  Widget _buildMetricsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Success Rate',
                value: '${_overallSuccessRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Entries',
                value: '$_totalEntries',
                icon: Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Positive Days',
                value: '$_totalPositiveDays',
                icon: Icons.thumb_up_alt_outlined,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Negative Days',
                value: '$_totalNegativeDays',
                icon: Icons.thumb_down_alt_outlined,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_bestCurrentStreak > 0)
          _buildMetricCard(
            title: 'Best Current Streak',
            value: '$_bestCurrentStreak days - $_bestStreakHabit',
            icon: Icons.local_fire_department,
            color: Colors.orange,
            isWide: true,
          ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isWide ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessRateChart() {
    if (_habits.isEmpty) {
      return SizedBox();
    }
    
    return SizedBox(
      height: 220,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() < _habits.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _habits[value.toInt()].name.length > 6
                                ? '${_habits[value.toInt()].name.substring(0, 6)}...'
                                : _habits[value.toInt()].name,
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              barGroups: List.generate(_habits.length, (index) {
                final habit = _habits[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: habit.successRate,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStreaksList() {
    if (_habits.isEmpty) {
      return SizedBox();
    }
    
    // Sort habits by current streak
    final sortedHabits = [..._habits]..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    
    return Card(
      elevation: 2, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: sortedHabits.length > 5 ? 5 : sortedHabits.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final habit = sortedHabits[index];
          return Row(
            children: [
              Icon(
                habit.icon ?? Icons.star,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: habit.currentStreak > 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${habit.currentStreak} days',
                  style: TextStyle(
                    color: habit.currentStreak > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildRecentEntries() {
    if (_habits.isEmpty) {
      return SizedBox();
    }
    
    // Collect all entries from all habits
    List<MapEntry<Habit, HabitEntry>> allEntries = [];
    
    for (var habit in _habits) {
      for (var entry in habit.entries) {
        allEntries.add(MapEntry(habit, entry));
      }
    }
    
    // Sort by date (newest first)
    allEntries.sort((a, b) => b.value.date.compareTo(a.value.date));
    
    // Take only the 5 most recent
    final recentEntries = allEntries.take(5).toList();
    
    if (recentEntries.isEmpty) {
      return Center(child: Text('No entries yet'));
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: recentEntries.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final habit = recentEntries[index].key;
          final entry = recentEntries[index].value;
          final isPositive = habit.isPositiveDay(entry);
          
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPositive 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.check : Icons.close,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(entry.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                'Day ${entry.dayNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
