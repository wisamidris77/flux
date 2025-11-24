import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';

class BulkEditScreen extends StatefulWidget {
  final List<Habit> habits;
  
  const BulkEditScreen({
    super.key,
    required this.habits,
  });
  
  @override
  _BulkEditScreenState createState() => _BulkEditScreenState();
}

class _BulkEditScreenState extends State<BulkEditScreen> {
  final Set<String> _selectedHabitIds = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';
  String? _filterCategory;
  HabitType? _filterType;
  bool? _filterArchived;
  
  List<Habit> get _filteredHabits {
    return widget.habits.where((habit) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!habit.name.toLowerCase().contains(query) &&
            !(habit.notes?.toLowerCase().contains(query) ?? false) &&
            !(habit.category?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      // Category filter
      if (_filterCategory != null && habit.category != _filterCategory) {
        return false;
      }
      
      // Type filter
      if (_filterType != null && habit.type != _filterType) {
        return false;
      }
      
      // Archived filter
      if (_filterArchived != null && habit.isArchived != _filterArchived) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  List<String> get _availableCategories {
    final categories = widget.habits
        .map((h) => h.category)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedHabitIds.length} selected')
            : Text('Manage Habits'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
            PopupMenuButton<String>(
              onSelected: _handleBulkAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive),
                      SizedBox(width: 8),
                      Text('Archive Selected'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unarchive',
                  child: Row(
                    children: [
                      Icon(Icons.unarchive),
                      SizedBox(width: 8),
                      Text('Unarchive Selected'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'change_category',
                  child: Row(
                    children: [
                      Icon(Icons.category),
                      SizedBox(width: 8),
                      Text('Change Category'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pause',
                  child: Row(
                    children: [
                      Icon(Icons.pause),
                      SizedBox(width: 8),
                      Text('Pause Selected'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unpause',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Unpause Selected'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Selected', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: 'Bulk Edit',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search habits...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                
                SizedBox(height: 12),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category filter
                      if (_availableCategories.isNotEmpty)
                        FilterChip(
                          label: Text(_filterCategory ?? 'All Categories'),
                          selected: _filterCategory != null,
                          onSelected: (selected) => _showCategoryFilter(),
                        ),
                      
                      SizedBox(width: 8),
                      
                      // Type filter
                      FilterChip(
                        label: Text(_filterType?.toString().split('.').last ?? 'All Types'),
                        selected: _filterType != null,
                        onSelected: (selected) => _showTypeFilter(),
                      ),
                      
                      SizedBox(width: 8),
                      
                      // Archived filter
                      FilterChip(
                        label: Text(_filterArchived == null 
                            ? 'All' 
                            : (_filterArchived! ? 'Archived' : 'Active')),
                        selected: _filterArchived != null,
                        onSelected: (selected) => _showArchivedFilter(),
                      ),
                      
                      if (_filterCategory != null || _filterType != null || _filterArchived != null) ...[
                        SizedBox(width: 8),
                        ActionChip(
                          label: Text('Clear Filters'),
                          onPressed: _clearFilters,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard('Total', widget.habits.length.toString(), Icons.list),
                SizedBox(width: 8),
                _buildStatCard(
                  'Active', 
                  widget.habits.where((h) => !h.isArchived).length.toString(), 
                  Icons.play_arrow,
                ),
                SizedBox(width: 8),
                _buildStatCard(
                  'Archived', 
                  widget.habits.where((h) => h.isArchived).length.toString(), 
                  Icons.archive,
                ),
                SizedBox(width: 8),
                _buildStatCard(
                  'Due Today', 
                  widget.habits.where((h) => h.isDueToday() && !h.isArchived).length.toString(), 
                  Icons.today,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Habits list
          Expanded(
            child: _filteredHabits.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = _filteredHabits[index];
                      return _buildHabitItem(habit);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No habits found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHabitItem(Habit habit) {
    final isSelected = _selectedHabitIds.contains(habit.id);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleSelection(habit.id),
              )
            : Container(
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
            decoration: habit.isArchived ? TextDecoration.lineThrough : null,
            color: habit.isArchived ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit.category != null)
              Text(
                habit.category!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Row(
              children: [
                Text(
                  formatPascalCase(habit.type.toString().split('.').last),
                  style: TextStyle(fontSize: 12),
                ),
                if (habit.isArchived) ...[
                  Text(' • ', style: TextStyle(fontSize: 12)),
                  Text(
                    'Archived',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                if (habit.isPaused) ...[
                  Text(' • ', style: TextStyle(fontSize: 12)),
                  Text(
                    'Paused',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: _isSelectionMode
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${habit.currentStreak}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: habit.color ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'streak',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
        onTap: _isSelectionMode 
            ? () => _toggleSelection(habit.id)
            : null,
      ),
    );
  }
  
  void _toggleSelection(String habitId) {
    setState(() {
      if (_selectedHabitIds.contains(habitId)) {
        _selectedHabitIds.remove(habitId);
      } else {
        _selectedHabitIds.add(habitId);
      }
      
      if (_selectedHabitIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }
  
  void _selectAll() {
    setState(() {
      _selectedHabitIds.addAll(_filteredHabits.map((h) => h.id));
    });
  }
  
  void _clearSelection() {
    setState(() {
      _selectedHabitIds.clear();
      _isSelectionMode = false;
    });
  }
  
  void _clearFilters() {
    setState(() {
      _filterCategory = null;
      _filterType = null;
      _filterArchived = null;
    });
  }
  
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text('All Categories'),
                onTap: () {
                  setState(() => _filterCategory = null);
                  Navigator.pop(context);
                },
                selected: _filterCategory == null,
              ),
              ..._availableCategories.map((category) => ListTile(
                title: Text(category),
                onTap: () {
                  setState(() => _filterCategory = category);
                  Navigator.pop(context);
                },
                selected: _filterCategory == category,
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Type'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text('All Types'),
                onTap: () {
                  setState(() => _filterType = null);
                  Navigator.pop(context);
                },
                selected: _filterType == null,
              ),
              ...HabitType.values.map((type) => ListTile(
                title: Text(formatPascalCase(type.toString().split('.').last)),
                onTap: () {
                  setState(() => _filterType = type);
                  Navigator.pop(context);
                },
                selected: _filterType == type,
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showArchivedFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text('All'),
                onTap: () {
                  setState(() => _filterArchived = null);
                  Navigator.pop(context);
                },
                selected: _filterArchived == null,
              ),
              ListTile(
                title: Text('Active Only'),
                onTap: () {
                  setState(() => _filterArchived = false);
                  Navigator.pop(context);
                },
                selected: _filterArchived == false,
              ),
              ListTile(
                title: Text('Archived Only'),
                onTap: () {
                  setState(() => _filterArchived = true);
                  Navigator.pop(context);
                },
                selected: _filterArchived == true,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleBulkAction(String action) async {
    if (_selectedHabitIds.isEmpty) return;
    
    final selectedHabits = widget.habits
        .where((h) => _selectedHabitIds.contains(h.id))
        .toList();
    
    switch (action) {
      case 'archive':
        await _archiveHabits(selectedHabits, true);
        break;
      case 'unarchive':
        await _archiveHabits(selectedHabits, false);
        break;
      case 'pause':
        await _pauseHabits(selectedHabits, true);
        break;
      case 'unpause':
        await _pauseHabits(selectedHabits, false);
        break;
      case 'change_category':
        await _changeCategoryDialog(selectedHabits);
        break;
      case 'delete':
        await _deleteHabitsDialog(selectedHabits);
        break;
    }
  }
  
  Future<void> _archiveHabits(List<Habit> habits, bool archive) async {
    for (final habit in habits) {
      habit.isArchived = archive;
      await StorageService.save(habit);
    }
    
    _clearSelection();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${habits.length} habit${habits.length == 1 ? '' : 's'} ${archive ? 'archived' : 'unarchived'}',
        ),
      ),
    );
  }
  
  Future<void> _pauseHabits(List<Habit> habits, bool pause) async {
    final now = DateTime.now();
    
    for (final habit in habits) {
      habit.isPaused = pause;
      if (pause) {
        habit.pauseStartDate = now;
        habit.pauseEndDate = null; // Indefinite pause
      } else {
        habit.pauseStartDate = null;
        habit.pauseEndDate = null;
      }
      await StorageService.save(habit);
    }
    
    _clearSelection();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${habits.length} habit${habits.length == 1 ? '' : 's'} ${pause ? 'paused' : 'unpaused'}',
        ),
      ),
    );
  }
  
  Future<void> _changeCategoryDialog(List<Habit> habits) async {
    final controller = TextEditingController();
    String? selectedCategory;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select or enter a new category for ${habits.length} habit${habits.length == 1 ? '' : 's'}:'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Existing Categories',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Select category...'),
                ),
                ..._availableCategories.map((category) => 
                  DropdownMenuItem(value: category, child: Text(category))
                ),
              ],
              onChanged: (value) {
                selectedCategory = value;
                if (value != null) {
                  controller.text = value;
                }
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Or enter new category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Change'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      for (final habit in habits) {
        habit.category = result;
        await StorageService.save(habit);
      }
      
      _clearSelection();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${habits.length} habit${habits.length == 1 ? '' : 's'} moved to "$result"',
          ),
        ),
      );
    }
  }
  
  Future<void> _deleteHabitsDialog(List<Habit> habits) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Habits'),
        content: Text(
          'Are you sure you want to delete ${habits.length} habit${habits.length == 1 ? '' : 's'}? '
          'This action cannot be undone and will remove all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      for (final habit in habits) {
        await StorageService.delete(habit);
      }
      
      _clearSelection();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${habits.length} habit${habits.length == 1 ? '' : 's'} deleted',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 