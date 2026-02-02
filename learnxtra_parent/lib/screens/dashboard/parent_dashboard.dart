// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/analytics/child_settings.dart';
import 'package:LearnXtraParent/screens/dashboard/child_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/child.dart';
import 'add_child_screen.dart';

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

  // For scroll indicators + arrows
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true; // Initially assume there might be more

  @override
  void initState() {
    super.initState();
    _loadDashboard();

    // Update arrow visibility based on scroll position
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

    // Initial check after first frame (in case few items)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final pos = _scrollController.position;
        setState(() {
          _showRightArrow = pos.maxScrollExtent > 20; // small threshold
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

      setState(() {
        dashboardData = response;
        isLoading = false;
      });
      final name = dashboardData?['parentName'] as String?;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_full_name', name.toString());
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
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
                  _buildScreenTimeSummary(),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "My Children",
                        style: const TextStyle(
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
                        onPressed: () => Get.to(
                          () => const AddChildScreen(),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 160,
                    child: _buildChildrenList(),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Daily Activity Graph",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActivityChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Only this method changed significantly
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

        // Left Arrow
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

        // Right Arrow
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
      onTap: () {
        if (childId != null) {
          Get.to(() => ChildDetailsScreen(childId: childId));
        }
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8, left: 10),
        padding: const EdgeInsets.all(14),
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
                  Get.to(
                    () => ChildScreenTimeSettings(
                      childId: childId,
                      childName: name,
                      dailyUnlockCount: child['dailyUnlockCount'],
                      unlockDurationMinutes: child['unlockDurationMinutes'],
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

  Widget _buildActivityChart() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: 8,
                  color: AppColors.cyanAccent,
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: 12,
                  color: AppColors.primaryTeal,
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: 5,
                  color: AppColors.orangePage,
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 3,
              barRods: [
                BarChartRodData(
                  toY: 15,
                  color: AppColors.yellowPage,
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
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
      leading: SizedBox.shrink(),
      shadowColor: Colors.black,
      centerTitle: true,
      elevation: 10,
      surfaceTintColor: AppColors.primaryTeal,
      scrolledUnderElevation: 10,
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      title: Text(
        "Hello, $displayName",
        style: TextStyle(
          wordSpacing: 1.6,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildScreenTimeSummary() {
    String displayMainValue = "2h 45m";
    String subtitle = "Total Screen Time Today";
    String? unlocksText;
    String? remainingText;

    if (dashboardData != null) {
      final summary =
          dashboardData!['screenTimeSummary'] as Map<String, dynamic>?;
      if (summary != null) {
        final usedToday = summary['usedToday']?.toString();
        final totalUnlocks = summary['totalUnlocks']?.toString();
        final remaining = summary['remaining']?.toString();

        if (usedToday != null) {
          displayMainValue =
              "$usedToday ${usedToday == "1" ? "time" : "times"}";
          subtitle = "Used Today";
        }
        if (totalUnlocks != null) unlocksText = "Unlocks: $totalUnlocks";
        if (remaining != null) remainingText = "Remaining: $remaining";
      }
    }

    return FadeIn(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.yellowPage,
              child: Icon(Icons.timer, color: AppColors.primaryTeal),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.gray700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    displayMainValue,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (unlocksText != null || remainingText != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (unlocksText != null)
                          Text(
                            unlocksText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray700,
                            ),
                          ),
                        if (unlocksText != null && remainingText != null)
                          const SizedBox(width: 10),
                        if (remainingText != null)
                          Text(
                            remainingText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray700,
                            ),
                          ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
