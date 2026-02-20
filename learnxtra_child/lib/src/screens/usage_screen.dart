// lib/screens/usage_screen.dart
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class UsageScreen extends StatefulWidget {
  final String childId;

  const UsageScreen({
    super.key,
    required this.childId,
  });

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  Map<String, dynamic>? usageData;
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
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      usageData = null;
    });

    try {
      final result = await ApiService().getUsageChart(
        childId: widget.childId,
        type: viewType,
        year: selectedYear,
        month: viewType == 'monthly' ? selectedMonth! : 1,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (result is Map<String, dynamic> && result['data'] != null) {
          usageData = result;
        } else {
          errorMessage = "Invalid response format";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load usage data: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text(
          "My Screen Usage",
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
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
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
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchUsageData,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                const Text(
                  "Usage Trend",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChartArea(),
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
            _fetchUsageData();
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
            _fetchUsageData();
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
              _fetchUsageData();
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

  Widget _buildChartArea() {
    if (usageData == null || usageData!['data'] == null) {
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
            "No usage data available",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    final List<dynamic> rawData = usageData!['data'];
    final labels = <String>[];
    final hours = <double>[];

    for (final item in rawData) {
      labels.add(item['label']?.toString() ?? '');
      hours.add((item['hours'] as num?)?.toDouble() ?? 0.0);
    }

    // API response: { childId, type, year, data: [ { label, hours } ] }
    const double minVisibleHeight = 0.15;
    final realMax = hours.isNotEmpty ? hours.reduce(math.max) : 0.0;
    final displayMax = math.max(realMax * 1.3, 2.5);

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
            "Screen usage",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewType == 'monthly'
                ? "Hours by day - ${months[selectedMonth! - 1]} $selectedYear"
                : "Hours by month - $selectedYear",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: displayMax,
                minY: 0,
                groupsSpace: 12,
                barGroups: List.generate(labels.length, (i) {
                  final realValue = hours[i];
                  final displayHeight =
                      realValue == 0 ? minVisibleHeight : realValue;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: displayHeight,
                        color: realValue == 0
                            ? AppColors.primaryTeal.withOpacity(0.40)
                            : AppColors.primaryTeal,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(1)),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: viewType == 'yearly' ? 1 : 5,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        final label = labels[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 8),
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
                      interval: displayMax > 10
                          ? 5
                          : (displayMax > 4 ? 2 : 1),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}h',
                        style: const TextStyle(fontSize: 8),
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
                  horizontalInterval: 1,
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
                      final label = labels[groupIndex];
                      final realVal = hours[groupIndex];
                      final displayVal = realVal.toStringAsFixed(1);
                      final displayLabel = viewType == 'monthly'
                          ? 'Day $label'
                          : label;
                      return BarTooltipItem(
                        '$displayLabel\n$displayVal h',
                        const TextStyle(
                            color: Colors.white, fontSize: 12),
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
