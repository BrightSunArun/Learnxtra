// ignore_for_file: deprecated_member_use

import 'package:LearnXtraParent/screens/analytics/child_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import '../../constants/app_colors.dart';

class ScreenTimeControlScreen extends StatefulWidget {
  const ScreenTimeControlScreen({
    super.key,
  });

  @override
  State<ScreenTimeControlScreen> createState() =>
      _ScreenTimeControlScreenState();
}

class _ScreenTimeControlScreenState extends State<ScreenTimeControlScreen> {
  final ApiService api = Get.find<ApiService>();

  List<dynamic> children = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await api.getParentDashboard();
      final fetchedChildren = (response['children'] as List<dynamic>?) ?? [];

      setState(() {
        children = fetchedChildren;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          "Screen Time Control",
          style: TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? _buildErrorState()
                      : _buildBody(),
            ),

            // Fixed bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Go Back",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? "Please try again later",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.gray700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadChildren,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.child_care_rounded,
                size: 80,
                color: AppColors.primaryTeal.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                "No children added yet",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add a child from the dashboard first",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Text(
            "Select a child to manage screen time",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index] as Map<String, dynamic>;
                final childId = child['childId']?.toString() ?? '';
                final name = child['name']?.toString() ?? 'Unknown Child';
                final grade = child['grade']?.toString() ?? '';
                final defaultDailyUnlocks = child['defaultDailyUnlocks'] ?? 0;
                final defaultUnlockDuration =
                    child['defaultUnlockDuration'] ?? 0;

                return GestureDetector(
                  onTap: () {
                    if (childId.isNotEmpty) {
                      Get.to(
                        () => ChildScreenTimeSettings(
                          childId: childId,
                          childName: name,
                          dailyUnlockCount: defaultDailyUnlocks,
                          unlockDurationMinutes: defaultUnlockDuration,
                        ),
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        'Child ID not available',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                      left: 8,
                      right: 8,
                      top: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.orangePage,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                grade.isNotEmpty
                                    ? "Grade $grade"
                                    : "No grade specified",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryTeal.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Manage Settings →",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
