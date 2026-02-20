// lib/src/screens/performance_screen.dart
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PerformanceScreen extends StatefulWidget {
  final String childId;

  const PerformanceScreen({
    super.key,
    required this.childId,
  });

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  Map<String, dynamic>? performanceData;
  bool isLoading = true;
  String? errorMessage;

  String viewType = 'monthly';
  int selectedYear = DateTime.now().year;
  int? selectedMonth;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now().month;
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      performanceData = null;
    });

    try {
      final result = await ApiService().getPerformanceChart(
        childId: widget.childId,
        type: viewType,
        year: selectedYear,
        month: viewType == 'monthly' ? selectedMonth! : 1,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (result is Map<String, dynamic> && result['data'] != null) {
          performanceData = result;
        } else {
          errorMessage = "Invalid response format";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load performance data: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text(
          "My Learning Progress",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterRow(),
              const SizedBox(height: 24),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                )
              else if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchPerformanceData,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                const Text(
                  "Performance Trend",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPerformanceChartSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _compactDropdown(
          label: "View",
          value: viewType,
          items: const ['monthly', 'yearly'],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              viewType = val;
              if (val == 'monthly' && selectedMonth == null) {
                selectedMonth = DateTime.now().month;
              }
            });
            _fetchPerformanceData();
          },
        ),
        _compactDropdown(
          label: "Year",
          value: selectedYear.toString(),
          items: List.generate(
            5,
            (i) => (DateTime.now().year - 2 + i).toString(),
          ),
          onChanged: (val) {
            if (val == null) return;
            setState(() => selectedYear = int.parse(val));
            _fetchPerformanceData();
          },
        ),
        if (viewType == 'monthly')
          _compactDropdown(
            label: "Month",
            value: selectedMonth?.toString() ?? '',
            items: List.generate(12, (i) => (i + 1).toString()),
            itemDisplay: (v) => months[int.parse(v) - 1].substring(0, 3),
            onChanged: (val) {
              if (val == null) return;
              setState(() => selectedMonth = int.parse(val));
              _fetchPerformanceData();
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.gray200),
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

  /// Decides chart type from API data: attempt-based vs label/score.
  Widget _buildPerformanceChartSection() {
    final dataList = performanceData?['data'] as List<dynamic>? ?? [];
    if (dataList.isEmpty) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "No performance data available",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    final first =
        dataList.isNotEmpty ? dataList.first as Map : <String, dynamic>{};
    final isAttemptBased =
        first.containsKey('attempt') && first.containsKey('accuracy');

    if (isAttemptBased) {
      return _buildAttemptsPerformanceChart(
        dataList.cast<Map<String, dynamic>>(),
      );
    }

    return _buildLabelScoreChart(dataList);
  }

  /// API format: attempt, totalQuestions, correctAnswers, accuracy.
  Widget _buildAttemptsPerformanceChart(List<Map<String, dynamic>> rawData) {
    final labels = <String>[];
    final accuracies = <double>[];
    final correctAnswers = <String>[];
    final totalQuestions = <int>[];

    for (final item in rawData) {
      final attemptStr = item['attempt']?.toString() ?? '';
      labels.add(attemptStr.replaceAll('Attempt ', ''));
      accuracies.add((item['accuracy'] as num?)?.toDouble() ?? 0.0);
      correctAnswers.add(item['correctAnswers']?.toString() ?? '0');
      totalQuestions.add((item['totalQuestions'] as num?)?.toInt() ?? 0);
    }

    const double minVisibleHeight = 2.0;
    final realMax = accuracies.isNotEmpty ? accuracies.reduce(math.max) : 0.0;
    final displayMax =
        math.max(realMax * 1.25, 25.0).ceilToDouble().clamp(25.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
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
                            : (isPass
                                ? AppColors.success
                                : AppColors.primaryTeal),
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
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
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
                      interval:
                          displayMax > 50 ? 25 : (displayMax > 25 ? 10 : 5),
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
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final total = groupIndex < totalQuestions.length
                          ? totalQuestions[groupIndex]
                          : 0;
                      final correct = groupIndex < correctAnswers.length
                          ? correctAnswers[groupIndex]
                          : '0';
                      final acc = groupIndex < accuracies.length
                          ? accuracies[groupIndex]
                          : 0.0;
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textDark),
        ),
      ],
    );
  }

  /// Fallback for label/score style data (e.g. label, score).
  double _getValue(dynamic item) {
    if (item is! Map) return 0.0;
    final keys = ['score', 'percentage', 'marks', 'value'];
    for (final k in keys) {
      final v = item[k];
      if (v != null) return (v as num).toDouble();
    }
    return 0.0;
  }

  Widget _buildLabelScoreChart(List<dynamic> rawData) {
    final labels = <String>[];
    final values = <double>[];

    for (final item in rawData) {
      labels.add((item is Map ? item['label'] : null)?.toString() ?? '');
      values.add(_getValue(item));
    }

    final maxY = values.isEmpty
        ? 100.0
        : (values.reduce(math.max) * 1.2).clamp(10.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
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
          Text(
            viewType == 'monthly'
                ? "Performance - ${months[selectedMonth! - 1]} $selectedYear"
                : "Performance - $selectedYear",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: values.every((v) => v == 0)
                ? const Center(
                    child: Text(
                      "No performance recorded this period",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      minY: 0,
                      groupsSpace: 8,
                      barGroups: List.generate(labels.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              color: AppColors.primaryTeal,
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
                              if (idx < 0 || idx >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[idx],
                                  style: const TextStyle(fontSize: 10),
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
                            interval: maxY > 50 ? 25 : 10,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 50 ? 25 : 10,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final labelStr = labels[groupIndex];
                            final val = rod.toY.toStringAsFixed(0);
                            return BarTooltipItem(
                              '$labelStr\n$val%',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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
