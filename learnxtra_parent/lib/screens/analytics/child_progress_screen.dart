// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import '../../constants/app_colors.dart';

class ChildProgressScreen extends StatefulWidget {
  final String childId;

  const ChildProgressScreen({super.key, required this.childId});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  final ApiService api = Get.find<ApiService>();

  Map<String, dynamic>? progressData;
  bool isLoading = true;
  String? errorMessage;

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

      final response = await api.getChildLearningProgress(widget.childId);

      setState(() {
        progressData = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childName = progressData?['childName'] as String? ?? 'Child';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Text(
          "$childName's Learning Progress",
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
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : errorMessage != null
                  ? Center(
                      child: Text(
                        "Error: $errorMessage",
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressCircularCard(),
                          const SizedBox(height: 20),
                          _buildSubjectsStats(),
                          const SizedBox(height: 20),
                          _buildWeeklyProgressChart(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildProgressCircularCard() {
    final score = (progressData?['weeklyQuizScore'] as num?)?.toDouble() ?? 0.0;
    final percentage = (score * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Quiz Score",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 120, // increase as needed
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: score,
                      strokeWidth: 15,
                      backgroundColor: AppColors.gray300,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  Text(
                    "$percentage%",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Accuracy this week",
              style: TextStyle(fontSize: 14, color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsStats() {
    final strong =
        (progressData?['strongSubjects'] as List<dynamic>?)?.cast<String>() ??
            [];
    final focus = (progressData?['needsFocusSubjects'] as List<dynamic>?)
            ?.cast<String>() ??
        [];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _statTile("Strong Subjects",
              strong.isEmpty ? "None" : strong.join(", "), AppColors.success),
          const Divider(height: 1),
          _statTile("Needs Focus", focus.isEmpty ? "None" : focus.join(", "),
              AppColors.coralRed),
        ],
      ),
    );
  }

  Widget _statTile(String title, String value, Color color) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        value,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildWeeklyProgressChart() {
    final progressList =
        (progressData?['weeklyProgress'] as List<dynamic>?)?.cast<num>() ??
            [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final spots = <FlSpot>[];
    for (int i = 0; i < progressList.length; i++) {
      spots.add(FlSpot(i.toDouble(), progressList[i].toDouble()));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Learning Progress",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryTeal,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryTeal.withOpacity(0.2),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()],
                              style: const TextStyle(fontSize: 11));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
