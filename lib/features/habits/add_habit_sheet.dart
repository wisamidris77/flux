// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/settings_service.dart';

class AddHabitSheet extends StatefulWidget {
  final Function(Habit) onSave;
  final List<String> existingCategories;
  const AddHabitSheet({super.key, required this.onSave, this.existingCategories = const []});
  @override _AddHabitSheetState createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _targetValueCtrl = TextEditingController();
  final _targetFrequencyCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();
  
  HabitType _type = HabitType.DoneBased;
  IconData _icon = Icons.star;
  Color _color = Color(0xFF1DB954);
  HabitFrequency _frequency = HabitFrequency.Daily;
  HabitUnit _unit = HabitUnit.Count;
  final List<int> _customDays = [];
  String? _selectedCategory;
  bool _hasMeasurableGoal = false;
  
  late TabController _tabController;
  
  final _icons = [
    Icons.star, Icons.fitness_center, Icons.book, Icons.brush, 
    Icons.run_circle, Icons.water_drop, Icons.food_bank, Icons.bed,
    Icons.emoji_emotions, Icons.self_improvement, Icons.music_note, 
    Icons.code, Icons.sports_basketball, Icons.smoking_rooms, 
    Icons.local_drink, Icons.monitor, Icons.health_and_safety,
    Icons.directions_run, Icons.dark_mode, Icons.light_mode,
    Icons.pets, Icons.nature, Icons.volunteer_activism, Icons.school,
    Icons.alarm, Icons.piano, Icons.savings, Icons.attach_money
  ];
  
