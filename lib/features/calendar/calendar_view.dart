import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/features/habits/add_entry_dialog.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  final Habit habit;
  final Function() onRefresh;
  
  const CalendarView({super.key, required this.habit, required this.onRefresh});
  
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late final ValueNotifier<List<HabitEntry>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<HabitEntry>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _processHabitEntries();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _processHabitEntries() {
    Map<DateTime, List<HabitEntry>> events = {};
    
    for (var entry in widget.habit.entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (events[date] != null) {
        events[date]!.add(entry);
      } else {
        events[date] = [entry];
      }
    }
    
    setState(() {
      _events = events;
    });
  }

  List<HabitEntry> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Color _getColorForDay(DateTime day) {
    final entries = _getEventsForDay(day);
    if (entries.isEmpty) {
      // Check if this day should have an entry based on frequency
      if (_shouldHaveEntry(day)) {
        return Colors.red.withValues(alpha: 0.3); // Missed day
      }
      return Colors.transparent; // No entry expected
    }
    
    final entry = entries.first;
    if (entry.isSkipped) {
      return Colors.orange.withValues(alpha: 0.4); // Skipped
    }
    
    if (widget.habit.isPositiveDay(entry)) {
      return Colors.green.withValues(alpha: 0.6); // Success
    } else {
      return Colors.red.withValues(alpha: 0.6); // Failure
    }
  }

  bool _shouldHaveEntry(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDay = DateTime(day.year, day.month, day.day);
    
    // Don't mark future days as missed
    if (checkDay.isAfter(today)) return false;
    
    // Don't mark days before habit creation as missed
    if (widget.habit.entries.isNotEmpty) {
      final firstEntryDate = widget.habit.entries
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (checkDay.isBefore(firstEntryDate)) return false;
    }
    
    // Check if habit was due on this day based on frequency
    switch (widget.habit.frequency) {
      case HabitFrequency.Daily:
        return true;
      case HabitFrequency.Weekdays:
        return day.weekday <= 5; // Monday = 1, Friday = 5
      case HabitFrequency.Weekends:
        return day.weekday > 5; // Saturday = 6, Sunday = 7
      case HabitFrequency.CustomDays:
        final dayIndex = day.weekday % 7; // Convert to 0=Sunday format
        return widget.habit.customDays.contains(dayIndex);
      case HabitFrequency.XTimesPerWeek:
      case HabitFrequency.XTimesPerMonth:
        // For frequency-based habits, don't mark individual days as missed
        return false;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _showAddEntryForDay(DateTime day) {
    // Calculate day number based on first entry date or use current logic
    int dayNumber = 1;
    if (widget.habit.entries.isNotEmpty) {
      final firstEntryDate = widget.habit.entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      dayNumber = day.difference(DateTime(firstEntryDate.year, firstEntryDate.month, firstEntryDate.day)).inDays + 1;
      if (dayNumber <= 0) dayNumber = widget.habit.getNextDayNumber();
    }

    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: widget.habit,
        dayNumber: dayNumber,
        onSave: (entry) async {
          // Set the correct date for the entry
          entry.date = day;
          widget.habit.entries.add(entry);
          await StorageService.save(widget.habit);
          Navigator.of(context).pop();
          _processHabitEntries();
          widget.onRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLegend(),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TableCalendar<HabitEntry>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.blue[600]),
                  holidayTextStyle: TextStyle(color: Colors.red[600]),
                  defaultTextStyle: TextStyle(fontWeight: FontWeight.w500),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, false, false);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, true, false);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, false, true);
                  },
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildSelectedDayInfo(),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final color = _getColorForDay(day);
    final entries = _getEventsForDay(day);
    
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isToday 
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : isSelected 
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                color: isToday || isSelected ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (entries.isNotEmpty)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.green.withValues(alpha: 0.6), 'Success'),
                _buildLegendItem(Colors.red.withValues(alpha: 0.6), 'Failure'),
                _buildLegendItem(Colors.orange.withValues(alpha: 0.4), 'Skipped'),
                _buildLegendItem(Colors.red.withValues(alpha: 0.3), 'Missed'),
                _buildLegendItem(Colors.grey.withValues(alpha: 0.1), 'No Entry'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSelectedDayInfo() {
    if (_selectedDay == null) return SizedBox();
    
    final entries = _getEventsForDay(_selectedDay!);
    final dateFormatter = DateFormat('EEEE, MMM d, yyyy');
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateFormatter.format(_selectedDay!),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (entries.isEmpty && _selectedDay!.isBefore(DateTime.now().add(Duration(days: 1))))
                  ElevatedButton.icon(
                    onPressed: () => _showAddEntryForDay(_selectedDay!),
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add Entry'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                'No entries for this day',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...entries.map((entry) => _buildEntryInfo(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryInfo(HabitEntry entry) {
    final isPositive = widget.habit.isPositiveDay(entry);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isSkipped 
            ? Colors.orange.withValues(alpha: 0.1)
            : isPositive 
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.isSkipped 
              ? Colors.orange.withValues(alpha: 0.3)
              : isPositive 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.isSkipped 
                    ? Icons.skip_next
                    : isPositive 
                        ? Icons.check_circle
                        : Icons.cancel,
                color: entry.isSkipped 
                    ? Colors.orange
                    : isPositive 
                        ? Colors.green
                        : Colors.red,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.isSkipped 
                      ? 'Skipped Day'
                      : isPositive 
                          ? 'Success'
                          : 'Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: entry.isSkipped 
                        ? Colors.orange[800]
                        : isPositive 
                            ? Colors.green[800]
                            : Colors.red[800],
                  ),
                ),
              ),
              Text(
                'Day ${entry.dayNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (entry.value != null) ...[
            SizedBox(height: 4),
            Text(
              '${entry.value} ${entry.unit ?? widget.habit.getUnitDisplayName()}',
              style: TextStyle(fontSize: 14),
            ),
          ] else if (entry.count > 0) ...[
            SizedBox(height: 4),
            Text(
              'Count: ${entry.count}',
              style: TextStyle(fontSize: 14),
            ),
          ],
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              entry.notes!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
} 