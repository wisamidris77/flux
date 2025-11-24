import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/notification_service.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/data/achievements/achievement_base.dart';
import 'package:flux/data/achievements/streak_achievements.dart';
import 'package:flux/data/achievements/milestone_achievements.dart';
import 'package:flux/data/achievements/consistency_achievements.dart';
import 'package:flux/data/achievements/special_achievements.dart';
import 'package:flux/data/achievements/legendary_achievements.dart';
import 'package:flux/data/achievements/bad_achievements.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsSystem {
  // Combined achievement definitions from all categories
  static final Map<String, AchievementDefinition> achievementDefinitions = {
    ...streakAchievements,           // 15 achievements
    ...milestoneAchievements,        // 16 achievements  
    ...consistencyAchievements,      // 18 achievements
    ...specialAchievements,          // 24 achievements
    ...legendaryAchievements,        // 20 achievements
    ...badAchievements,              // 23 achievements
  };
  
  // Total: 116 achievements!
  
  // Check and award achievements for a habit
  static Future<List<AchievementEarned>> checkAndAwardAchievements(Habit habit) async {
    final newAchievements = <AchievementEarned>[];
    final prefs = await SharedPreferences.getInstance();
    final globalUnlockedAchievements = prefs.getStringList('global_achievements') ?? [];
    
    // Check each achievement definition
    for (final achievement in achievementDefinitions.values) {
      // Skip if already unlocked globally
      if (globalUnlockedAchievements.contains(achievement.id)) {
        continue;
      }
      
      // Check if condition is met
      if (achievement.checkCondition(habit)) {
        final earned = AchievementEarned(
          definition: achievement,
          earnedAt: DateTime.now(),
          habitName: habit.name,
        );
        
        newAchievements.add(earned);
        
        // Add to global unlocked achievements
        globalUnlockedAchievements.add(achievement.id);
        await prefs.setStringList('global_achievements', globalUnlockedAchievements);
        
        // Also add to habit's unlocked achievements for backward compatibility
        habit.unlockedAchievements.add(achievement.id);
        
        // Award points to habit
        final levelUpMessages = habit.addPoints(achievement.points);
        
        // Show notification
        await NotificationService.showAchievementNotification(
          title: achievement.isBadAchievement 
              ? 'Oops! Achievement Unlocked 😅'
              : 'Achievement Unlocked! 🏆',
          body: '${achievement.name}: ${achievement.description}',
        );
        
        // Handle level ups
        for (final message in levelUpMessages) {
          if (message.contains('Level')) {
            final level = int.tryParse(message.replaceAll(RegExp(r'[^0-9]'), ''));
            if (level != null) {
              await NotificationService.showLevelUpNotification(habit, level);
            }
          }
        }
      }
    }
    
    // Save updated habit
    if (newAchievements.isNotEmpty) {
      await StorageService.save(habit);
    }
    
    return newAchievements;
  }
  
  // Show celebration effect
  static void showCelebrationEffect(BuildContext context, AchievementEarned achievement) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => CelebrationOverlay(
        achievement: achievement,
        onComplete: () => overlayEntry.remove(),
      ),
    );
    
    overlay.insert(overlayEntry);
  }
  
  // Get all achievements for a habit
  static Future<List<AchievementEarned>> getGlobalAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final globalUnlockedAchievements = prefs.getStringList('global_achievements') ?? [];
    final earned = <AchievementEarned>[];
    
    for (final achievementId in globalUnlockedAchievements) {
      if (achievementDefinitions.containsKey(achievementId)) {
        earned.add(AchievementEarned(
          definition: achievementDefinitions[achievementId]!,
          earnedAt: DateTime.now(), // This would be stored properly in a real app
          habitName: 'Global Achievement',
        ));
      }
    }
    
    return earned;
  }
  
  // Get achievement progress
  static Map<String, double> getAchievementProgress(Habit habit) {
    final progress = <String, double>{};
    
    for (final achievement in achievementDefinitions.values) {
      // Simple progress calculation based on achievement type
      if (achievement.id.contains('streak')) {
        final target = _extractNumberFromId(achievement.id, 'streak');
        progress[achievement.id] = (habit.currentStreak / target).clamp(0.0, 1.0);
      } else if (achievement.id.contains('entries') || achievement.id.contains('century')) {
        final target = _extractNumberFromId(achievement.id, 'entries');
        progress[achievement.id] = (habit.entries.length / target).clamp(0.0, 1.0);
      } else if (achievement.id.contains('points')) {
        final target = _extractNumberFromId(achievement.id, 'points');
        progress[achievement.id] = (habit.totalPoints / target).clamp(0.0, 1.0);
      } else {
        // For complex achievements, just check if condition is met
        progress[achievement.id] = achievement.checkCondition(habit) ? 1.0 : 0.0;
      }
    }
    
    return progress;
  }
  
  // Helper to extract numbers from achievement IDs for progress calculation
  static double _extractNumberFromId(String id, String type) {
    switch (id) {
      // Streak achievements
      case 'first_3_days': return 3;
      case 'first_week': return 7;
      case 'two_weeks': return 14;
      case 'three_weeks': return 21;
      case 'first_month': return 30;
      case 'six_weeks': return 42;
      case 'two_months': return 60;
      case 'three_months': return 90;
      case 'centurion': return 100;
      case 'half_year': return 180;
      case 'year_warrior': return 365;
      case 'immortal_streak': return 500;
      case 'eternal_dedication': return 1000;
      case 'transcendent': return 1500;
      
      // Entry achievements
      case 'first_entry': return 1;
      case 'getting_started': return 10;
      case 'quarter_century': return 25;
      case 'half_century': return 50;
      case 'century_club': return 100;
      case 'double_century': return 200;
      case 'triple_century': return 300;
      case 'half_millennium': return 500;
      case 'millennium': return 1000;
      case 'dedication_master': return 2000;
      case 'habit_overlord': return 5000;
      case 'habit_emperor': return 10000;
      
      // Point achievements
      case 'first_thousand_points': return 1000;
      case 'point_collector': return 5000;
      case 'point_master': return 10000;
      case 'legend': return 25000;
      case 'point_deity': return 50000;
      case 'point_legend': return 100000;
      case 'point_omnipotent': return 1000000;
      
      default: return 100; // Default target
    }
  }
  
  // Get achievements by category
  static Map<String, List<AchievementDefinition>> getAchievementsByCategory() {
    final categories = <String, List<AchievementDefinition>>{};
    
    // Categorize achievements
    for (final achievement in achievementDefinitions.values) {
      String category;
      
      if (achievement.isBadAchievement) {
        category = '🚫 Hall of Shame';
      } else if (achievement.rarity == AchievementRarity.mythic) {
        category = '🌟 Mythic Legends';
      } else if (achievement.rarity == AchievementRarity.legendary) {
        category = '👑 Legendary Heroes';
      } else if (achievement.id.contains('streak') || achievement.id.contains('week') || achievement.id.contains('month')) {
        category = '🔥 Streak Masters';
      } else if (achievement.id.contains('entry') || achievement.id.contains('century') || achievement.id.contains('millennium')) {
        category = '📊 Entry Milestones';
      } else if (achievement.id.contains('consistency') || achievement.id.contains('perfect') || achievement.id.contains('success')) {
        category = '⭐ Consistency Champions';
      } else if (achievement.id.contains('point') || achievement.id.contains('thousand')) {
        category = '💎 Point Collectors';
      } else {
        category = '🎯 Special Achievements';
      }
      
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(achievement);
    }
    
    // Sort achievements within each category by rarity and points
    for (final categoryAchievements in categories.values) {
      categoryAchievements.sort((a, b) {
        if (a.rarity.index != b.rarity.index) {
          return a.rarity.index.compareTo(b.rarity.index);
        }
        return a.points.compareTo(b.points);
      });
    }
    
    return categories;
  }
  
  // Get total achievement stats
  static Map<String, int> getAchievementStats() {
    final stats = <String, int>{
      'total': achievementDefinitions.length,
      'common': 0,
      'uncommon': 0,
      'rare': 0,
      'epic': 0,
      'legendary': 0,
      'mythic': 0,
      'bad': 0,
    };
    
    for (final achievement in achievementDefinitions.values) {
      if (achievement.isBadAchievement) {
        stats['bad'] = stats['bad']! + 1;
      } else {
        final rarity = achievement.rarity.name.toLowerCase();
        stats[rarity] = stats[rarity]! + 1;
      }
    }
    
    return stats;
  }
}

