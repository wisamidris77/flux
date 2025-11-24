import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flux/core/services/backup_service.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/core/services/data_service.dart';
import 'package:intl/intl.dart';

class BackupImportScreen extends StatefulWidget {
  const BackupImportScreen({super.key});
  
  @override
  _BackupImportScreenState createState() => _BackupImportScreenState();
}

class _BackupImportScreenState extends State<BackupImportScreen> {
  List<Habit> _habits = [];
  List<BackupFileInfo> _availableBackups = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final habits = await StorageService.loadAll();
      final backups = await BackupService.listAvailableBackups();
      
      setState(() {
        _habits = habits;
        _availableBackups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Backup & Import',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildSummaryCard(),
              SizedBox(height: 24),
              _buildActionButtons(),
              SizedBox(height: 24),
              _buildBackupsList(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final totalEntries = _habits.fold(0, (sum, h) => sum + h.entries.length);
    final avgSuccessRate = _habits.isEmpty ? 0.0 : 
        _habits.fold(0.0, (sum, h) => sum + h.successRate) / _habits.length;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.backup,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ready for backup or import',
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
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.list_alt,
                  label: 'Habits',
                  value: '${_habits.length}',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timeline,
                  label: 'Entries',
                  value: '$totalEntries',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Avg Success',
                  value: '${avgSuccessRate.toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.backup,
                label: 'Create JSON Backup',
                onPressed: _createBackup,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.file_upload,
                label: 'Import JSON Backup',
                onPressed: _importBackup,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.storage,
                label: 'Create DB Backup',
                onPressed: _createDatabaseBackup,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.storage_rounded,
                label: 'Import DB Backup',
                onPressed: _importDatabaseBackup,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBackupsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              'Available Backups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: _loadData,
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh backup list',
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_availableBackups.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.folder_open,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'No backups found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create your first backup to see it here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _availableBackups.length,
            itemBuilder: (context, index) {
              return _buildBackupItem(_availableBackups[index]);
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildBackupItem(BackupFileInfo backup) {
    final dateFormatter = DateFormat('MMM d, yyyy • HH:mm');
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backup.isValid 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: backup.isValid ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Icon(
            backup.isValid ? Icons.check_circle : Icons.error,
            color: backup.isValid ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          backup.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              dateFormatter.format(backup.modified),
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${backup.habitCount} habits',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
                SizedBox(width: 8),
                Text(
                  backup.formattedSize,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (backup.version != null) ...[
                  SizedBox(width: 8),
                  Text(
                    'v${backup.version}',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: backup.isValid
            ? IconButton(
                onPressed: () => _restoreBackup(backup),
                icon: Icon(Icons.restore, color: Colors.green),
                tooltip: 'Restore this backup',
              )
            : Icon(Icons.warning, color: Colors.red),
      ),
    );
  }
  
  Future<void> _createBackup() async {
    try {
      setState(() => _isLoading = true);
      
      final success = await BackupService.createBackup(_habits);
      
      setState(() => _isLoading = false);
      
      if (success) {
        _showSuccessSnackBar('Backup created successfully');
        _loadData(); // Refresh the list of backups
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to create backup: $e');
    }
  }
  
  Future<void> _createDatabaseBackup() async {
    try {
      setState(() => _isLoading = true);
      
      final success = await BackupService.createDatabaseBackup();
      
      setState(() => _isLoading = false);
      
      if (success) {
        _showSuccessSnackBar('Database backup created successfully');
        _loadData(); // Refresh the list of backups
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to create database backup: $e');
    }
  }
  
  Future<void> _importBackup() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await BackupService.importBackup();
      
      setState(() => _isLoading = false);
      
      if (result.success) {
        _showSuccessSnackBar('Backup imported successfully');
        _loadData(); // Refresh data
        
        if (result.habits.isNotEmpty) {
          _showImportSummaryDialog(result);
        }
      } else {
        _showErrorSnackBar('Import failed: ${result.errors.join(', ')}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to import backup: $e');
    }
  }
  
  Future<void> _importDatabaseBackup() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await BackupService.importDatabaseBackup();
      
      setState(() => _isLoading = false);
      
      if (result.success) {
        _showSuccessSnackBar('Database backup imported successfully');
        _loadData(); // Refresh data
      } else {
        _showErrorSnackBar('Database import failed: ${result.errors.join(', ')}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to import database backup: $e');
    }
  }
  
  Future<void> _restoreBackup(BackupFileInfo backup) async {
    try {
      _showLoadingDialog('Loading backup...');
      
      final validation = await BackupService.validateBackup(backup.path);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (!validation.isValid) {
        _showErrorSnackBar('Invalid backup file: ${validation.issues.join(', ')}');
        return;
      }
      
      // Load and import the backup
      final file = await File(backup.path).readAsString();
      final importResult = await DataService.importFromJson(file);
      
      if (importResult.hasHabits) {
        _showImportDialog(ImportBackupResult(
          success: true,
          habits: importResult.habits,
          errors: importResult.errors,
          fileName: backup.name,
        ));
      } else {
        _showErrorSnackBar('No valid habits found in backup');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Failed to restore backup: $e');
    }
  }
  
  void _showImportDialog(ImportBackupResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Found ${result.habits.length} habits in "${result.fileName}".'),
            SizedBox(height: 16),
            Text('How would you like to import them?'),
            if (result.hasErrors) ...[
              SizedBox(height: 16),
              Text(
                'Warnings:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              ...result.errors.map((error) => Text(
                '• $error',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performImport(result.habits, MergeStrategy.Replace);
            },
            child: Text('Replace All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performImport(result.habits, MergeStrategy.MergeEntries);
            },
            child: Text('Merge'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performImport(result.habits, MergeStrategy.Rename);
            },
            child: Text('Add New'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performImport(List<Habit> importedHabits, MergeStrategy strategy) async {
    try {
      _showLoadingDialog('Importing habits...');
      
      final result = await BackupService.restoreBackup(_habits, importedHabits, strategy);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result.success) {
        _showSuccessSnackBar(
          'Import completed! Added: ${result.added.length}, Updated: ${result.updated.length}'
        );
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar(result.error ?? 'Import failed');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Import failed: $e');
    }
  }
  
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showImportSummaryDialog(ImportBackupResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully imported ${result.habits.length} habits',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              if (result.errors.isNotEmpty) ...[
                Text(
                  'Warnings:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                SizedBox(height: 8),
                ...result.errors.map((e) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('• $e', style: TextStyle(fontSize: 14)),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
} 