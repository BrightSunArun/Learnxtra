// ignore_for_file: deprecated_member_use
import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? registrationStats;
  bool isLoading = true;
  bool isStatsLoading = false;
  String? errorMessage;
  String viewType = 'yearly';
  int get _startYear => math.max(2026, DateTime.now().year);
  int selectedYear = math.max(2026, DateTime.now().year);
  int? selectedMonth;
  List<String> months = [
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
    _loadDashboardData();
    _loadRegistrationStats();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final data = await ApiService().getDashboardOverview();
    if (!mounted) return;
    setState(() {
      isLoading = false;
      if (data != null) {
        dashboardData = data;
      } else {
        errorMessage = "Failed to load dashboard data";
      }
    });
  }

  Future<void> _loadRegistrationStats() async {
    setState(() => isStatsLoading = true);
    Map<String, dynamic>? stats;
    if (viewType == 'yearly') {
      stats = await ApiService().getRegistrationStats(
        type: 'yearly',
        year: selectedYear,
      );
    } else {
      if (selectedMonth == null) {
        setState(() => isStatsLoading = false);
        return;
      }
      stats = await ApiService().getRegistrationStats(
        type: 'monthly',
        year: selectedYear,
        month: selectedMonth,
      );
    }
    if (!mounted) return;
    setState(() {
      isStatsLoading = false;
      registrationStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            )
          else if (errorMessage != null)
            _buildErrorWidget()
          else if (dashboardData != null)
            _buildStatsRow()
          else
            const SizedBox.shrink(),
          const SizedBox(height: 28),
          _buildChartControls(),
          const SizedBox(height: 20),
          _chartCard(),
        ],
      ),
    );
  }

  Widget _buildChartControls() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _compactDropdown(
            label: "View",
            value: viewType,
            items: const ['yearly', 'monthly'],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  viewType = val;
                  if (val == 'monthly' && selectedMonth == null) {
                    selectedMonth = DateTime.now().month;
                  }
                });
                _loadRegistrationStats();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _compactDropdown(
            label: "Year",
            value: selectedYear.toString(),
            items: List.generate(10, (i) => (_startYear + i).toString()),
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedYear = int.parse(val));
                _loadRegistrationStats();
              }
            },
          ),
        ),
        if (viewType == 'monthly') ...[
          const SizedBox(width: 16),
          Expanded(
            child: _compactDropdown(
              label: "Month",
              value: selectedMonth?.toString() ?? '',
              items: List.generate(12, (i) => (i + 1).toString()),
              itemDisplay: (v) => months[int.parse(v) - 1].substring(0, 3),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedMonth = int.parse(val));
                  _loadRegistrationStats();
                }
              },
            ),
          ),
        ] else
          const Spacer(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200.withOpacity(0.7)),
          ),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: value.isEmpty ? null : value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            underline: const SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  itemDisplay?.call(item) ?? item,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage ?? "Unknown error",
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _loadDashboardData,
            child: const Text("Retry", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalParents = (dashboardData!['totalParents'] ?? 0).toString();
    final totalChildren = (dashboardData!['totalChildren'] ?? 0).toString();
    final activeDevices = (dashboardData!['activeDevices'] ?? 0).toString();
    final totalSOS = (dashboardData!['totalSOS'] ?? 0).toString();
    return Row(
      children: [
        _compactStatCard("Parents", totalParents, AppColors.primaryTeal,
            FontAwesomeIcons.person),
        _compactStatCard("Children", totalChildren, AppColors.orangePage,
            FontAwesomeIcons.child),
        _compactStatCard("Devices", activeDevices, AppColors.cyanAccent,
            FontAwesomeIcons.mobileScreen),
        _compactStatCard("SOS", totalSOS, AppColors.coralRed,
            FontAwesomeIcons.triangleExclamation),
      ],
    );
  }

  Widget _compactStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewType == 'yearly'
                    ? "$selectedYear Registrations"
                    : "${months[selectedMonth! - 1]} $selectedYear Registrations",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  _legendDot("Parents", AppColors.primaryTeal),
                  const SizedBox(width: 20),
                  _legendDot("Children", AppColors.orangePage),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280, // reduced from 340
            child: isStatsLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : registrationStats == null ||
                        (registrationStats!['labels'] as List?)?.isEmpty == true
                    ? const Center(
                        child: Text(
                          "No data for this period",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      )
                    : _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final labels = registrationStats!['labels'] as List;
    final parentData = (registrationStats!['parent'] as List)
        .map((e) => double.tryParse(e.toString()) ?? 0)
        .toList();
    final childrenData = (registrationStats!['children'] as List)
        .map((e) => double.tryParse(e.toString()) ?? 0)
        .toList();
    final maxRaw = [...parentData, ...childrenData].fold<double>(0, math.max);
    final maxY = math.max(maxRaw * 1.4, 4.0);
    final double? bottomInterval = viewType == 'monthly' ? 5 : 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        groupsSpace: 6,
        barGroups: List.generate(labels.length, (i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 3,
            barRods: [
              BarChartRodData(
                toY: parentData[i],
                color: AppColors.primaryTeal,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              BarChartRodData(
                toY: childrenData[i],
                color: AppColors.orangePage,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length)
                  return const SizedBox.shrink();
                final rawLabel = labels[index].toString();
                String displayLabel;
                if (viewType == 'yearly') {
                  final monthIndex = int.tryParse(rawLabel);
                  if (monthIndex != null &&
                      monthIndex >= 1 &&
                      monthIndex <= 12) {
                    displayLabel = months[monthIndex - 1].substring(0, 3);
                  } else {
                    displayLabel = rawLabel;
                  }
                } else {
                  displayLabel = rawLabel;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    displayLabel,
                    style: const TextStyle(fontSize: 11, height: 1.1),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: maxY <= 10 ? 1 : 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.12),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = labels[groupIndex].toString();
              final value = rod.toY.toInt();
              final type = rodIndex == 0 ? "Parents" : "Children";
              return BarTooltipItem(
                '$type\n$label: $value',
                const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              );
            },
          ),
        ),
      ),
    );
  }
}
