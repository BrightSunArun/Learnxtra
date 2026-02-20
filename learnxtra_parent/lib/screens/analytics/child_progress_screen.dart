// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'dart:math' as math;

class ChildProgressScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildProgressScreen(
      {super.key, required this.childId, required this.childName});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  final ApiService api = Get.find<ApiService>();

  Map<String, dynamic>? progressData;
  bool isLoading = true;
  String? errorMessage;

  String chartType = 'yearly';
  int selectedYear = DateTime.now().year;
  int? selectedMonth;

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parentId');

      if (parentId == null || parentId.isEmpty) {
        setState(() {
          errorMessage = "Parent ID not found. Please log in again.";
          isLoading = false;
        });
        return;
      }

      final monthToSend =
          chartType == 'monthly' ? (selectedMonth ?? DateTime.now().month) : 1;

      final response = await api.getParentPerformance(
        parentId: parentId,
        childId: widget.childId,
        year: selectedYear,
        month: monthToSend,
        type: chartType,
      );

      if (!mounted) return;

      setState(() {
        progressData = response;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _reloadProgress() {
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Text(
          "${widget.childName}'s Learning Progress",
          style: const TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.white,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartControls(),
                      const SizedBox(height: 24),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (errorMessage != null)
                        Center(
                          child: Text(
                            "Error: $errorMessage",
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 32),
                        const Text(
                          "Performance Trend",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildPerformanceChartSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _compactDropdown(
          label: "View",
          value: chartType,
          items: const ['yearly', 'monthly'],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              chartType = val;
              if (val == 'monthly' && selectedMonth == null) {
                selectedMonth = DateTime.now().month;
              }
            });
            _reloadProgress();
          },
        ),
        _compactDropdown(
          label: "Year",
          value: selectedYear.toString(),
          items:
              List.generate(5, (i) => (DateTime.now().year - 2 + i).toString()),
          onChanged: (val) {
            if (val == null) return;
            setState(() => selectedYear = int.parse(val));
            _reloadProgress();
          },
        ),
        if (chartType == 'monthly')
          _compactDropdown(
            label: "Month",
            value: selectedMonth?.toString() ?? '',
            items: List.generate(12, (i) => (i + 1).toString()),
            itemDisplay: (v) => months[int.parse(v) - 1],
            onChanged: (val) {
              if (val == null) return;
              setState(() => selectedMonth = int.parse(val));
              _reloadProgress();
            },
          ),
      ],
    );
  }

  Widget _compactDropdown({
    required String label,
    required String value,
    required List<String> items,
    String Function(String)? itemDisplay,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    itemDisplay?.call(item) ?? item,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChartSection() {
    final dataList = progressData?['data'] as List<dynamic>? ?? [];
    if (dataList.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            "No performance data available",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final first = dataList.isNotEmpty ? dataList.first as Map : <String, dynamic>{};
    final isAttemptBased = first.containsKey('attempt') && first.containsKey('accuracy');

    if (isAttemptBased) {
      return _buildAttemptsPerformanceChart(dataList.cast<Map<String, dynamic>>());
    }

    final isPerSubject = first.containsKey('subject');
    if (isPerSubject) {
      return Column(
        children: dataList.map((subjectData) {
          final subjectName = (subjectData['subject'] ?? 'Subject').toString();
          final subjectDataPoints =
              (subjectData['data'] as List?)?.cast<Map>() ?? [];

          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: _buildSingleSubjectChart(subjectDataPoints, subjectName),
          );
        }).toList(),
      );
    }

    return _buildSingleSubjectChart(
        dataList.cast<Map>(), "Overall Performance");
  }

  /// Builds performance chart from API response: attempt, totalQuestions, correctAnswers, accuracy.
  Widget _buildAttemptsPerformanceChart(List<Map<String, dynamic>> rawData) {
    final labels = <String>[];
    final accuracies = <double>[];
    final correctAnswers = <String>[];
    final totalQuestions = <int>[];

    for (final item in rawData) {
      labels.add(item['attempt']?.toString() ?? '');
      accuracies.add((item['accuracy'] as num?)?.toDouble() ?? 0.0);
      correctAnswers.add(item['correctAnswers']?.toString() ?? '0');
      totalQuestions.add((item['totalQuestions'] as num?)?.toInt() ?? 0);
    }

    const double minVisibleHeight = 2.0;
    final realMax = accuracies.isNotEmpty ? accuracies.reduce(math.max) : 0.0;
    final displayMax = math.max(realMax * 1.25, 25.0).ceilToDouble().clamp(25.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quiz attempts",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Accuracy by attempt (correct / total)",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: displayMax,
                minY: 0,
                groupsSpace: 14,
                barGroups: List.generate(labels.length, (i) {
                  final val = accuracies[i];
                  final displayVal = val == 0 ? minVisibleHeight : val;
                  final isPass = val >= 60;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: displayVal,
                        color: val == 0
                            ? AppColors.gray300
                            : (isPass ? AppColors.success : AppColors.primaryTeal),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: displayMax > 50 ? 25 : (displayMax > 25 ? 10 : 5),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: displayMax > 50 ? 25 : 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.gray800,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final total = groupIndex < totalQuestions.length ? totalQuestions[groupIndex] : 0;
                      final correct = groupIndex < correctAnswers.length ? correctAnswers[groupIndex] : '0';
                      final acc = groupIndex < accuracies.length ? accuracies[groupIndex] : 0.0;
                      return BarTooltipItem(
                        '${labels[groupIndex]}\n$correct / $total correct\n${acc.toStringAsFixed(0)}% accuracy',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (rawData.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendItem(AppColors.primaryTeal, "Below 60%"),
                _legendItem(AppColors.success, "60% or above"),
                _legendItem(AppColors.gray300, "No correct answers"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildSingleSubjectChart(List<Map> rawData, String subjectName) {
    final labels = <String>[];
    final scores = <double>[];

    for (final item in rawData) {
      labels.add(item['label']?.toString() ?? '');
      scores.add((item['score'] as num?)?.toDouble() ?? 0.0);
    }

    const double minVisibleHeight = 5.0;
    final realMax = scores.isNotEmpty ? scores.reduce(math.max) : 0.0;
    final displayMax = math.max(realMax * 1.25, 20.0).ceilToDouble();

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$subjectName Performance",
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: displayMax,
                minY: 0,
                groupsSpace: 12,
                barGroups: List.generate(labels.length, (i) {
                  final val = scores[i];
                  final displayVal = val == 0 ? minVisibleHeight : val;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: displayVal,
                        color: val == 0
                            ? AppColors.primaryTeal.withOpacity(0.35)
                            : AppColors.primaryTeal,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: chartType == 'yearly' ? 1 : 4,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval:
                          displayMax > 50 ? 20 : (displayMax > 20 ? 10 : 5),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black.withOpacity(0.75),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = labels[groupIndex];
                      final val = scores[groupIndex];
                      final displayLabel = chartType == 'yearly'
                          ? months[int.tryParse(label) ?? 1 - 1]
                          : 'Day $label';
                      return BarTooltipItem(
                        '$displayLabel\n${val.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
