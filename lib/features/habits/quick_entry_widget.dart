import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/features/achievements/achievements_system.dart';
import 'package:flux/core/services/notification_service.dart';

class QuickEntryWidget extends StatefulWidget {
  final List<Habit> habits;
  final Function() onUpdate;
  
  const QuickEntryWidget({
    super.key,
    required this.habits,
    required this.onUpdate,
  });
  
  @override
  _QuickEntryWidgetState createState() => _QuickEntryWidgetState();
}

class _QuickEntryWidgetState extends State<QuickEntryWidget> {
  // Get habits due today
  List<Habit> get habitsToday => widget.habits
      .where((h) => h.isDueToday() && !h.isArchived && !h.isPaused)
      .toList();
  
  // Get completed habits today
  List<Habit> get completedToday => widget.habits.where((h) {
    final today = DateTime.now();
    final todayEntries = h.entries.where((e) => 
      e.date.year == today.year &&
      e.date.month == today.month &&
      e.date.day == today.day &&
      h.isPositiveDay(e)
    );
    return todayEntries.isNotEmpty;
  }).toList();
  
  @override
  Widget build(BuildContext context) {
    if (habitsToday.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              SizedBox(height: 12),
              Text(
                'All habits completed for today! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Great job staying consistent!',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Today\'s Habits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${completedToday.length}/${habitsToday.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: habitsToday.isEmpty ? 1.0 : completedToday.length / habitsToday.length,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                completedToday.length == habitsToday.length 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Quick entry list
          ...habitsToday.map((habit) => _buildQuickEntryItem(habit)),
          
          SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildQuickEntryItem(Habit habit) {
    final isCompleted = completedToday.contains(habit);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Colors.green.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: habit.color?.withOpacity(0.1) ?? 
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            habit.icon ?? Icons.star,
            color: habit.color ?? Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          _getSubtitleText(habit),
          style: TextStyle(fontSize: 12),
        ),
        trailing: _buildQuickActionButton(habit, isCompleted),
        onTap: () => _showQuickEntryDialog(habit),
      ),
    );
  }
  
  String _getSubtitleText(Habit habit) {
    if (habit.targetValue != null) {
      return 'Target: ${habit.targetValue} ${habit.getUnitDisplayName()}';
    }
    
    switch (habit.type) {
      case HabitType.DoneBased:
        return 'Tap to mark as done';
      case HabitType.SuccessBased:
        return 'Track your progress';
      case HabitType.FailBased:
        return 'Avoid or track failure';
    }
  }
  
