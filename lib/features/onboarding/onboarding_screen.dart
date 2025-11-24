import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(String?)? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  late AnimationController _headerAnimationController;
  late Animation<Color?> _headerColorAnimation;
  late Animation<double> _headerHeightAnimation;

  // User selections
  String? _selectedQuest;
  final List<String> _selectedAreas = [];
  final Map<String, List<String>> _selectedGoals = {};
  String? _energyLevel;
  String? _timePreference;
  String? _timeAvailability;
  String? _habitPreference;
  String? _startingApproach;
  List<Habit> _suggestedHabits = [];
  final List<Habit> _selectedHabits = [];
  bool _wantsReminders = false;
  String? _reminderTime;
  String? _selectedTheme;

  final List<String> _steps = [
    'Welcome',
    'Quest Selection',
    'Areas of Focus',
    'Specific Goals',
    'Lifestyle Insights',
    'Habit Preferences',
    'Starter Pack',
    'Reminders',
    'Theme',
    'Complete',
  ];

  final List<Color> _stepColors = [
    Color(0xFF1DB954), // Welcome - Spotify Green
    Color(0xFF9C27B0), // Quest - Purple
    Color(0xFF2196F3), // Areas - Blue
    Color(0xFFFF9800), // Goals - Orange
    Color(0xFF4CAF50), // Lifestyle - Green
    Color(0xFFF44336), // Preferences - Red
    Color(0xFF00BCD4), // Starter - Cyan
    Color(0xFFFF5722), // Reminders - Deep Orange
    Color(0xFF3F51B5), // Theme - Indigo
    Color(0xFF1DB954), // Complete - Back to Green
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);

    _headerColorAnimation = ColorTween(
      begin: _stepColors[0],
      end: _stepColors[0],
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeInOut));

    _headerHeightAnimation = Tween<double>(
      begin: 120.0,
      end: 120.0,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _animateHeaderColor() {
    _headerColorAnimation = ColorTween(
      begin: _headerColorAnimation.value,
      end: _stepColors[_currentStep],
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeInOut));

    _headerAnimationController.reset();
    _headerAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAnimatedHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                  _animateHeaderColor();
                },
                children: [
                  _buildWelcomeStep(),
                  _buildQuestStep(),
                  _buildAreasStep(),
                  _buildGoalsStep(),
                  _buildLifestyleStep(),
                  _buildPreferencesStep(),
                  _buildStarterPackStep(),
                  _buildRemindersStep(),
                  _buildThemeStep(),
                  _buildCompleteStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _headerColorAnimation.value ?? _stepColors[_currentStep],
                (_headerColorAnimation.value ?? _stepColors[_currentStep]).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: (_headerColorAnimation.value ?? _stepColors[_currentStep]).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Flux Setup',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  children: List.generate(_steps.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep ? Colors.white : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  '${_currentStep + 1}/${_steps.length} - ${_steps[_currentStep]}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeStep() {
    return AnimationLimiter(
      child: _buildStepContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(horizontalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: _stepColors[_currentStep].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.explore, size: 60, color: _stepColors[_currentStep]),
              ),
              SizedBox(height: 32),
              Text(
                'Welcome to Flux!',
                style: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Let\'s build amazing habits together! Choose your path to get started with personalized recommendations.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildOptionButton(title: 'Quick Start', subtitle: 'Set up manually', icon: Icons.flash_on, onTap: () => _skipToEnd()),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildOptionButton(
                      title: 'Guided Setup',
                      subtitle: 'Recommended',
                      icon: Icons.map,
                      onTap: () => _nextStep(),
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestStep() {
    final quests = [
      {'title': '💪 Boost My Health & Energy', 'value': 'health'},
      {'title': '🧠 Sharpen My Mind & Skills', 'value': 'mind'},
      {'title': '🧘 Find Calm & Reduce Stress', 'value': 'calm'},
      {'title': '🚀 Increase My Productivity', 'value': 'productivity'},
      {'title': '☀️ Build Positive Daily Routines', 'value': 'routines'},
      {'title': '✨ Something Else', 'value': 'other'},
    ];

    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'What\'s Your Main Goal?',
        subtitle: 'Choose what motivates you most right now',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: quests.map((quest) {
              return _buildSelectionCard(
                title: quest['title']!,
                isSelected: _selectedQuest == quest['value'],
                onTap: () => setState(() => _selectedQuest = quest['value']),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAreasStep() {
    final areas = [
      {'title': '🏃 Health & Fitness', 'subtitle': 'exercise, diet, sleep', 'value': 'health'},
      {'title': '💼 Career & Work', 'subtitle': 'focus, skills, organization', 'value': 'career'},
      {'title': '📚 Personal Growth', 'subtitle': 'learning, reading, hobbies', 'value': 'growth'},
      {'title': '💰 Finances', 'subtitle': 'saving, budgeting, mindful spending', 'value': 'finances'},
      {'title': '😊 Mental Well-being', 'subtitle': 'mindfulness, journaling, relaxation', 'value': 'mental'},
      {'title': '🏡 Home & Organization', 'subtitle': 'tidying, chores', 'value': 'home'},
    ];

    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'Choose Your Focus Areas',
        subtitle: 'Which areas of your life would you like to improve? (Select up to 3)',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: areas.map((area) {
              return _buildMultiSelectionCard(
                title: area['title']!,
                subtitle: area['subtitle']!,
                isSelected: _selectedAreas.contains(area['value']),
                onTap: () => _toggleAreaSelection(area['value']!),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsStep() {
    if (_selectedAreas.isEmpty) {
      return _buildStepContainer(
        title: 'Setting Your Goals',
        subtitle: 'Please select some areas first',
        child: Center(
          child: Text('Go back and select some areas of focus first', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'Set Specific Goals',
        subtitle: 'For each area, choose what you\'d like to focus on',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: _selectedAreas.map((area) => _buildGoalSection(area)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSection(String area) {
    final goalOptions = _getGoalOptions(area);
    final selectedGoals = _selectedGoals[area] ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getAreaTitle(area),
            style: TextStyle(color: _stepColors[_currentStep], fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...goalOptions.map((goal) {
            return CheckboxListTile(
              title: Text(goal, style: TextStyle(color: Colors.black87, fontSize: 14)),
              value: selectedGoals.contains(goal),
              onChanged: (value) => _toggleGoalSelection(area, goal),
              activeColor: _stepColors[_currentStep],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLifestyleStep() {
    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'About Your Lifestyle',
        subtitle: 'Help us understand your daily rhythm',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: [
              _buildLifestyleQuestion(
                'My typical daily energy is like:',
                ['🔋 Low Spark', '⚡ Steady Glow', '🔥 Bright Flame'],
                _energyLevel,
                (value) => setState(() => _energyLevel = value),
              ),
              SizedBox(height: 16),
              _buildLifestyleQuestion(
                'I\'m more of a:',
                ['☀️ Morning Person', '🦉 Night Owl'],
                _timePreference,
                (value) => setState(() => _timePreference = value),
              ),
              SizedBox(height: 16),
              _buildLifestyleQuestion(
                'Daily time for new habits:',
                ['⏳ Just a few minutes (<15)', '⏱️ A good moment (15-30)', '🕰️ A dedicated slot (30-60)', '🗓️ It\'s flexible!'],
                _timeAvailability,
                (value) => setState(() => _timeAvailability = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'Your Preferences',
        subtitle: 'How do you like to track your progress?',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: [
              _buildLifestyleQuestion(
                'I prefer habits that are:',
                ['✅ Simple yes/no tracking', '📈 Goal-based with targets', '📉 Avoiding bad behaviors'],
                _habitPreference,
                (value) => setState(() => _habitPreference = value),
              ),
              SizedBox(height: 16),
              _buildLifestyleQuestion(
                'When starting, I prefer to:',
                ['🎯 Focus on one habit', '🤹 Start multiple habits'],
                _startingApproach,
                (value) => setState(() => _startingApproach = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarterPackStep() {
    if (_suggestedHabits.isEmpty) {
      _generateSuggestedHabits();
    }

    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'Your Starter Habits',
        subtitle: 'Based on your preferences, here are some great habits to begin with',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: _suggestedHabits.map((habit) {
              return _buildHabitSuggestionCard(habit);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersStep() {
    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'Daily Reminders',
        subtitle: 'Would you like gentle nudges to stay on track?',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: [
              SwitchListTile(
                title: Text('Enable Reminders', style: TextStyle(color: Colors.black87, fontSize: 16)),
                subtitle: Text(
                  _wantsReminders ? '🔔 Yes, keep me motivated!' : '🔕 No, I\'ll remember myself',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: _wantsReminders,
                onChanged: (value) => setState(() => _wantsReminders = value),
                activeThumbColor: _stepColors[_currentStep],
              ),
              if (_wantsReminders) ...[
                SizedBox(height: 16),
                Text('When would you like to be reminded?', style: TextStyle(color: Colors.black87, fontSize: 16)),
                SizedBox(height: 8),
                ...['🌅 Morning (8-9 AM)', '☀️ Afternoon (1-2 PM)', '🌙 Evening (7-8 PM)'].map((time) {
                  return _buildSelectionCard(title: time, isSelected: _reminderTime == time, onTap: () => setState(() => _reminderTime = time));
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeStep() {
    final themes = [
      {'title': '☀️ Light Mode', 'value': 'light'},
      {'title': '🌑 Dark Mode', 'value': 'dark'},
      {'title': '⚙️ System Default', 'value': 'system'},
    ];

    return AnimationLimiter(
      child: _buildStepContainer(
        title: 'Choose Your Style',
        subtitle: 'Pick a theme that feels right for you',
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: themes.map((theme) {
              return _buildSelectionCard(
                title: theme['title']!,
                isSelected: _selectedTheme == theme['value'],
                onTap: () => setState(() => _selectedTheme = theme['value']),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteStep() {
    return AnimationLimiter(
      child: _buildStepContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: _stepColors[_currentStep].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.celebration, size: 60, color: _stepColors[_currentStep]),
              ),
              SizedBox(height: 32),
              Text(
                'You\'re All Set!',
                style: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Your personalized habits are ready! Start your journey towards better habits and watch yourself grow.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildOptionButton(
                      title: 'Start My Journey!',
                      subtitle: 'Go to main app',
                      icon: Icons.rocket_launch,
                      onTap: () => _completeOnboarding(),
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer({String? title, String? subtitle, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
          ],
          if (subtitle != null) ...[Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.4)), SizedBox(height: 24)],
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? _stepColors[_currentStep] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? _stepColors[_currentStep] : Colors.grey[300]!, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isPrimary ? Colors.white : _stepColors[_currentStep]),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(color: isPrimary ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: isPrimary ? Colors.white.withOpacity(0.8) : Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({required String title, required bool isSelected, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? _stepColors[_currentStep].withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _stepColors[_currentStep] : Colors.grey[300]!, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        trailing: isSelected ? Icon(Icons.check, color: _stepColors[_currentStep]) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildMultiSelectionCard({required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? _stepColors[_currentStep].withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _stepColors[_currentStep] : Colors.grey[300]!, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: isSelected ? Icon(Icons.check, color: _stepColors[_currentStep]) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildLifestyleQuestion(String question, List<String> options, String? selectedValue, Function(String) onChanged) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...options.map((option) {
            return RadioListTile<String>(
              title: Text(option, style: TextStyle(color: Colors.black87, fontSize: 14)),
              value: option,
              groupValue: selectedValue,
              onChanged: (value) => onChanged(value!),
              activeColor: _stepColors[_currentStep],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHabitSuggestionCard(Habit habit) {
    final isSelected = _selectedHabits.contains(habit);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(habit.icon ?? Icons.star, color: _stepColors[_currentStep], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('Type: ${habit.type.toString().split('.').last}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text('Frequency: ${habit.frequency.toString().split('.').last}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleHabitSelection(habit),
                  icon: Icon(isSelected ? Icons.remove : Icons.add),
                  label: Text(isSelected ? 'Remove' : 'Add this Habit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.red : _stepColors[_currentStep],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0),
                child: Text('Back'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(backgroundColor: _stepColors[_currentStep], foregroundColor: Colors.white),
              child: Text(_currentStep == _steps.length - 1 ? 'Complete' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _skipToEnd() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(toggleTheme: () {}, isDarkMode: false)));
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 1:
        return _selectedQuest != null;
      case 2:
        return _selectedAreas.isNotEmpty;
      case 3:
        return _selectedGoals.isNotEmpty;
      case 4:
        return _energyLevel != null && _timePreference != null && _timeAvailability != null;
      case 5:
        return _habitPreference != null && _startingApproach != null;
      case 8:
        return _selectedTheme != null;
      default:
        return true;
    }
  }

  void _toggleAreaSelection(String area) {
    setState(() {
      if (_selectedAreas.contains(area)) {
        _selectedAreas.remove(area);
        _selectedGoals.remove(area);
      } else if (_selectedAreas.length < 3) {
        _selectedAreas.add(area);
      }
    });
  }

  void _toggleGoalSelection(String area, String goal) {
    setState(() {
      if (_selectedGoals[area] == null) {
        _selectedGoals[area] = [];
      }
      if (_selectedGoals[area]!.contains(goal)) {
        _selectedGoals[area]!.remove(goal);
      } else {
        _selectedGoals[area]!.add(goal);
      }
    });
  }

  void _toggleHabitSelection(Habit habit) {
    setState(() {
      if (_selectedHabits.contains(habit)) {
        _selectedHabits.remove(habit);
      } else {
        _selectedHabits.add(habit);
      }
    });
  }

  void _generateSuggestedHabits() {
    // _suggestedHabits = [
    //   Habit(
    //     name: 'Drink Water',
    //     type: HabitType.DoneBased,
    //     frequency: HabitFrequency.Daily,
    //     icon: Icons.local_drink,
    //     targetValue: 8,
    //     unit: HabitUnit.Count,
    //   ),
    //   Habit(
    //     name: 'Morning Walk',
    //     type: HabitType.SuccessBased,
    //     frequency: HabitFrequency.Daily,
    //     icon: Icons.directions_walk,
    //     targetValue: 30,
    //     unit: HabitUnit.Minutes,
    //   ),
    //   Habit(
    //     name: 'Read Books',
    //     type: HabitType.SuccessBased,
    //     frequency: HabitFrequency.Daily,
    //     icon: Icons.book,
    //     targetValue: 20,
    //     unit: HabitUnit.Minutes,
    //   ),
    // ];
    _suggestedHabits = [
      //== Fitness & Workout ==//
      Habit(
        name: 'Workout',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.fitness_center,
        targetValue: 30,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Go for a Run',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.directions_run,
        targetValue: 3, // e.g., 3 Kilometers
        unit: HabitUnit.Kilometers,
      ),
      Habit(
        name: 'Morning Walk',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.directions_walk,
        targetValue: 20,
        unit: HabitUnit.Minutes,
      ),
      //== Breaking Bad Habits ==//
      Habit(
        name: 'No Smoking',
        type: HabitType.FailBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.smoke_free,
        targetValue: 1, // 1 successful day
        unit: HabitUnit.Count,
      ),
      Habit(
        name: 'No PMO',
        type: HabitType.FailBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.shield, // Using a generic, discreet icon
        targetValue: 1, // 1 successful day
        unit: HabitUnit.Count,
      ),
      Habit(
        name: 'No Junk Food',
        type: HabitType.FailBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.no_food,
        targetValue: 1,
        unit: HabitUnit.Count,
      ),
      Habit(
        name: 'Limit Social Media',
        type: HabitType.FailBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.timer_off,
        targetValue: 30, // Max 30 minutes
        unit: HabitUnit.Minutes,
      ),

      Habit(
        name: 'Strength Training',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.fitness_center,
        targetValue: 45,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Stretching / Yoga',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.self_improvement,
        targetValue: 15,
        unit: HabitUnit.Minutes,
      ),

      //== Health & Wellness ==//
      Habit(
        name: 'Drink Water',
        type: HabitType.DoneBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.local_drink,
        targetValue: 8, // 8 glasses
        unit: HabitUnit.Count,
      ),
      Habit(
        name: 'Eat a Healthy Meal',
        type: HabitType.DoneBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.restaurant,
        targetValue: 3, // 3 healthy meals
        unit: HabitUnit.Count,
      ),
      Habit(
        name: 'Get 8 Hours of Sleep',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.bedtime,
        targetValue: 8,
        unit: HabitUnit.Hours,
      ),
      Habit(
        name: 'Take Vitamins',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.medication,
        targetValue: 1,
        unit: HabitUnit.Count,
      ),

      //== Mindfulness & Mental Health ==//
      Habit(
        name: 'Meditate',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.spa,
        targetValue: 10,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Practice Gratitude',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.sentiment_satisfied_alt,
        targetValue: 5,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Journaling',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.edit,
        targetValue: 10,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Digital Detox before Bed',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.mobile_off,
        targetValue: 60, // 60 minutes before bed
        unit: HabitUnit.Minutes,
      ),

      //== Personal Growth & Productivity ==//
      Habit(
        name: 'Read Books',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.book,
        targetValue: 20,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Learn a New Skill',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.school,
        targetValue: 30,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Plan Your Day',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.event_note,
        targetValue: 1,
        unit: HabitUnit.Count,
      ),
      Habit(
        name: 'Tidy Up Space',
        type: HabitType.SuccessBased,
        frequency: HabitFrequency.Daily,
        icon: Icons.cleaning_services,
        targetValue: 15,
        unit: HabitUnit.Minutes,
      ),
      Habit(
        name: 'Review Weekly Goals',
        type: HabitType.DoneBased,
        frequency: HabitFrequency.Weekdays,
        icon: Icons.check_circle_outline,
        targetValue: 1,
        unit: HabitUnit.Count,
      ),
    ];
  }

  void _completeOnboarding() async {
    // Save selected habits
    for (final habit in _selectedHabits) {
      await StorageService.save(habit);
    }

    // Save onboarding data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_quest', _selectedQuest ?? '');
    await prefs.setStringList('onboarding_areas', _selectedAreas);
    await prefs.setString('onboarding_energy', _energyLevel ?? '');
    await prefs.setString('onboarding_time_preference', _timePreference ?? '');
    await prefs.setString('onboarding_time_availability', _timeAvailability ?? '');
    await prefs.setString('onboarding_habit_preference', _habitPreference ?? '');
    await prefs.setString('onboarding_starting_approach', _startingApproach ?? '');
    await prefs.setBool('onboarding_wants_reminders', _wantsReminders);
    await prefs.setString('onboarding_reminder_time', _reminderTime ?? '');
    await prefs.setString('onboarding_selected_theme', _selectedTheme ?? 'Default');

    // Call completion callback
    if (widget.onComplete != null) {
      widget.onComplete!(_selectedTheme);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(toggleTheme: () {}, isDarkMode: _selectedTheme == 'dark'),
        ),
      );
    }
  }

  List<String> _getGoalOptions(String area) {
    switch (area) {
      case 'health':
        return ['💧 Drink More Water', '🍎 Eat Healthier Meals', '🏋️ Exercise Regularly', '😴 Improve Sleep Quality', '🚶‍♀️ Walk More Steps'];
      case 'growth':
        return [
          '📖 Read More Books/Articles',
          '🗣️ Learn a New Language',
          '🎨 Practice a Creative Hobby',
          '🧘 Meditate or Practice Mindfulness',
          '✍️ Journal Regularly',
        ];
      case 'career':
        return ['📚 Learn New Skills', '🎯 Set Daily Goals', '📝 Organize Tasks', '🤝 Network More', '💡 Practice Creativity'];
      case 'finances':
        return ['💰 Track Expenses', '🏦 Save Money Daily', '📊 Review Budget', '💳 Reduce Spending', '📈 Learn About Investing'];
      case 'mental':
        return ['🧘 Meditate Daily', '📝 Practice Gratitude', '🌱 Positive Affirmations', '🎵 Listen to Calming Music', '🌿 Spend Time in Nature'];
      case 'home':
        return ['🧹 Tidy Up Daily', '🍽️ Clean After Meals', '📦 Declutter Regularly', '🌱 Care for Plants', '🛏️ Make Bed Daily'];
      default:
        return [];
    }
  }

  String _getAreaTitle(String area) {
    switch (area) {
      case 'health':
        return '🏃 Health & Fitness';
      case 'career':
        return '💼 Career & Work';
      case 'growth':
        return '📚 Personal Growth';
      case 'finances':
        return '💰 Finances';
      case 'mental':
        return '😊 Mental Well-being';
      case 'home':
        return '🏡 Home & Organization';
      default:
        return area;
    }
  }
}
