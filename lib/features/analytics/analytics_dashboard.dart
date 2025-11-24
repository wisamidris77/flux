import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class AnalyticsDashboard extends StatefulWidget {
  final List<Habit> habits;
  final bool showBackButton;
  
  const AnalyticsDashboard({super.key, required this.habits, this.showBackButton = true});
  
  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = 'Last 30 Days';
  DateTime? _startDate;
  DateTime? _endDate;
  
  final List<String> _timeRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Year',
    'All Time',
    'Custom Range'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setDateRange() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 'Last 7 Days':
        _startDate = now.subtract(Duration(days: 7));
        _endDate = now;
        break;
      case 'Last 30 Days':
        _startDate = now.subtract(Duration(days: 30));
        _endDate = now;
        break;
      case 'Last 90 Days':
        _startDate = now.subtract(Duration(days: 90));
        _endDate = now;
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'All Time':
        _startDate = null;
        _endDate = null;
        break;
      case 'Custom Range':
        // Will be handled by date picker
        break;
    }
  }

  List<Habit> get _filteredHabits {
    if (_startDate == null || _endDate == null) return widget.habits;
    
    return widget.habits.map((habit) {
      final filteredEntries = habit.entries.where((entry) {
        return entry.date.isAfter(_startDate!.subtract(Duration(days: 1))) &&
               entry.date.isBefore(_endDate!.add(Duration(days: 1)));
      }).toList();
      
      // Create a copy of the habit with filtered entries
      final filteredHabit = Habit(
        name: habit.name,
        type: habit.type,
        displayMode: habit.displayMode,
        icon: habit.icon,
        color: habit.color,
        isArchived: habit.isArchived,
        notes: habit.notes,
        reminderHour: habit.reminderHour,
        reminderMinute: habit.reminderMinute,
        hasReminder: habit.hasReminder,
        category: habit.category,
        frequency: habit.frequency,
        customDays: habit.customDays,
        targetFrequency: habit.targetFrequency,
        targetValue: habit.targetValue,
        unit: habit.unit,
        customUnit: habit.customUnit,
        entries: filteredEntries,
      );
      
      return filteredHabit;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.timeline), text: 'Trends'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Distribution'),
            Tab(icon: Icon(Icons.grid_view), text: 'Heatmap'),
            Tab(icon: Icon(Icons.analytics), text: 'Insights'),
          ],
        ),
        automaticallyImplyLeading: widget.showBackButton,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
                if (value == 'Custom Range') {
                  _showDateRangePicker();
                } else {
                  _setDateRange();
                }
              });
            },
            itemBuilder: (context) => _timeRanges.map((range) =>
              PopupMenuItem(
                value: range,
                child: Text(range),
              ),
            ).toList(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendsTab(),
          _buildDistributionTab(),
          _buildHeatmapTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeInfo(),
          SizedBox(height: 16),
          _buildSuccessRateTrendChart(),
          SizedBox(height: 24),
          _buildValueTrendChart(),
          SizedBox(height: 24),
          _buildStreakTrendChart(),
        ],
      ),
    );
  }

  Widget _buildDistributionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHabitTypeDistribution(),
          SizedBox(height: 24),
          _buildCategoryDistribution(),
          SizedBox(height: 24),
          _buildFrequencyDistribution(),
        ],
      ),
    );
  }

  Widget _buildHeatmapTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Heatmap',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildActivityHeatmap(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCorrelationAnalysis(),
          SizedBox(height: 24),
          _buildPerformanceInsights(),
          SizedBox(height: 24),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildDateRangeInfo() {
    String rangeText = _selectedTimeRange;
    if (_startDate != null && _endDate != null) {
      final formatter = DateFormat('MMM d, yyyy');
      rangeText += '\n${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
    }
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                rangeText,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateTrendChart() {
    final chartData = _generateSuccessRateData();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Success Rate Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  title: AxisTitle(text: 'Success Rate (%)'),
                ),
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: chartData.map((habitData) => 
                  LineSeries<ChartDataPoint, DateTime>(
                    name: habitData.habitName,
                    dataSource: habitData.points,
                    xValueMapper: (point, _) => point.date,
                    yValueMapper: (point, _) => point.value,
                    color: habitData.color,
                    markerSettings: MarkerSettings(isVisible: true),
                  )
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTrendChart() {
    final chartData = _generateValueTrendData();
    
    if (chartData.isEmpty) return SizedBox();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Value Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM d'),
                  intervalType: DateTimeIntervalType.days,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Values'),
                ),
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: chartData.map((habitData) => 
                  ColumnSeries<ChartDataPoint, DateTime>(
                    name: habitData.habitName,
                    dataSource: habitData.points,
                    xValueMapper: (point, _) => point.date,
                    yValueMapper: (point, _) => point.value,
                    color: habitData.color,
                  )
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakTrendChart() {
    final chartData = _generateStreakData();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Streaks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Days'),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  BarSeries<StreakDataPoint, String>(
                    dataSource: chartData,
                    xValueMapper: (point, _) => point.habitName,
                    yValueMapper: (point, _) => point.streak,
                    pointColorMapper: (point, _) => point.color,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitTypeDistribution() {
    final typeData = _generateHabitTypeData();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Type Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  PieSeries<PieDataPoint, String>(
                    dataSource: typeData,
                    xValueMapper: (point, _) => point.label,
                    yValueMapper: (point, _) => point.value,
                    pointColorMapper: (point, _) => point.color,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final categoryData = _generateCategoryData();
    
    if (categoryData.isEmpty) return SizedBox();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  DoughnutSeries<PieDataPoint, String>(
                    dataSource: categoryData,
                    xValueMapper: (point, _) => point.label,
                    yValueMapper: (point, _) => point.value,
                    pointColorMapper: (point, _) => point.color,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyDistribution() {
    final frequencyData = _generateFrequencyData();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequency Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Number of Habits'),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  ColumnSeries<FrequencyDataPoint, String>(
                    dataSource: frequencyData,
                    xValueMapper: (point, _) => point.frequency,
                    yValueMapper: (point, _) => point.count,
                    color: Theme.of(context).colorScheme.primary,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming Soon: Activity Heatmap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'GitHub-style activity heatmap\nwill be implemented here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationAnalysis() {
    final correlations = _calculateCorrelations();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Correlations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (correlations.isEmpty)
              Text(
                'Need more habits and data to analyze correlations',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...correlations.map((correlation) => _buildCorrelationItem(correlation)),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationItem(CorrelationData correlation) {
    final isPositive = correlation.coefficient > 0;
    final strength = correlation.coefficient.abs();
    String strengthText = '';
    
    if (strength > 0.7) {
      strengthText = 'Strong';
    } else if (strength > 0.4) strengthText = 'Moderate';
    else strengthText = 'Weak';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${correlation.habit1} & ${correlation.habit2}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${(correlation.coefficient * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '$strengthText ${isPositive ? 'positive' : 'negative'} correlation',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    final insights = _generatePerformanceInsights();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(InsightData insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(insight.icon, color: insight.color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...recommendations.map((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(RecommendationData recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation.text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // Data generation methods
  List<HabitTrendData> _generateSuccessRateData() {
    return _filteredHabits.take(5).map((habit) {
      List<ChartDataPoint> points = [];
      
      // Group entries by day and calculate daily success rate
      final groupedEntries = groupBy(habit.entries, (HabitEntry entry) => 
          DateTime(entry.date.year, entry.date.month, entry.date.day));
      
      groupedEntries.forEach((date, entries) {
        final positiveEntries = entries.where((e) => habit.isPositiveDay(e)).length;
        final successRate = (positiveEntries / entries.length) * 100;
        points.add(ChartDataPoint(date, successRate));
      });
      
      points.sort((a, b) => a.date.compareTo(b.date));
      
      return HabitTrendData(
        habitName: habit.formattedName,
        points: points,
        color: habit.color ?? Colors.blue,
      );
    }).toList();
  }

  List<HabitTrendData> _generateValueTrendData() {
    return _filteredHabits.where((h) => h.unit != HabitUnit.Count).take(3).map((habit) {
      List<ChartDataPoint> points = [];
      
      for (var entry in habit.entries) {
        if (entry.value != null) {
          points.add(ChartDataPoint(
            DateTime(entry.date.year, entry.date.month, entry.date.day),
            entry.value!,
          ));
        }
      }
      
      points.sort((a, b) => a.date.compareTo(b.date));
      
      return HabitTrendData(
        habitName: habit.formattedName,
        points: points,
        color: habit.color ?? Colors.green,
      );
    }).toList();
  }

  List<StreakDataPoint> _generateStreakData() {
    return _filteredHabits.map((habit) => StreakDataPoint(
      habitName: habit.formattedName,
      streak: habit.currentStreak,
      color: habit.color ?? Colors.orange,
    )).toList();
  }

  List<PieDataPoint> _generateHabitTypeData() {
    final Map<HabitType, int> typeCount = {};
    
    for (var habit in _filteredHabits) {
      typeCount[habit.type] = (typeCount[habit.type] ?? 0) + 1;
    }
    
    return typeCount.entries.map((entry) {
      String label;
      Color color;
      
      switch (entry.key) {
        case HabitType.SuccessBased:
          label = 'Achieve';
          color = Colors.green;
          break;
        case HabitType.FailBased:
          label = 'Avoid';
          color = Colors.red;
          break;
        case HabitType.DoneBased:
          label = 'Check';
          color = Colors.blue;
          break;
      }
      
      return PieDataPoint(label, entry.value.toDouble(), color);
    }).toList();
  }

  List<PieDataPoint> _generateCategoryData() {
    final Map<String, int> categoryCount = {};
    
    for (var habit in _filteredHabits) {
      final category = habit.category ?? 'Uncategorized';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.teal];
    int colorIndex = 0;
    
    return categoryCount.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieDataPoint(entry.key, entry.value.toDouble(), color);
    }).toList();
  }

  List<FrequencyDataPoint> _generateFrequencyData() {
    final Map<HabitFrequency, int> frequencyCount = {};
    
    for (var habit in _filteredHabits) {
      frequencyCount[habit.frequency] = (frequencyCount[habit.frequency] ?? 0) + 1;
    }
    
    return frequencyCount.entries.map((entry) {
      String label = formatPascalCase(entry.key.toString().split('.').last);
      return FrequencyDataPoint(label, entry.value);
    }).toList();
  }

  List<CorrelationData> _calculateCorrelations() {
    List<CorrelationData> correlations = [];
    
    if (_filteredHabits.length < 2) return correlations;
    
    for (int i = 0; i < _filteredHabits.length; i++) {
      for (int j = i + 1; j < _filteredHabits.length; j++) {
        final habit1 = _filteredHabits[i];
        final habit2 = _filteredHabits[j];
        
        // Simple correlation calculation based on success patterns
        final correlation = _calculateSimpleCorrelation(habit1, habit2);
        
        if (correlation.abs() > 0.3) { // Only show meaningful correlations
          correlations.add(CorrelationData(
            habit1: habit1.formattedName,
            habit2: habit2.formattedName,
            coefficient: correlation,
          ));
        }
      }
    }
    
    return correlations;
  }

  double _calculateSimpleCorrelation(Habit habit1, Habit habit2) {
    // Get common dates
    final dates1 = habit1.entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    final dates2 = habit2.entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    final commonDates = dates1.intersection(dates2).toList();
    
    if (commonDates.length < 5) return 0.0; // Need at least 5 common days
    
    int bothSuccess = 0;
    int bothFail = 0;
    int oneSuccessOneFail = 0;
    
    for (var date in commonDates) {
      final entry1 = habit1.entries.firstWhereOrNull((e) => 
          DateTime(e.date.year, e.date.month, e.date.day) == date);
      final entry2 = habit2.entries.firstWhereOrNull((e) => 
          DateTime(e.date.year, e.date.month, e.date.day) == date);
      
      if (entry1 != null && entry2 != null) {
        final success1 = habit1.isPositiveDay(entry1);
        final success2 = habit2.isPositiveDay(entry2);
        
        if (success1 && success2) {
          bothSuccess++;
        } else if (!success1 && !success2) {
          bothFail++;
        } else {
          oneSuccessOneFail++;
        }
      }
    }
    
    // Simple correlation: (agreements - disagreements) / total
    final agreements = bothSuccess + bothFail;
    final total = commonDates.length;
    
    return (agreements - oneSuccessOneFail) / total;
  }

  List<InsightData> _generatePerformanceInsights() {
    List<InsightData> insights = [];
    
    if (_filteredHabits.isEmpty) return insights;
    
    // Best performing habit
    final bestHabit = _filteredHabits.reduce((a, b) => 
        a.successRate > b.successRate ? a : b);
    insights.add(InsightData(
      title: 'Best Performer',
      description: '${bestHabit.formattedName} has ${bestHabit.successRate.toStringAsFixed(1)}% success rate',
      icon: Icons.star,
      color: Colors.green,
    ));
    
    // Most consistent habit (longest current streak)
    final mostConsistent = _filteredHabits.reduce((a, b) => 
        a.currentStreak > b.currentStreak ? a : b);
    if (mostConsistent.currentStreak > 0) {
      insights.add(InsightData(
        title: 'Most Consistent',
        description: '${mostConsistent.formattedName} has a ${mostConsistent.currentStreak}-day streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
      ));
    }
    
    // Most active day
    final entryDates = _filteredHabits
        .expand((h) => h.entries)
        .map((e) => e.date.weekday)
        .toList();
    
    if (entryDates.isNotEmpty) {
      final dayCount = <int, int>{};
      for (var day in entryDates) {
        dayCount[day] = (dayCount[day] ?? 0) + 1;
      }
      
      final mostActiveDay = dayCount.entries.reduce((a, b) => 
          a.value > b.value ? a : b);
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      insights.add(InsightData(
        title: 'Most Active Day',
        description: '${dayNames[mostActiveDay.key - 1]} with ${mostActiveDay.value} entries',
        icon: Icons.calendar_today,
        color: Colors.blue,
      ));
    }
    
    return insights;
  }

  List<RecommendationData> _generateRecommendations() {
    List<RecommendationData> recommendations = [];
    
    // Check for habits with low success rates
    final strugglingHabits = _filteredHabits.where((h) => h.successRate < 50 && h.entries.length > 5).toList();
    
    if (strugglingHabits.isNotEmpty) {
      recommendations.add(RecommendationData(
        'Consider reviewing ${strugglingHabits.first.formattedName} - try adjusting the target or frequency',
      ));
    }
    
    // Check for habits without recent entries
    final now = DateTime.now();
    final staleHabits = _filteredHabits.where((h) {
      if (h.entries.isEmpty) return true;
      final lastEntry = h.entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
      return now.difference(lastEntry).inDays > 7;
    }).toList();
    
    if (staleHabits.isNotEmpty) {
      recommendations.add(RecommendationData(
        'You haven\'t logged ${staleHabits.first.formattedName} recently - consider adding an entry',
      ));
    }
    
    // Suggest habit pairing based on correlations
    final correlations = _calculateCorrelations();
    final strongPositiveCorrelations = correlations.where((c) => c.coefficient > 0.5).toList();
    
    if (strongPositiveCorrelations.isNotEmpty) {
      final correlation = strongPositiveCorrelations.first;
      recommendations.add(RecommendationData(
        '${correlation.habit1} and ${correlation.habit2} work well together - consider doing them consecutively',
      ));
    }
    
    return recommendations;
  }
}

// Data classes
class HabitTrendData {
  final String habitName;
  final List<ChartDataPoint> points;
  final Color color;
  
  HabitTrendData({required this.habitName, required this.points, required this.color});
}

class ChartDataPoint {
  final DateTime date;
  final double value;
  
  ChartDataPoint(this.date, this.value);
}

class StreakDataPoint {
  final String habitName;
  final int streak;
  final Color color;
  
  StreakDataPoint({required this.habitName, required this.streak, required this.color});
}

class PieDataPoint {
  final String label;
  final double value;
  final Color color;
  
  PieDataPoint(this.label, this.value, this.color);
}

class FrequencyDataPoint {
  final String frequency;
  final int count;
  
  FrequencyDataPoint(this.frequency, this.count);
}

class CorrelationData {
  final String habit1;
  final String habit2;
  final double coefficient;
  
  CorrelationData({required this.habit1, required this.habit2, required this.coefficient});
}

class InsightData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  InsightData({required this.title, required this.description, required this.icon, required this.color});
}

class RecommendationData {
  final String text;
  
  RecommendationData(this.text);
} 