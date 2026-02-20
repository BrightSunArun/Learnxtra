// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/analytics/child_settings.dart';
import 'package:LearnXtraParent/screens/dashboard/child_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/child.dart';
import 'add_child_screen.dart';
import 'dart:math' as math;

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final controller = Get.find<AppStateController>();
  final ApiService api = Get.find<ApiService>();

  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  Map<String, Map<String, dynamic>?> childUsageData = {};
  Map<String, bool> childUsageLoading = {};
  Map<String, String?> childUsageError = {};
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
    _loadDashboard();

    _scrollController.addListener(() {
      if (!mounted) return;
      final pos = _scrollController.position;
      final atStart = pos.pixels <= 10;
      final atEnd = pos.pixels >= pos.maxScrollExtent - 10;

      setState(() {
        _showLeftArrow = !atStart;
        _showRightArrow = !atEnd;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final pos = _scrollController.position;
        setState(() {
          _showRightArrow = pos.maxScrollExtent > 20;
          _showLeftArrow = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await api.getParentDashboard();

      if (!mounted) return;

      setState(() {
        dashboardData = response;
        isLoading = false;
      });

      final name = dashboardData?['parentName'] as String?;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_full_name', name ?? '');

      final children = dashboardData?['children'] as List<dynamic>? ?? [];
      for (final child in children) {
        final childId = (child is Map) ? child['childId']?.toString() : null;
        if (childId != null && childId.isNotEmpty) {
          _loadUsageForChild(childId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadUsageForChild(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final parentId = prefs.getString('parentId');

    if (parentId == null || parentId.isEmpty) {
      setState(() {
        errorMessage = "Parent ID not found. Please log in again.";
        isLoading = false;
      });
      return;
    }

    setState(() {
      childUsageLoading[childId] = true;
      childUsageError[childId] = null;
      childUsageData[childId] = null;
    });

    try {
      final int monthToSend =
          chartType == 'monthly' ? (selectedMonth ?? DateTime.now().month) : 1;

      final result = await api.getParentUsage(
        parentId: parentId,
        childId: childId,
        year: selectedYear,
        month: monthToSend,
        type: chartType,
      );

      if (!mounted) return;

      setState(() {
        childUsageLoading[childId] = false;
        if (result is Map<String, dynamic> && result['data'] != null) {
          childUsageData[childId] = result;
        } else {
          childUsageError[childId] = "Invalid response";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        childUsageLoading[childId] = false;
        childUsageError[childId] = e.toString();
      });
    }
  }

  Future<void> _refreshIfNeeded(dynamic result) async {
    if (result == true) {
      await _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.white,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Children",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primaryTeal,
                          size: 30,
                        ),
                        onPressed: () => Get.to(() => const AddChildScreen()),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 160,
                    child: _buildChildrenList(),
                  ),
                  const SizedBox(height: 32),
                  _buildChartControls(),
                  const SizedBox(height: 16),
                  const Text(
                    "Screen Time Usage",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildAllChildUsageCharts(),
                ],
              ),
            ),
          ),
        ],
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
            _reloadAllChildUsage();
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
            _reloadAllChildUsage();
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
              _reloadAllChildUsage();
            },
          ),
      ],
    );
  }

  void _reloadAllChildUsage() {
    final children = dashboardData?['children'] as List<dynamic>? ?? [];
    for (final child in children) {
      final childId = (child is Map) ? child['childId']?.toString() : null;
      if (childId != null && childId.isNotEmpty) {
        _loadUsageForChild(childId);
      }
    }
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

  List<Widget> _buildAllChildUsageCharts() {
    if (isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }

    final children = dashboardData?['children'] as List<dynamic>? ?? [];

    if (children.isEmpty) {
      return [];
    }

    return children.map((child) {
      final childId = (child is Map) ? child['childId']?.toString() : null;
      final name =
          (child is Map) ? (child['name'] ?? 'Child').toString() : 'Child';

      if (childId == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _buildSingleChildUsageSection(childId, name, child),
      );
    }).toList();
  }

  Widget _buildSingleChildUsageSection(
      String childId, String name, dynamic childData) {
    final loading = childUsageLoading[childId] ?? false;
    final error = childUsageError[childId];
    final data = childUsageData[childId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$name's Usage",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTeal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
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
          child: loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
              : error != null
                  ? Center(
                      child: Text(
                        "Error: $error",
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : data == null || (data['data'] as List?)?.isEmpty == true
                      ? const Center(
                          child: Text(
                            "No usage data",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : _buildBarChartForChild(data['data'] as List, name),
        ),
      ],
    );
  }

  Widget _buildBarChartForChild(List<dynamic> rawData, String childName) {
    final labels = <String>[];
    final hours = <double>[];

    for (final item in rawData) {
      labels.add(item['label']?.toString() ?? '');
      hours.add((item['hours'] as num?)?.toDouble() ?? 0.0);
    }

    const double minVisibleHeight = 0.15;
    final realMax = hours.isNotEmpty ? hours.reduce(math.max) : 0.0;
    final displayMax = math.max(realMax * 1.3, 2.5);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: displayMax,
        minY: 0,
        groupsSpace: 12,
        barGroups: List.generate(labels.length, (i) {
          final realValue = hours[i];
          final displayHeight = realValue == 0 ? minVisibleHeight : realValue;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: displayHeight,
                color: realValue == 0
                    ? AppColors.primaryTeal.withOpacity(0.40)
                    : AppColors.primaryTeal,
                width: 8,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(1)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: chartType == 'yearly' ? 1 : 5,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length)
                  return const SizedBox.shrink();
                final label = labels[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    chartType == 'yearly' ? label : label,
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: displayMax > 10 ? 5 : (displayMax > 4 ? 2 : 1),
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 8),
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
              final realVal = hours[groupIndex];
              final displayVal = realVal.toStringAsFixed(1);
              final displayLabel = chartType == 'yearly'
                  ? months[int.tryParse(label) ?? 1 - 1]
                  : 'Day $label';
              return BarTooltipItem(
                '$displayLabel\n$displayVal h',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Failed to load children",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final childrenData = dashboardData?['children'] as List<dynamic>? ?? [];

    if (childrenData.isEmpty) {
      return const Center(
        child: Text(
          "No children added yet",
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 16,
          ),
        ),
      );
    }

    final listView = ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: childrenData.length,
      itemBuilder: (context, index) {
        return _childCard(childrenData[index]);
      },
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        listView,
        if (_showLeftArrow)
          Positioned(
            left: 0,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset - 150,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.gray800,
                  size: 32,
                ),
              ),
            ),
          ),
        if (_showRightArrow)
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset + 150,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gray800,
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _childCard(dynamic child) {
    String name = '';
    String grade = '';

    if (child is Child) {
      name = child.name;
      grade = child.grade;
    } else if (child is Map<String, dynamic>) {
      name = (child['name'] ?? '').toString();
      grade = (child['grade'] ?? '').toString();
    } else {
      name = child.toString();
    }

    final childId = (child is Map) ? child['childId'] : null;

    return GestureDetector(
      onTap: () async {
        if (childId == null) return;

        final result = await Get.to(
          () => ChildDetailsScreen(childId: childId),
        );

        await _refreshIfNeeded(result);
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8, left: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.orangePage,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Grade $grade",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (childId != null) {
                  final dynamic dailyVal =
                      (child is Map) ? child['dailyUnlockCount'] : null;
                  final dynamic durationVal =
                      (child is Map) ? child['unlockDurationMinutes'] : null;

                  final int dailyUnlockCount = dailyVal is int
                      ? dailyVal
                      : int.tryParse(dailyVal?.toString() ?? '') ?? 3;
                  final int unlockDurationMinutes = durationVal is int
                      ? durationVal
                      : int.tryParse(durationVal?.toString() ?? '') ?? 60;

                  Get.to(
                    () => ChildScreenTimeSettings(
                      childId: childId.toString(),
                      childName: name.toString(),
                      dailyUnlockCount: dailyUnlockCount,
                      unlockDurationMinutes: unlockDurationMinutes,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final name = dashboardData?['parentName'] as String?;
    final displayName = (name != null && name.isNotEmpty) ? name : "Parent";

    return SliverAppBar(
      leadingWidth: 0,
      leading: const SizedBox.shrink(),
      shadowColor: Colors.black,
      centerTitle: true,
      elevation: 10,
      surfaceTintColor: AppColors.primaryTeal,
      scrolledUnderElevation: 10,
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      title: Text(
        "Hello, $displayName",
        style: const TextStyle(
          wordSpacing: 1.6,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