  final List<Color> _colorOptions = [
    Color(0xFF1DB954), Color(0xFF2196F3), Color(0xFFF44336), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFF795548), Color(0xFF607D8B), Color(0xFF009688),
    Color(0xFFE91E63), Color(0xFF4CAF50), Color(0xFF673AB7), Color(0xFFFF5722),
  ];
  
  final List<String> _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDefaults();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _categoryCtrl.dispose();
    _targetValueCtrl.dispose();
    _targetFrequencyCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }
  
  Future<void> _loadDefaults() async {
    _type = await SettingsService.getDefaultHabitType();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Create New Habit', 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Basic'),
              Tab(text: 'Schedule'),
              Tab(text: 'Goals'),
              Tab(text: 'Style'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicTab(),
                _buildScheduleTab(),
                _buildGoalsTab(),
                _buildStyleTab(),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _createHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Create Habit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(),
          SizedBox(height: 16),
          _buildNotesField(),
          SizedBox(height: 16),
          _buildCategoryField(),
          SizedBox(height: 24),
          Text(
            'Habit Type', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          _buildHabitTypeSelector(),
        ],
      ),
    );
  }
  
  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How often should this habit occur?', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildFrequencySelector(),
          if (_frequency == HabitFrequency.CustomDays) ...[
            SizedBox(height: 16),
            _buildCustomDaysSelector(),
          ],
          if (_frequency == HabitFrequency.XTimesPerWeek || _frequency == HabitFrequency.XTimesPerMonth) ...[
            SizedBox(height: 16),
            _buildTargetFrequencyField(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text('Set Measurable Goal'),
            subtitle: Text('Track specific values instead of just counts'),
            value: _hasMeasurableGoal,
            onChanged: (value) {
              setState(() {
                _hasMeasurableGoal = value;
                if (!value) {
                  _unit = HabitUnit.Count;
                  _targetValueCtrl.clear();
                }
              });
            },
          ),
          if (_hasMeasurableGoal) ...[
            SizedBox(height: 16),
            Text(
              'Unit of Measurement', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            _buildUnitSelector(),
            if (_unit == HabitUnit.Custom) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _customUnitCtrl,
                decoration: InputDecoration(
                  labelText: 'Custom Unit Name',
                  hintText: 'e.g., cups, sets, chapters',
                  filled: true,
                ),
              ),
            ],
            SizedBox(height: 16),
            TextFormField(
              controller: _targetValueCtrl,
              decoration: InputDecoration(
                labelText: _getTargetLabel(),
                hintText: _getTargetHint(),
                filled: true,
                suffixText: _getUnitName(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStyleTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Icon', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          _buildIconSelector(),
          SizedBox(height: 24),
          Text(
            'Color', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          _buildColorSelector(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        hintText: 'Habit name',
        labelText: 'Name',
        prefixIcon: Icon(Icons.edit),
        filled: true,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: 16),
    );
  }
  
  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesCtrl,
      decoration: InputDecoration(
        hintText: 'Optional description or notes',
        labelText: 'Notes',
        prefixIcon: Icon(Icons.note),
        filled: true,
      ),
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: 14),
      maxLines: 2,
    );
  }
  
  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category (Optional)', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        if (widget.existingCategories.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            children: widget.existingCategories.map((category) =>
              FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                    _categoryCtrl.text = selected ? category : '';
                  });
                },
              )
            ).toList(),
          ),
          SizedBox(height: 8),
          Text('Or create new:', style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 4),
        ],
        TextFormField(
          controller: _categoryCtrl,
          decoration: InputDecoration(
            hintText: 'e.g., Fitness, Learning, Health',
            prefixIcon: Icon(Icons.category),
            filled: true,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() => _selectedCategory = null);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildHabitTypeSelector() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: HabitType.values.map((type) {
          final isSelected = _type == type;
          String typeLabel;
          
          switch (type) {
            case HabitType.FailBased:
              typeLabel = 'Avoid';
              break;
            case HabitType.SuccessBased:
              typeLabel = 'Achieve';
              break;
            case HabitType.DoneBased:
              typeLabel = 'Check';
              break;
          }
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = type),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                      ? Colors.white 
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildFrequencySelector() {
    return Column(
      children: HabitFrequency.values.map((frequency) {
        final isSelected = _frequency == frequency;
        String label = _getFrequencyLabel(frequency);
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: RadioListTile<HabitFrequency>(
            title: Text(label),
            value: frequency,
            groupValue: _frequency,
            onChanged: (value) {
              setState(() {
                _frequency = value!;
                if (frequency != HabitFrequency.CustomDays) {
                  _customDays.clear();
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildCustomDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Days', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _customDays.contains(index);
            return FilterChip(
              label: Text(_weekDays[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _customDays.add(index);
                  } else {
                    _customDays.remove(index);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildTargetFrequencyField() {
    return TextFormField(
      controller: _targetFrequencyCtrl,
      decoration: InputDecoration(
        labelText: _frequency == HabitFrequency.XTimesPerWeek ? 'Times per week' : 'Times per month',
        hintText: 'e.g., 3',
        filled: true,
      ),
      keyboardType: TextInputType.number,
    );
  }
  
  Widget _buildUnitSelector() {
    return DropdownButtonFormField<HabitUnit>(
      initialValue: _unit,
      decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: HabitUnit.values.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(_getUnitDisplayName(unit)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _unit = value!;
        });
      },
    );
  }
  
  Widget _buildIconSelector() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = _icon == icon;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _icon = icon),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2) 
                    : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildColorSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colorOptions.length,
        itemBuilder: (context, index) {
          final color = _colorOptions[index];
          final isSelected = _color.value == color.value;
          
          return GestureDetector(
            onTap: () => setState(() => _color = color),
            child: Container(
              width: 48,
              height: 48,
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: isSelected ? 8 : 0,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: isSelected 
                ? Icon(Icons.check, color: Colors.white)
                : null,
            ),
          );
        },
      ),
    );
  }
  
  String _getFrequencyLabel(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.Daily:
        return 'Daily';
      case HabitFrequency.Weekdays:
        return 'Weekdays (Mon-Fri)';
      case HabitFrequency.Weekends:
        return 'Weekends (Sat-Sun)';
      case HabitFrequency.CustomDays:
        return 'Custom Days';
      case HabitFrequency.XTimesPerWeek:
        return 'X times per week';
      case HabitFrequency.XTimesPerMonth:
        return 'X times per month';
    }
  }
  
  String _getUnitDisplayName(HabitUnit unit) {
    switch (unit) {
      case HabitUnit.Count:
        return 'Count/Times';
      case HabitUnit.Minutes:
        return 'Minutes';
      case HabitUnit.Hours:
        return 'Hours';
      case HabitUnit.Pages:
        return 'Pages';
      case HabitUnit.Kilometers:
        return 'Kilometers';
      case HabitUnit.Miles:
        return 'Miles';
      case HabitUnit.Grams:
        return 'Grams';
      case HabitUnit.Pounds:
        return 'Pounds';
      case HabitUnit.Dollars:
        return 'Dollars';
      case HabitUnit.Custom:
        return 'Custom Unit';
    }
  }
  
  String _getTargetLabel() {
    switch (_type) {
      case HabitType.FailBased:
        return 'Maximum allowed per day';
      case HabitType.SuccessBased:
        return 'Target amount per day';
      case HabitType.DoneBased:
        return 'Target amount';
    }
  }
  
  String _getTargetHint() {
    switch (_type) {
      case HabitType.FailBased:
        return 'e.g., 2 (max 2 cigarettes)';
      case HabitType.SuccessBased:
        return 'e.g., 30 (read 30 pages)';
      case HabitType.DoneBased:
        return 'e.g., 10 (meditate 10 minutes)';
    }
  }
  
  String _getUnitName() {
    if (_unit == HabitUnit.Custom && _customUnitCtrl.text.isNotEmpty) {
      return _customUnitCtrl.text;
    }
    return _getUnitDisplayName(_unit);
  }
  
  void _createHabit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    
    final category = _selectedCategory ?? (_categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : null);
    
    final targetValue = _hasMeasurableGoal && _targetValueCtrl.text.isNotEmpty 
        ? double.tryParse(_targetValueCtrl.text) 
        : null;
        
    final targetFrequency = (_frequency == HabitFrequency.XTimesPerWeek || _frequency == HabitFrequency.XTimesPerMonth) && _targetFrequencyCtrl.text.isNotEmpty
        ? int.tryParse(_targetFrequencyCtrl.text)
        : null;
    
    final customUnit = _unit == HabitUnit.Custom ? _customUnitCtrl.text.trim() : null;
    
    widget.onSave(Habit(
      name: name,
      type: _type,
      icon: _icon,
      color: _color,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      category: category,
      frequency: _frequency,
      customDays: _frequency == HabitFrequency.CustomDays ? _customDays : [],
      targetFrequency: targetFrequency,
      targetValue: targetValue,
      unit: _hasMeasurableGoal ? _unit : HabitUnit.Count,
      customUnit: customUnit,
    ));
  }
}
