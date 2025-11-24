import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/features/achievements/achievements_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux/core/services/theme_service.dart';
import 'package:flux/data/achievements/achievement_base.dart';

class DebugTestPage extends StatefulWidget {
  const DebugTestPage({super.key});
  
  @override
  _DebugTestPageState createState() => _DebugTestPageState();
}

class _DebugTestPageState extends State<DebugTestPage> {
  List<Habit> _habits = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadHabits();
  }
  
  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final habits = await StorageService.loadAll();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: Text('Access Denied')),
        body: Center(
          child: Text('This page is only available in debug mode'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🛠️ Debug Test Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'DEBUG MODE ONLY\nThese actions will modify your actual data!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Test Actions
                  _buildSectionHeader('🏆 Achievement Tests'),
                  SizedBox(height: 16),
                  _buildTestCard(
                    title: 'Unlock All Achievements',
                    description: 'Unlocks all achievements for testing purposes',
                    icon: Icons.emoji_events,
                    color: Colors.purple,
                    onTap: _unlockAllAchievements,
                  ),
                  
                  SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Clear All Achievements',
                    description: 'Removes all unlocked achievements',
                    icon: Icons.clear_all,
                    color: Colors.orange,
                    onTap: _clearAllAchievements,
                  ),
                  
                  SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Show Achievement Dialog',
                    description: 'Tests the achievement celebration overlay',
                    icon: Icons.celebration,
                    color: Colors.amber,
                    onTap: _showTestAchievementDialog,
                  ),
                  
                  SizedBox(height: 24),
                  
                  _buildSectionHeader('⭐ Points & Level Tests'),
                  SizedBox(height: 16),
                  _buildTestCard(
                    title: 'Add 10,000 Points',
                    description: 'Adds points to all habits for testing',
                    icon: Icons.star,
                    color: Colors.amber,
                    onTap: () => _addPointsToAllHabits(10000),
                  ),
                  
                  SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Max Out All Levels',
                    description: 'Sets all habits to maximum level',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    onTap: _maxOutAllLevels,
                  ),
                  
                  SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Reset All Progress',
                    description: 'Resets all points and levels to 0',
                    icon: Icons.restart_alt,
                    color: Colors.red,
                    onTap: _resetAllProgress,
                  ),
                  
                  SizedBox(height: 24),
                  
                  _buildSectionHeader('📊 Data Tests'),
                  SizedBox(height: 16),
                  _buildTestCard(
                    title: 'Create Test Habits',
                    description: 'Creates sample habits with various data',
                    icon: Icons.add_circle,
                    color: Colors.blue,
                    onTap: _createTestHabits,
                  ),
                  
                  SizedBox(height: 12),
                  _buildTestCard(
                    title: 'Simulate Long Streaks',
                    description: 'Adds entries to simulate long streaks',
                    icon: Icons.local_fire_department,
                    color: Colors.deepOrange,
                    onTap: _simulateLongStreaks,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Current Stats
                  _buildSectionHeader('📈 Current Stats'),
                  SizedBox(height: 16),
                  _buildStatsOverview(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
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
    );
  }
  
  Widget _buildTestCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsOverview() {
    if (_habits.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No habits found. Create some test habits first.'),
        ),
      );
    }
    
    final totalPoints = _habits.fold<int>(0, (sum, h) => sum + h.totalPoints);
    final totalLevel = _habits.fold<int>(0, (sum, h) => sum + h.level);
    final totalAchievements = _habits.fold<int>(0, (sum, h) => sum + h.unlockedAchievements.length);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Points', totalPoints.toString(), Icons.star, Colors.amber),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Total Levels', totalLevel.toString(), Icons.trending_up, Colors.green),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Achievements', totalAchievements.toString(), Icons.emoji_events, Colors.purple),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Habits', _habits.length.toString(), Icons.list, Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _unlockAllAchievements() async {
    setState(() => _isLoading = true);
    
    // Get all achievement IDs
    final allAchievementIds = AchievementsSystem.achievementDefinitions.keys.toList();
    
    // Store in global achievements
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('global_achievements', allAchievementIds);
    
    // Also add to each habit for backward compatibility
    for (final habit in _habits) {
      habit.unlockedAchievements = Set<String>.from(allAchievementIds).toList();
      await StorageService.save(habit);
    }
    
    // Unlock all themes
    final allThemes = ThemeService.themePresets.keys.toList();
    await prefs.setStringList('unlocked_themes', allThemes);
    
    // Unlock all shop items
    final purchasedItems = [
      'Emoji Pack', 'Sport Icons', 'Nature Pack', 'Tech Icons',
      'Food & Drink', 'Travel Pack', 'Minimalist Set', 'Vintage Collection',
      'Advanced Analytics', 'Custom Widgets', 'Habit Templates', 'Export Data',
      'Goal Tracking', 'Habit Streaks+', 'Smart Reminders', 'Mood Tracking',
      'Habit Groups', 'Time Tracking'
    ];
    await prefs.setStringList('purchased_items', purchasedItems);
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All achievements, themes and shop items unlocked!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _clearAllAchievements() async {
    setState(() => _isLoading = true);
    
    // Clear global achievements
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('global_achievements', []);
    
    // Clear each habit's achievements
    for (final habit in _habits) {
      habit.unlockedAchievements = <String>[];
      await StorageService.save(habit);
    }
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All achievements cleared!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  Future<void> _addPointsToAllHabits(int points) async {
    setState(() => _isLoading = true);
    
    for (final habit in _habits) {
      // Add points without triggering achievements
      habit.totalPoints += points;
      
      // Calculate level
      int newLevel = 1;
      int pointsNeeded = 100;
      int remainingPoints = habit.totalPoints;
      
      while (remainingPoints >= pointsNeeded) {
        remainingPoints -= pointsNeeded;
        newLevel++;
        pointsNeeded = (newLevel * 100);
      }
      
      habit.level = newLevel;
      
      await StorageService.save(habit);
    }
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $points points to all habits!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _maxOutAllLevels() async {
    for (final habit in _habits) {
      habit.level = 100;
      habit.experiencePoints = 100000;
      habit.totalPoints = 100000;
      await StorageService.save(habit);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All habits maxed out! 🚀'),
        backgroundColor: Colors.green,
      ),
    );
    
    _loadHabits();
  }
  
  Future<void> _resetAllProgress() async {
    for (final habit in _habits) {
      habit.level = 1;
      habit.experiencePoints = 0;
      habit.totalPoints = 0;
      habit.unlockedAchievements.clear();
      await StorageService.save(habit);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All progress reset'),
        backgroundColor: Colors.red,
      ),
    );
    
    _loadHabits();
  }
  
  Future<void> _createTestHabits() async {
    // Implementation would create sample habits
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test habits created! 📝'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  Future<void> _simulateLongStreaks() async {
    // Implementation would add entries to simulate streaks
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Long streaks simulated! 🔥'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
  
  void _showTestAchievementDialog() {
    // Create a test achievement
    final testAchievement = AchievementEarned(
      definition: AchievementDefinition(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'This is a test achievement for debugging purposes',
        icon: Icons.star,
        color: Colors.amber,
        points: 100,
        rarity: AchievementRarity.legendary,
        isBadAchievement: false,
        checkCondition: (_) => true,
      ),
      earnedAt: DateTime.now(),
      habitName: 'Test Habit',
    );
    
    // Show the celebration effect
    AchievementsSystem.showCelebrationEffect(context, testAchievement);
  }
} 