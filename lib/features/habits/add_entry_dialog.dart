// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';

class AddEntryDialog extends StatefulWidget {
  final Habit habit;
  final int dayNumber;
  final Function(HabitEntry) onSave;

  const AddEntryDialog({super.key, required this.habit, required this.dayNumber, required this.onSave});

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> with TickerProviderStateMixin {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _skipReasonController = TextEditingController();

  bool _isDone = false;
  bool _isSkipped = false;
  int _sliderValue = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    // Initialize with target value if available
    if (widget.habit.targetValue != null) {
      _valueController.text = widget.habit.targetValue!.toString();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    _skipReasonController.dispose();
    super.dispose();
  }

  String get _getMainTitle {
    if (_isSkipped) return 'Skipping Day ${widget.dayNumber}';

    if (widget.habit.unit != HabitUnit.Count && widget.habit.targetValue != null) {
      switch (widget.habit.type) {
        case HabitType.FailBased:
          return 'Track Failure';
        case HabitType.SuccessBased:
          return 'Track Progress';
        case HabitType.DoneBased:
          return 'Mark as Done';
      }
    } else {
      switch (widget.habit.type) {
        case HabitType.FailBased:
          return 'Track Failure';
        case HabitType.SuccessBased:
          return 'Track Success';
        case HabitType.DoneBased:
          return 'Mark Completion';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      // padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isSkipped) ...[
                    SizedBox(height: 20),
                    _buildMainContent(),
                    if (widget.habit.targetValue != null && !_isSkipped) ...[SizedBox(height: 10), _buildTargetProgressIndicator()],
                    SizedBox(height: 10),
                    _buildNotesSection(),
                  ] else ...[
                    SizedBox(height: 20),
                    _buildSkipReasonSection(),
                  ],
                  SizedBox(height: 10),
                  _buildSkipSection(),
                  SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.habit.color?.withValues(alpha: 0.8) ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            widget.habit.color ?? Theme.of(context).colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(widget.habit.icon ?? Icons.star, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.habit.formattedName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(_getMainTitle, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isSkipped ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isSkipped ? Colors.orange.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(
        children: [
          Icon(_isSkipped ? Icons.skip_next : Icons.schedule, color: _isSkipped ? Colors.orange : Colors.grey, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skip this day?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isSkipped ? Colors.orange : null),
                ),
                SizedBox(height: 4),
                Text("Won't break your streak or affect statistics", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: _isSkipped,
            onChanged: (value) {
              setState(() {
                _isSkipped = value;
                if (value) {
                  _isDone = false;
                  _countController.clear();
                  _valueController.clear();
                  _notesController.clear();
                }
              });
            },
            activeThumbColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.habit.type == HabitType.DoneBased && widget.habit.unit == HabitUnit.Count) {
      return _buildDoneTypeInput();
    } else {
      return _buildValueInput();
    }
  }

  Widget _buildDoneTypeInput() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Did you complete this habit today?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _isDone,
                onChanged: (value) {
                  setState(() {
                    _isDone = value;
                  });
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 20),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isDone ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isDone ? Colors.green : Colors.red, width: 2),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isDone ? Icons.check_circle : Icons.cancel, color: _isDone ? Colors.green : Colors.red, size: 32),
                  SizedBox(width: 12),
                  Text(
                    _isDone ? 'Completed ✓' : 'Not Completed ✗',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDone ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueInput() {
    final hasTargetValue = widget.habit.targetValue != null;
    final unitName = widget.habit.getUnitDisplayName();

    return Container(
      padding: EdgeInsets.all(0),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).colorScheme.surface,
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTargetValue) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.track_changes, color: Theme.of(context).colorScheme.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Goal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),
                        ),
                        SizedBox(height: 4),
                        Text('${widget.habit.targetValue} $unitName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],

          if (widget.habit.unit == HabitUnit.Count) ...[
            // Text('Enter Count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            // SizedBox(height: 12),

            // Enhanced count input with stepper buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  // Stepper row with +/- buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: IconButton.filledTonal(
                          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () {
                            final currentValue = int.tryParse(_countController.text) ?? 0;
                            if (currentValue > 0) {
                              final newValue = currentValue - 1;
                              _countController.text = newValue.toString();
                              setState(() {
                                _sliderValue = newValue;
                              });
                            }
                          },
                          icon: Icon(Icons.remove, color: Theme.of(context).colorScheme.primary),
                          iconSize: 16,
                        ),
                      ),

                      SizedBox(width: 10),

                      // Count display and text field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: TextFormField(
                            controller: _countController,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: unitName,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final intValue = int.tryParse(value) ?? 0;
                              setState(() {
                                _sliderValue = intValue.clamp(0, 50);
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                      // Plus button
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: IconButton(
                          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () {
                            final currentValue = int.tryParse(_countController.text) ?? 0;
                            final newValue = currentValue + 1;
                            _countController.text = newValue.toString();
                            setState(() {
                              _sliderValue = newValue;
                            });
                          },
                          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                          iconSize: 16,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Quick increment buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 5,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickButton('+1', 1),
                        _buildQuickButton('+5', 5),
                        _buildQuickButton('+10', 10),
                        _buildQuickButton('Reset', -1), // Special case for reset
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // // Enhanced slider
            // Container(
            //   padding: EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.grey.withValues(alpha: 0.05),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Text('Quick Slider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            //           Text('${_sliderValue.toString()} $unitName',
            //                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
            //                               color: Theme.of(context).colorScheme.primary)),
            //         ],
            //       ),
            //       SizedBox(height: 8),
            //       SliderTheme(
            //         data: SliderTheme.of(context).copyWith(
            //           thumbColor: Theme.of(context).colorScheme.primary,
            //           activeTrackColor: Theme.of(context).colorScheme.primary,
            //           inactiveTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            //           overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            //           thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            //           trackHeight: 6,
            //         ),
            //         child: Slider(
            //           value: _sliderValue.toDouble(),
            //           min: 0,
            //           max: 50,
            //           divisions: 50,
            //           onChanged: (value) {
            //             setState(() {
            //               _sliderValue = value.round();
            //               _countController.text = _sliderValue.toString();
            //             });
            //           },
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ] else ...[
            Text('Enter Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.0',
                suffixText: unitName,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetProgressIndicator() {
    final targetValue = widget.habit.targetValue!;
    final currentValue = widget.habit.unit == HabitUnit.Count
        ? (int.tryParse(_countController.text) ?? 0).toDouble()
        : (double.tryParse(_valueController.text) ?? 0.0);

    final progress = (currentValue / targetValue).clamp(0.0, 1.0);
    final isOnTrack = widget.habit.type == HabitType.FailBased ? currentValue <= targetValue : currentValue >= targetValue;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnTrack
              ? [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)]
              : [Colors.orange.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnTrack ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: isOnTrack ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
                child: Icon(isOnTrack ? Icons.check_circle : Icons.warning, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Status',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getProgressText(isOnTrack, currentValue, targetValue),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isOnTrack ? Colors.green : Colors.orange, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(isOnTrack ? Colors.green : Colors.orange),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${currentValue.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)} ${widget.habit.getUnitDisplayName()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_add, color: Theme.of(context).colorScheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: widget.habit.type == HabitType.FailBased ? 'What triggered this? Any insights...' : 'How did it go? Any thoughts...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildSkipReasonSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Why are you skipping today?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange[800]),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _skipReasonController,
            decoration: InputDecoration(
              hintText: 'e.g., sick, traveling, planned rest day...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSkipped ? Colors.orange : (widget.habit.color ?? Theme.of(context).colorScheme.primary),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Text(_isSkipped ? 'Skip Day' : 'Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  String _getProgressText(bool isOnTrack, double current, double target) {
    switch (widget.habit.type) {
      case HabitType.FailBased:
        if (current <= target) {
          return 'Within limit ✓';
        } else {
          return 'Over limit by ${(current - target).toStringAsFixed(1)}';
        }
      case HabitType.SuccessBased:
        if (current >= target) {
          return 'Target reached! ✓';
        } else {
          return 'Need ${(target - current).toStringAsFixed(1)} more';
        }
      case HabitType.DoneBased:
        if (current >= target) {
          return 'Goal achieved! ✓';
        } else {
          return 'Progress towards goal';
        }
    }
  }

  Widget _buildQuickButton(String label, int value) {
    return Container(
      constraints: BoxConstraints(minWidth: 60),
      child: ElevatedButton(
        onPressed: () {
          if (value == -1) {
            // Reset button
            _countController.text = '0';
            setState(() {
              _sliderValue = 0;
            });
          } else {
            // Add value button
            final currentValue = int.tryParse(_countController.text) ?? 0;
            final newValue = currentValue + value;
            _countController.text = newValue.toString();
            setState(() {
              _sliderValue = newValue.clamp(0, 50);
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: value == -1 ? Colors.grey : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: value == -1 ? Colors.white : Theme.of(context).colorScheme.primary,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: Size(50, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _saveEntry() {
    if (_isSkipped) {
      // Create skipped entry with reason
      final entry = HabitEntry(
        date: DateTime.now(),
        count: 0,
        dayNumber: widget.dayNumber,
        isSkipped: true,
        notes: _skipReasonController.text.trim().isNotEmpty ? 'Skip reason: ${_skipReasonController.text.trim()}' : 'Skipped day',
      );
      widget.onSave(entry);
      return;
    }

    int count = 0;
    double? value;

    if (widget.habit.type == HabitType.DoneBased && widget.habit.unit == HabitUnit.Count) {
      count = _isDone ? 1 : 0;
    } else if (widget.habit.unit == HabitUnit.Count) {
      count = int.tryParse(_countController.text) ?? _sliderValue;
    } else {
      value = double.tryParse(_valueController.text);
      if (value != null) {
        count = value > 0 ? 1 : 0; // Set count based on whether value was entered
      }
    }

    final entry = HabitEntry(
      date: DateTime.now(),
      count: count,
      dayNumber: widget.dayNumber,
      value: value,
      unit: widget.habit.unit != HabitUnit.Count ? widget.habit.getUnitDisplayName() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      isSkipped: false,
    );

    widget.onSave(entry);
  }
}
