import 'package:flutter/material.dart';
import 'package:flux/data/models/habit.dart';

class GamificationDisplay extends StatelessWidget {
  final Habit habit;
  final bool isCompact;
  
  const GamificationDisplay({
    super.key,
    required this.habit,
    this.isCompact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactDisplay(context);
    } else {
      return _buildFullDisplay(context);
    }
  }
  
  Widget _buildCompactDisplay(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getLevelColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _getLevelColor(), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, size: 12, color: _getLevelColor()),
              SizedBox(width: 2),
              Text(
                'Lv.${habit.level}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(width: 6),
        
        // Points
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 12, color: Colors.amber),
              SizedBox(width: 2),
              Text(
                '${habit.totalPoints}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFullDisplay(BuildContext context) {
    final progress = _getExperienceProgress();
    final nextLevelXP = _getNextLevelXP();
    final currentLevelXP = _getCurrentLevelXP();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLevelColor().withOpacity(0.1),
            _getLevelColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getLevelColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getLevelColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: _getLevelColor(),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${habit.level} ${_getLevelTitle()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(),
                      ),
                    ),
                    Text(
                      '${habit.totalPoints} Total Points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      '${habit.experiencePoints} XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Progress to next level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to Level ${habit.level + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${habit.experiencePoints - currentLevelXP}/${nextLevelXP - currentLevelXP} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Streak',
                  '${habit.currentStreak}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  'Success',
                  '${habit.successRate.toStringAsFixed(0)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  'Entries',
                  '${habit.entries.length}',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getLevelColor() {
    if (habit.level >= 50) return Color(0xFFFFD700); // Gold color
    if (habit.level >= 30) return Colors.purple;
    if (habit.level >= 20) return Colors.blue;
    if (habit.level >= 10) return Colors.green;
    return Colors.grey;
  }
  
  String _getLevelTitle() {
    if (habit.level >= 50) return 'Master';
    if (habit.level >= 30) return 'Expert';
    if (habit.level >= 20) return 'Advanced';
    if (habit.level >= 10) return 'Intermediate';
    return 'Beginner';
  }
  
  double _getExperienceProgress() {
    final currentLevelXP = _getCurrentLevelXP();
    final nextLevelXP = _getNextLevelXP();
    final currentXP = habit.experiencePoints - currentLevelXP;
    final xpForNextLevel = nextLevelXP - currentLevelXP;
    
    return xpForNextLevel > 0 ? currentXP / xpForNextLevel : 0.0;
  }
  
  int _getCurrentLevelXP() {
    return ((habit.level - 1) * 1000);
  }
  
  int _getNextLevelXP() {
    return (habit.level * 1000);
  }
}

// Extension to add gamification display to HabitListItem
extension GamificationExtension on Widget {
  Widget withGamification(Habit habit, {bool compact = true}) {
    return Column(
      children: [
        this,
        if (habit.totalPoints > 0 || habit.level > 1) ...[
          SizedBox(height: 8),
          GamificationDisplay(habit: habit, isCompact: compact),
        ],
      ],
    );
  }
} 