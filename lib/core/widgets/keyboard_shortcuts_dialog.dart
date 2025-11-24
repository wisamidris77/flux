import 'package:flutter/material.dart';

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 8),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutSection(
              context,
              'Navigation',
              [
                _ShortcutItem('Alt + ←', 'Previous page'),
                _ShortcutItem('Alt + →', 'Next page'),
                _ShortcutItem('F1', 'Show keyboard shortcuts'),
                _ShortcutItem('F11', 'Toggle fullscreen'),
                _ShortcutItem('Ctrl + W', 'Close popup/app'),
              ],
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              context,
              'Scrolling',
              [
                _ShortcutItem('↑/↓', 'Scroll up/down'),
                _ShortcutItem('Page Up/Down', 'Scroll page up/down'),
                _ShortcutItem('Space', 'Scroll down (Shift + Space for up)'),
                _ShortcutItem('Home', 'Scroll to top'),
                _ShortcutItem('End', 'Scroll to bottom'),
              ],
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              context,
              'Zoom',
              [
                _ShortcutItem('Ctrl + +', 'Zoom in'),
                _ShortcutItem('Ctrl + -', 'Zoom out'),
                _ShortcutItem('Ctrl + 0', 'Reset zoom'),
              ],
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              context,
              'Focus & Selection',
              [
                _ShortcutItem('Tab', 'Next focusable element'),
                _ShortcutItem('Shift + Tab', 'Previous focusable element'),
                _ShortcutItem('Enter', 'Activate focused element'),
              ],
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              context,
              'Quick Actions',
              [
                _ShortcutItem('A', 'Add habit'),
                _ShortcutItem('S', 'Settings'),
                _ShortcutItem('D', 'Analytics dashboard'),
                _ShortcutItem('F', 'Filter by category'),
                _ShortcutItem('B', 'Bulk edit'),
                _ShortcutItem('I', 'Backup & import'),
                _ShortcutItem('Y', 'Year in review'),
                _ShortcutItem('P', 'Points & rewards'),
                _ShortcutItem('R', 'Achievements'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildShortcutSection(
    BuildContext context,
    String title,
    List<_ShortcutItem> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 8),
        ...shortcuts.map((shortcut) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
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
                  shortcut.key,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  shortcut.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _ShortcutItem {
  final String key;
  final String description;

  _ShortcutItem(this.key, this.description);
}

// Helper function to show the keyboard shortcuts dialog
void showKeyboardShortcutsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => KeyboardShortcutsDialog(),
  );
}