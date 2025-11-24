import 'package:flutter/material.dart';
import 'package:flux/core/services/keyboard_service.dart';

class KeyboardAwareWidget extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onClose;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onAddHabit;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenAnalytics;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onFilterByCategory;
  final VoidCallback? onBulkEdit;
  final VoidCallback? onBackup;
  final VoidCallback? onYearReview;
  final VoidCallback? onAchievements;
  final VoidCallback? onPoints;
  final VoidCallback? onShowKeyboardShortcuts;
  final List<FocusNode> focusableNodes;

  const KeyboardAwareWidget({
    super.key,
    required this.child,
    this.scrollController,
    this.onPreviousPage,
    this.onNextPage,
    this.onClose,
    this.onToggleFullscreen,
    this.onAddHabit,
    this.onOpenSettings,
    this.onOpenAnalytics,
    this.onToggleArchive,
    this.onFilterByCategory,
    this.onBulkEdit,
    this.onBackup,
    this.onYearReview,
    this.onAchievements,
    this.onPoints,
    this.onShowKeyboardShortcuts,
    this.focusableNodes = const [],
  });

  @override
  State<KeyboardAwareWidget> createState() => _KeyboardAwareWidgetState();
}

class _KeyboardAwareWidgetState extends State<KeyboardAwareWidget> {
  final KeyboardService _keyboardService = KeyboardService();

  @override
  void initState() {
    super.initState();
    _initializeKeyboardService();
  }

  void _initializeKeyboardService() {
    _keyboardService.initialize(
      mainScrollController: widget.scrollController,
      onPreviousPage: widget.onPreviousPage,
      onNextPage: widget.onNextPage,
      onClose: widget.onClose,
      onToggleFullscreen: widget.onToggleFullscreen,
      onAddHabit: widget.onAddHabit,
      onOpenSettings: widget.onOpenSettings,
      onOpenAnalytics: widget.onOpenAnalytics,
      onToggleArchive: widget.onToggleArchive,
      onFilterByCategory: widget.onFilterByCategory,
      onBulkEdit: widget.onBulkEdit,
      onBackup: widget.onBackup,
      onYearReview: widget.onYearReview,
      onAchievements: widget.onAchievements,
      onPoints: widget.onPoints,
      onShowKeyboardShortcuts: widget.onShowKeyboardShortcuts,
    );

    if (widget.focusableNodes.isNotEmpty) {
      _keyboardService.setFocusableNodes(widget.focusableNodes);
    }
  }

  @override
  void didUpdateWidget(KeyboardAwareWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update scroll controller if it changed
    if (oldWidget.scrollController != widget.scrollController) {
      _keyboardService.setScrollController(widget.scrollController);
    }
    
    // Update focusable nodes if they changed
    if (oldWidget.focusableNodes != widget.focusableNodes) {
      _keyboardService.setFocusableNodes(widget.focusableNodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        final handled = _keyboardService.handleKeyEvent(event);
        if (handled) {
          // Prevent the event from propagating further
          return;
        }
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _keyboardService.dispose();
    super.dispose();
  }
}