import 'package:flutter/material.dart';
import 'package:flux/core/widgets/keyboard_aware_widget.dart';
import 'package:flux/core/widgets/focusable_button.dart';
import 'package:flux/core/widgets/keyboard_shortcuts_dialog.dart';

/// Example of how to implement keyboard navigation in other screens
/// This shows the pattern for integrating keyboard shortcuts into any screen
class ExampleScreenWithKeyboardNavigation extends StatefulWidget {
  const ExampleScreenWithKeyboardNavigation({super.key});

  @override
  _ExampleScreenWithKeyboardNavigationState createState() => _ExampleScreenWithKeyboardNavigationState();
}

class _ExampleScreenWithKeyboardNavigationState extends State<ExampleScreenWithKeyboardNavigation> {
  late ScrollController _scrollController;
  List<FocusNode> _focusableNodes = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusableNodes = List.generate(10, (index) => FocusNode());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var node in _focusableNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved!')),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted!')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleClose() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareWidget(
      scrollController: _scrollController,
      onClose: _handleClose,
      onShowKeyboardShortcuts: () => showKeyboardShortcutsDialog(context),
      focusableNodes: _focusableNodes,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Example Screen'),
          actions: [
            FocusableIconButton(
              icon: Icon(Icons.keyboard),
              onPressed: () => showKeyboardShortcutsDialog(context),
              tooltip: 'Keyboard Shortcuts (F1)',
              focusNode: _focusableNodes[0],
            ),
            FocusableIconButton(
              icon: Icon(Icons.close),
              onPressed: _handleClose,
              tooltip: 'Close (Ctrl+W)',
              focusNode: _focusableNodes[1],
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Example Content',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              
              // Example form with focusable elements
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Example',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      
                      // Focusable text fields
                      TextField(
                        focusNode: _focusableNodes[2],
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your name',
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      TextField(
                        focusNode: _focusableNodes[3],
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Focusable buttons
                      Row(
                        children: [
                          FocusableButton(
                            onPressed: _handleSave,
                            focusNode: _focusableNodes[4],
                            child: Text('Save'),
                          ),
                          SizedBox(width: 8),
                          FocusableButton(
                            onPressed: _handleDelete,
                            focusNode: _focusableNodes[5],
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Example list with focusable items
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'List Example',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          focusNode: _focusableNodes[6 + index],
                          title: Text('Item ${index + 1}'),
                          subtitle: Text('Description for item ${index + 1}'),
                          trailing: FocusableIconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Edit item ${index + 1}')),
                              );
                            },
                            tooltip: 'Edit item ${index + 1}',
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Selected item ${index + 1}')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 100), // Extra space for scrolling demo
            ],
          ),
        ),
        floatingActionButton: FocusableButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Floating action button pressed!')),
            );
          },
          focusNode: _focusableNodes.length > 10 ? _focusableNodes[10] : null,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Example of how to add custom keyboard shortcuts for a specific screen
class CustomKeyboardShortcutsExample extends StatefulWidget {
  const CustomKeyboardShortcutsExample({super.key});

  @override
  _CustomKeyboardShortcutsExampleState createState() => _CustomKeyboardShortcutsExampleState();
}

class _CustomKeyboardShortcutsExampleState extends State<CustomKeyboardShortcutsExample> {
  late ScrollController _scrollController;
  List<FocusNode> _focusableNodes = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusableNodes = List.generate(5, (index) => FocusNode());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var node in _focusableNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleCustomAction1() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Custom action 1 triggered!')),
    );
  }

  void _handleCustomAction2() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Custom action 2 triggered!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareWidget(
      scrollController: _scrollController,
      onClose: () => Navigator.pop(context),
      onShowKeyboardShortcuts: () => showKeyboardShortcutsDialog(context),
      // Add custom shortcuts for this screen
      onAddHabit: _handleCustomAction1, // Reuse 'A' key for custom action
      onOpenSettings: _handleCustomAction2, // Reuse 'S' key for custom action
      focusableNodes: _focusableNodes,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Custom Shortcuts Example'),
          actions: [
            FocusableIconButton(
              icon: Icon(Icons.keyboard),
              onPressed: () => showKeyboardShortcutsDialog(context),
              tooltip: 'Keyboard Shortcuts (F1)',
              focusNode: _focusableNodes[0],
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Keyboard Shortcuts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Shortcuts:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      
                      _buildShortcutItem('A', 'Trigger Custom Action 1'),
                      _buildShortcutItem('S', 'Trigger Custom Action 2'),
                      _buildShortcutItem('F1', 'Show all shortcuts'),
                      _buildShortcutItem('Ctrl+W', 'Close screen'),
                      _buildShortcutItem('↑/↓', 'Scroll content'),
                      _buildShortcutItem('Tab', 'Navigate between elements'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              Row(
                children: [
                  FocusableButton(
                    onPressed: _handleCustomAction1,
                    focusNode: _focusableNodes[1],
                    child: Text('Custom Action 1 (A)'),
                  ),
                  SizedBox(width: 8),
                  FocusableButton(
                    onPressed: _handleCustomAction2,
                    focusNode: _focusableNodes[2],
                    child: Text('Custom Action 2 (S)'),
                  ),
                ],
              ),
              
              SizedBox(height: 100), // Extra space for scrolling demo
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutItem(String key, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}