// Celebration overlay widget
class CelebrationOverlay extends StatefulWidget {
  final AchievementEarned achievement;
  final VoidCallback onComplete;
  
  const CelebrationOverlay({
    super.key,
    required this.achievement,
    required this.onComplete,
  });
  
  @override
  _CelebrationOverlayState createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: Duration(seconds: 2),
    );
    
    _startAnimation();
  }
  
  void _startAnimation() async {
    await Future.delayed(Duration(milliseconds: 100));
    _slideController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _scaleController.forward();
    
    // Only show confetti for positive achievements
    if (!widget.achievement.definition.isBadAchievement) {
      _confettiController.play();
    }
    
    // Auto-dismiss after 3 seconds
    await Future.delayed(Duration(seconds: 3));
    _dismiss();
  }
  
  void _dismiss() async {
    _confettiController.stop();
    await _slideController.reverse();
    widget.onComplete();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isbad = widget.achievement.definition.isBadAchievement;
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          
          // Confetti (only for good achievements)
          if (!isbad)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 1.5708, // Down
                particleDrag: 0.05,
                emissionFrequency: 0.3,
                numberOfParticles: 30,
                gravity: 0.3,
                shouldLoop: false,
                colors: [
                  widget.achievement.definition.color,
                  widget.achievement.definition.rarity.color,
                  Colors.yellow,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                ],
              ),
            ),
          
          // Achievement card
          Center(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, -1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.elasticOut,
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.elasticOut,
                )),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 300,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: isbad 
                          ? Border.all(color: Colors.red, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: widget.achievement.definition.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.achievement.definition.color,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            widget.achievement.definition.icon,
                            size: 40,
                            color: widget.achievement.definition.color,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          isbad ? 'Oops! Achievement Unlocked!' : 'Achievement Unlocked!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isbad ? Colors.red : Colors.amber,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.achievement.definition.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.achievement.definition.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.achievement.definition.rarity.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.achievement.definition.rarity.color,
                            ),
                          ),
                          child: Text(
                            widget.achievement.definition.rarity.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.achievement.definition.rarity.color,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '${widget.achievement.definition.points > 0 ? '+' : ''}${widget.achievement.definition.points} Points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.achievement.definition.points > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 