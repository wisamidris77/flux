import 'package:flutter/material.dart';
import 'package:flux/core/services/keyboard_service.dart';
import 'package:flutter/services.dart';

class FocusableButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;
  final String? tooltip;
  final FocusNode? focusNode;

  const FocusableButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
    this.tooltip,
    this.focusNode,
  }) : super(key: key);

  @override
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  late FocusNode _focusNode;
  final KeyboardService _keyboardService = KeyboardService();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardService.addFocusableNode(_focusNode);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _keyboardService.removeFocusableNode(_focusNode);
    super.dispose();
  }

  void _handlePressed() {
    if (widget.enabled && widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _handlePressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          
          return Tooltip(
            message: widget.tooltip ?? '',
            child: ElevatedButton(
              onPressed: widget.enabled ? _handlePressed : null,
              style: widget.style?.copyWith(
                elevation: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.focused)) {
                    return 8.0;
                  }
                  return widget.style?.elevation?.resolve(states) ?? 2.0;
                }),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.focused)) {
                    return Theme.of(context).colorScheme.primary.withOpacity(0.1);
                  }
                  return widget.style?.backgroundColor?.resolve(states);
                }),
                side: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.focused)) {
                    return BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    );
                  }
                  return widget.style?.side?.resolve(states);
                }),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class FocusableIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool enabled;

  const FocusableIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.focusNode,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<FocusableIconButton> createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<FocusableIconButton> {
  late FocusNode _focusNode;
  final KeyboardService _keyboardService = KeyboardService();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardService.addFocusableNode(_focusNode);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _keyboardService.removeFocusableNode(_focusNode);
    super.dispose();
  }

  void _handlePressed() {
    if (widget.enabled && widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _handlePressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          
          return Tooltip(
            message: widget.tooltip ?? '',
            child: IconButton(
              onPressed: widget.enabled ? _handlePressed : null,
              icon: widget.icon,
              style: IconButton.styleFrom(
                backgroundColor: isFocused 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
                side: isFocused 
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}