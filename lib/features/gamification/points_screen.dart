import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/core/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  _PointsScreenState createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> with TickerProviderStateMixin {
  List<Habit> _habits = [];
  int _totalPoints = 0;
  int _currentLevel = 1;
  int _pointsToNextLevel = 100;
  double _levelProgress = 0.0;
  List<Achievement> _achievements = [];
  List<ShopItem> _shopItems = [];
  List<String> _unlockedThemes = [];
  List<String> _purchasedItems = [];
  bool _loading = true;
  bool _isWeekend = false;
  late AnimationController _pointsAnimationController;
  late Animation<double> _pointsAnimation;
  
  @override
  void initState() {
    super.initState();
    _pointsAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pointsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pointsAnimationController, curve: Curves.easeOutBack),
    );
    _loadData();
  }
  
  @override
  void dispose() {
    _pointsAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    _habits = await StorageService.loadAll();
    await _loadPurchasedItems();
    await _loadUnlockedThemes();
    _checkWeekend();
    _calculatePoints();
    _generateAchievements();
    _generateShopItems();
    setState(() => _loading = false);
    _pointsAnimationController.forward();
  }
  
  Future<void> _loadPurchasedItems() async {
    final prefs = await SharedPreferences.getInstance();
    _purchasedItems = prefs.getStringList('purchased_items') ?? [];
  }
  
  Future<void> _loadUnlockedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedThemes = prefs.getStringList('unlocked_themes') ?? ['Default'];
  }
  
  Future<void> _savePurchasedItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('purchased_items', _purchasedItems);
  }
  
  Future<void> _saveUnlockedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_themes', _unlockedThemes);
  }
  
  void _checkWeekend() {
    final now = DateTime.now();
    _isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }
  
  void _calculatePoints() {
    _totalPoints = 0;
    
    for (final habit in _habits) {
      // Points for entries
      _totalPoints += habit.entries.length * 10;
      
      // Bonus points for streaks
      if (habit.currentStreak >= 7) _totalPoints += 50;
      if (habit.currentStreak >= 30) _totalPoints += 200;
      if (habit.currentStreak >= 100) _totalPoints += 500;
      
      // Points for success rate
      if (habit.successRate >= 80) _totalPoints += 100;
      if (habit.successRate >= 95) _totalPoints += 200;
    }
    
    // Calculate level
    _currentLevel = (_totalPoints / 1000).floor() + 1;
    _pointsToNextLevel = (_currentLevel * 1000) - _totalPoints;
    _levelProgress = (_totalPoints % 1000) / 1000.0;
  }
  
  void _generateAchievements() {
    _achievements = [
      Achievement(
        title: 'First Steps',
        description: 'Complete your first habit entry',
        icon: Icons.baby_changing_station,
        points: 10,
        isUnlocked: _habits.any((h) => h.entries.isNotEmpty),
        category: 'Beginner',
      ),
      Achievement(
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        points: 50,
        isUnlocked: _habits.any((h) => h.currentStreak >= 7),
        category: 'Streaks',
      ),
      Achievement(
        title: 'Month Master',
        description: 'Maintain a 30-day streak',
        icon: Icons.emoji_events,
        points: 200,
        isUnlocked: _habits.any((h) => h.currentStreak >= 30),
        category: 'Streaks',
      ),
      Achievement(
        title: 'Perfectionist',
        description: 'Achieve 95% success rate',
        icon: Icons.star,
        points: 200,
        isUnlocked: _habits.any((h) => h.successRate >= 95),
        category: 'Performance',
      ),
      Achievement(
        title: 'Habit Collector',
        description: 'Create 10 different habits',
        icon: Icons.collections,
        points: 100,
        isUnlocked: _habits.length >= 10,
        category: 'Collection',
      ),
      Achievement(
        title: 'Century Club',
        description: 'Maintain a 100-day streak',
        icon: Icons.military_tech,
        points: 500,
        isUnlocked: _habits.any((h) => h.currentStreak >= 100),
        category: 'Legendary',
      ),
    ];
  }
  
  void _generateShopItems() {
    _shopItems = [];
    
    // Add theme items from ThemeService
    final availableThemes = ThemeService.themePresets.keys.toList();
    for (final themeName in availableThemes) {
      if (!_unlockedThemes.contains(themeName)) {
        final basePrice = 300;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: '$themeName Theme',
          description: 'Unlock the beautiful $themeName color scheme',
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: Icons.palette,
          type: ShopItemType.Theme,
          themeKey: themeName,
        ));
      }
    }
    
    // Add Premium Themes
    final premiumThemes = [
      {'name': 'Cosmic', 'price': 500, 'desc': 'Deep space inspired colors'},
      {'name': 'Forest', 'price': 450, 'desc': 'Natural green forest theme'},
      {'name': 'Ocean', 'price': 450, 'desc': 'Calming ocean blue tones'},
      {'name': 'Sunset', 'price': 550, 'desc': 'Warm sunset gradient'},
      {'name': 'Midnight', 'price': 600, 'desc': 'Premium dark theme'},
      {'name': 'Cherry Blossom', 'price': 650, 'desc': 'Soft pink sakura theme'},
      {'name': 'Golden Hour', 'price': 700, 'desc': 'Luxurious gold accents'},
      {'name': 'Aurora', 'price': 800, 'desc': 'Northern lights inspired'},
    ];
    
    for (final theme in premiumThemes) {
      if (!_unlockedThemes.contains(theme['name'])) {
        final basePrice = theme['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: '${theme['name']} Theme',
          description: theme['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: Icons.auto_awesome,
          type: ShopItemType.Theme,
          themeKey: theme['name'] as String,
        ));
      }
    }
    
    // Icon Packs
    final iconPacks = [
      {'name': 'Emoji Pack', 'price': 200, 'desc': '50+ colorful emoji icons', 'icon': Icons.emoji_emotions},
      {'name': 'Sport Icons', 'price': 250, 'desc': 'Athletic and fitness icons', 'icon': Icons.sports_soccer},
      {'name': 'Nature Pack', 'price': 300, 'desc': 'Beautiful nature-themed icons', 'icon': Icons.eco},
      {'name': 'Tech Icons', 'price': 350, 'desc': 'Modern technology icons', 'icon': Icons.computer},
      {'name': 'Food & Drink', 'price': 280, 'desc': 'Culinary and beverage icons', 'icon': Icons.restaurant},
      {'name': 'Travel Pack', 'price': 400, 'desc': 'Adventure and travel icons', 'icon': Icons.flight},
      {'name': 'Minimalist Set', 'price': 320, 'desc': 'Clean, simple line icons', 'icon': Icons.minimize},
      {'name': 'Vintage Collection', 'price': 380, 'desc': 'Retro-style icons', 'icon': Icons.history},
    ];
    
    for (final pack in iconPacks) {
      if (!_purchasedItems.contains(pack['name'])) {
        final basePrice = pack['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: pack['name'] as String,
          description: pack['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: pack['icon'] as IconData,
          type: ShopItemType.Icons,
        ));
      }
    }
    
    // Premium Features
    final premiumFeatures = [
      {'name': 'Advanced Analytics', 'price': 1000, 'desc': 'Detailed insights and reports', 'icon': Icons.analytics},
      {'name': 'Custom Widgets', 'price': 800, 'desc': 'Personalized home screen widgets', 'icon': Icons.widgets},
      {'name': 'Habit Templates', 'price': 600, 'desc': 'Pre-made habit categories', 'icon': Icons.library_add},
      {'name': 'Export Data', 'price': 500, 'desc': 'Export habits to CSV/PDF', 'icon': Icons.file_download},
      {'name': 'Goal Tracking', 'price': 750, 'desc': 'Advanced goal management', 'icon': Icons.flag},
      {'name': 'Habit Streaks+', 'price': 450, 'desc': 'Enhanced streak tracking', 'icon': Icons.local_fire_department},
      {'name': 'Smart Reminders', 'price': 550, 'desc': 'AI-powered notifications', 'icon': Icons.smart_toy},
      {'name': 'Mood Tracking', 'price': 650, 'desc': 'Track daily mood patterns', 'icon': Icons.mood},
      {'name': 'Habit Groups', 'price': 400, 'desc': 'Organize habits into groups', 'icon': Icons.group_work},
      {'name': 'Time Tracking', 'price': 700, 'desc': 'Detailed time analytics', 'icon': Icons.timer},
    ];
    
    for (final feature in premiumFeatures) {
      if (!_purchasedItems.contains(feature['name'])) {
        final basePrice = feature['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: feature['name'] as String,
          description: feature['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: feature['icon'] as IconData,
          type: ShopItemType.Feature,
        ));
      }
    }
    
    // Animations & Effects
    final animations = [
      {'name': 'Particle Effects', 'price': 300, 'desc': 'Beautiful floating particles', 'icon': Icons.auto_awesome},
      {'name': 'Confetti Celebration', 'price': 250, 'desc': 'Confetti for achievements', 'icon': Icons.celebration},
      {'name': 'Smooth Transitions', 'price': 400, 'desc': 'Premium page transitions', 'icon': Icons.animation},
      {'name': 'Glow Effects', 'price': 350, 'desc': 'Glowing button animations', 'icon': Icons.lightbulb},
      {'name': 'Ripple Animations', 'price': 200, 'desc': 'Water ripple effects', 'icon': Icons.water},
      {'name': 'Bounce Effects', 'price': 180, 'desc': 'Playful bounce animations', 'icon': Icons.sports_basketball},
    ];
    
    for (final anim in animations) {
      if (!_purchasedItems.contains(anim['name'])) {
        final basePrice = anim['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: anim['name'] as String,
          description: anim['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: anim['icon'] as IconData,
          type: ShopItemType.Cosmetic,
        ));
      }
    }
    
    // Sounds & Audio
    final sounds = [
      {'name': 'Nature Sounds', 'price': 150, 'desc': 'Calming forest and ocean sounds', 'icon': Icons.nature_people},
      {'name': 'Success Chimes', 'price': 120, 'desc': 'Satisfying completion sounds', 'icon': Icons.music_note},
      {'name': 'Zen Collection', 'price': 200, 'desc': 'Meditation bell sounds', 'icon': Icons.self_improvement},
      {'name': 'Retro Beeps', 'price': 100, 'desc': 'Classic arcade game sounds', 'icon': Icons.gamepad},
      {'name': 'Piano Notes', 'price': 180, 'desc': 'Beautiful piano melodies', 'icon': Icons.piano},
      {'name': 'Space Ambient', 'price': 220, 'desc': 'Futuristic space sounds', 'icon': Icons.rocket},
    ];
    
    for (final sound in sounds) {
      if (!_purchasedItems.contains(sound['name'])) {
        final basePrice = sound['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: sound['name'] as String,
          description: sound['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: sound['icon'] as IconData,
          type: ShopItemType.Cosmetic,
        ));
      }
    }
    
    // Backgrounds & Wallpapers
    final backgrounds = [
      {'name': 'Mountain Views', 'price': 250, 'desc': 'Stunning mountain landscapes', 'icon': Icons.landscape},
      {'name': 'City Lights', 'price': 300, 'desc': 'Urban nighttime skylines', 'icon': Icons.location_city},
      {'name': 'Abstract Art', 'price': 350, 'desc': 'Modern abstract patterns', 'icon': Icons.brush},
      {'name': 'Geometric Patterns', 'price': 280, 'desc': 'Clean geometric designs', 'icon': Icons.category},
      {'name': 'Watercolor Dreams', 'price': 320, 'desc': 'Soft watercolor textures', 'icon': Icons.water_drop},
      {'name': 'Galaxy Collection', 'price': 400, 'desc': 'Deep space and nebulas', 'icon': Icons.star},
    ];
    
    for (final bg in backgrounds) {
      if (!_purchasedItems.contains(bg['name'])) {
        final basePrice = bg['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: bg['name'] as String,
          description: bg['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: bg['icon'] as IconData,
          type: ShopItemType.Cosmetic,
        ));
      }
    }
    
    // Special Collections
    final special = [
      {'name': 'Motivational Quotes Pro', 'price': 300, 'desc': '500+ inspiring daily quotes', 'icon': Icons.format_quote},
      {'name': 'Statistics Boost', 'price': 450, 'desc': 'Enhanced progress tracking', 'icon': Icons.trending_up},
      {'name': 'Habit Chains', 'price': 350, 'desc': 'Visual habit chain tracking', 'icon': Icons.link},
      {'name': 'Daily Challenges', 'price': 500, 'desc': 'Fun daily habit challenges', 'icon': Icons.emoji_events},
      {'name': 'Focus Mode', 'price': 400, 'desc': 'Distraction-free interface', 'icon': Icons.center_focus_strong},
      {'name': 'Dark Mode Pro', 'price': 250, 'desc': 'Enhanced dark theme options', 'icon': Icons.dark_mode},
      {'name': 'Habit Journal', 'price': 350, 'desc': 'Detailed habit journaling', 'icon': Icons.book},
      {'name': 'Progress Photos', 'price': 300, 'desc': 'Track visual progress with photos', 'icon': Icons.camera_alt},
    ];
    
    for (final item in special) {
      if (!_purchasedItems.contains(item['name'])) {
        final basePrice = item['price'] as int;
        final discountedPrice = _isWeekend ? (basePrice * 0.8).round() : basePrice;
        
        _shopItems.add(ShopItem(
          title: item['name'] as String,
          description: item['desc'] as String,
          cost: discountedPrice,
          originalCost: _isWeekend ? basePrice : null,
          icon: item['icon'] as IconData,
          type: ShopItemType.Feature,
        ));
      }
    }
    
    // Sort items by price (cheapest first)
    _shopItems.sort((a, b) => a.cost.compareTo(b.cost));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Points & Shop',
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
              _buildPointsCard(),
              SizedBox(height: 16),
              _buildLevelCard(),
              SizedBox(height: 16),
              _buildAchievementsSection(),
              SizedBox(height: 16),
              _buildShopItemsSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPointsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFA500),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pointsAnimation,
              builder: (context, child) {
                return Text(
                  '${(_totalPoints * _pointsAnimation.value).toInt()}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(
              'Total Points',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Habits', _habits.length.toString(), Icons.list),
                _buildStatItem('Entries', _habits.fold(0, (sum, h) => sum + h.entries.length).toString(), Icons.check_circle),
                _buildStatItem('Best Streak', _habits.isEmpty ? '0' : _habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b).toString(), Icons.local_fire_department),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLevelCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $_currentLevel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$_pointsToNextLevel points to next level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _levelProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              '${(_levelProgress * 100).toInt()}% to Level ${_currentLevel + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAchievementsSection() {
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = _achievements.where((a) => !a.isUnlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        if (unlockedAchievements.isNotEmpty) ...[
          Text(
            'Unlocked (${unlockedAchievements.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          ...unlockedAchievements.map((achievement) => _buildAchievementCard(achievement, true)),
          SizedBox(height: 16),
        ],
        if (lockedAchievements.isNotEmpty) ...[
          Text(
            'Locked (${lockedAchievements.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          ...lockedAchievements.map((achievement) => _buildAchievementCard(achievement, false)),
        ],
      ],
    );
  }
  
  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Card(
      elevation: isUnlocked ? 4 : 2,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 24,
            ),
          ),
          title: Text(
            achievement.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.description,
                style: TextStyle(
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${achievement.points} points',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber[700],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: isUnlocked
              ? Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.lock, color: Colors.grey),
        ),
      ),
    );
  }
  
  Widget _buildShopItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...(_shopItems.map((item) => _buildShopItemCard(item))),
      ],
    );
  }
  
  Widget _buildShopItemCard(ShopItem item) {
    final canAfford = _totalPoints >= item.cost;
    final isWeekendDiscount = item.originalCost != null;
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: isWeekendDiscount ? BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 2),
        ) : null,
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: canAfford
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: canAfford
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? null : Colors.grey,
                  ),
                ),
              ),
              if (isWeekendDiscount) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '20% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: TextStyle(
                  color: canAfford ? null : Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  if (isWeekendDiscount) ...[
                    Text(
                      '${item.originalCost}',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 4),
                  ],
                  Text(
                    '${item.cost} points',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber[700],
                    ),
                  ),
                  if (_isWeekend && !isWeekendDiscount) ...[
                    SizedBox(width: 8),
                    Text(
                      '🎉 Weekend Special!',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: canAfford ? () => _purchaseItem(item) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              canAfford ? 'Buy' : 'Locked',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
  
  void _purchaseItem(ShopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item.title}'),
        content: Text('Are you sure you want to spend ${item.cost} points on this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _totalPoints -= item.cost;
                _calculatePoints();
              });
              
              // Handle different item types
              if (item.type == ShopItemType.Theme && item.themeKey != null) {
                _unlockedThemes.add(item.themeKey!);
                await _saveUnlockedThemes();
              } else {
                _purchasedItems.add(item.title);
                await _savePurchasedItems();
              }
              
              // Regenerate shop items to remove purchased item
              _generateShopItems();
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} purchased successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Purchase'),
          ),
        ],
      ),
    );
  }
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final int points;
  final bool isUnlocked;
  final String category;
  
  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.isUnlocked,
    required this.category,
  });
}

class ShopItem {
  final String title;
  final String description;
  final int cost;
  final int? originalCost;
  final IconData icon;
  final ShopItemType type;
  final String? themeKey;
  
  ShopItem({
    required this.title,
    required this.description,
    required this.cost,
    this.originalCost,
    required this.icon,
    required this.type,
    this.themeKey,
  });
}

enum ShopItemType { Theme, Icons, Feature, Cosmetic } 