  Widget _buildQuickActionButton(Habit habit, bool isCompleted) {
    if (isCompleted) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: Colors.white, size: 20),
      );
    }
    
    if (habit.type == HabitType.DoneBased && habit.unit == HabitUnit.Count) {
      // Quick complete button for simple done-based habits
      return GestureDetector(
        onTap: () => _quickComplete(habit),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: habit.color ?? Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add, color: Colors.white, size: 20),
        ),
      );
    }
    
    // For other types, show quick entry dialog
    return GestureDetector(
      onTap: () => _showQuickEntryDialog(habit),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: habit.color?.withOpacity(0.1) ?? 
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: habit.color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Text(
          'Log',
          style: TextStyle(
            color: habit.color ?? Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Future<void> _quickComplete(Habit habit) async {
    final entry = HabitEntry(
      date: DateTime.now(),
      count: 1,
      dayNumber: habit.getNextDayNumber(),
      notes: 'Quick logged',
    );
    
    habit.entries.add(entry);
    await StorageService.save(habit);
    
    // Check for achievements
    final achievements = await AchievementsSystem.checkAndAwardAchievements(habit);
    
    // Show celebration effects if achievements unlocked
    if (achievements.isNotEmpty && context.mounted) {
      for (final achievement in achievements) {
        AchievementsSystem.showCelebrationEffect(context, achievement);
      }
    }
    
    // Check for streak milestones
    if (habit.isStreakMilestone()) {
      await NotificationService.showStreakMilestoneNotification(habit);
    }
    
    widget.onUpdate();
    
    // Show quick feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} completed! 🎉'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _showQuickEntryDialog(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => QuickEntryDialog(
        habit: habit,
        onSave: (entry) async {
          habit.entries.add(entry);
          await StorageService.save(habit);
          
          // Check for achievements
          final achievements = await AchievementsSystem.checkAndAwardAchievements(habit);
          
          // Show celebration effects
          if (achievements.isNotEmpty && context.mounted) {
            for (final achievement in achievements) {
              AchievementsSystem.showCelebrationEffect(context, achievement);
            }
          }
          
          // Check for streak milestones
          if (habit.isStreakMilestone()) {
            await NotificationService.showStreakMilestoneNotification(habit);
          }
          
          widget.onUpdate();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class QuickEntryDialog extends StatefulWidget {
  final Habit habit;
  final Function(HabitEntry) onSave;
  
  const QuickEntryDialog({
    super.key,
    required this.habit,
    required this.onSave,
  });
  
  @override
  _QuickEntryDialogState createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends State<QuickEntryDialog> {
  final TextEditingController _valueController = TextEditingController();
  bool _isDone = false;
  int _quickValue = 1;
  
  @override
  void initState() {
    super.initState();
    if (widget.habit.targetValue != null) {
      _quickValue = widget.habit.targetValue!.toInt();
      _valueController.text = _quickValue.toString();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.habit.color?.withOpacity(0.1) ?? 
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.habit.icon ?? Icons.star,
                    color: widget.habit.color ?? Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Quick Log Entry',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            if (widget.habit.type == HabitType.DoneBased && widget.habit.unit == HabitUnit.Count) ...[
              // Simple done/not done
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDone ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDone ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: _isDone ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isDone ? 'Completed!' : 'Mark as done?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isDone ? Colors.green : null,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isDone,
                      onChanged: (value) => setState(() => _isDone = value),
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Value entry with quick buttons
              Text(
                'How much?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              
              // Quick value buttons
              Wrap(
                spacing: 8,
                children: _getQuickValueButtons(),
              ),
              
              SizedBox(height: 16),
              
              // Manual entry
              TextFormField(
                controller: _valueController,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: widget.habit.getUnitDisplayName(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _quickValue = int.tryParse(value) ?? 0;
                },
              ),
            ],
            
            SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.habit.color ?? Theme.of(context).colorScheme.primary,
                    ),
                    child: Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _getQuickValueButtons() {
    final buttons = <Widget>[];
    
    if (widget.habit.targetValue != null) {
      final target = widget.habit.targetValue!.toInt();
      buttons.add(_buildQuickButton(target.toString(), target));
      buttons.add(_buildQuickButton('${(target * 0.5).toInt()}', (target * 0.5).toInt()));
      buttons.add(_buildQuickButton('${(target * 1.5).toInt()}', (target * 1.5).toInt()));
    } else {
      // Default quick values
      buttons.addAll([
        _buildQuickButton('1', 1),
        _buildQuickButton('5', 5),
        _buildQuickButton('10', 10),
        _buildQuickButton('15', 15),
        _buildQuickButton('30', 30),
      ]);
    }
    
    return buttons;
  }
  
  Widget _buildQuickButton(String label, int value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _quickValue = value;
          _valueController.text = value.toString();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _quickValue == value 
              ? (widget.habit.color ?? Theme.of(context).colorScheme.primary)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _quickValue == value 
                ? (widget.habit.color ?? Theme.of(context).colorScheme.primary)
                : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _quickValue == value ? Colors.white : null,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  void _save() {
    final entry = HabitEntry(
      date: DateTime.now(),
      dayNumber: widget.habit.getNextDayNumber(),
      count: widget.habit.type == HabitType.DoneBased && widget.habit.unit == HabitUnit.Count
          ? (_isDone ? 1 : 0)
          : _quickValue,
      value: widget.habit.unit != HabitUnit.Count ? _quickValue.toDouble() : null,
      unit: widget.habit.unit != HabitUnit.Count ? widget.habit.getUnitDisplayName() : null,
      notes: 'Quick entry',
    );
    
    widget.onSave(entry);
  }
} 