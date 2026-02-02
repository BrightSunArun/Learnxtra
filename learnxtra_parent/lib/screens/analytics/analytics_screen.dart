// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraParent/screens/analytics/child_progress_screen.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import '../../constants/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ApiService api = Get.find<ApiService>();

  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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
      appBar: AppBar(
        title: const Text(
          "Learning Progress",
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
      body: Container(
        color: AppColors.white,
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? _buildErrorState()
                  : _buildChildrenList(),
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
              onPressed: _loadDashboard,
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

  Widget _buildChildrenList() {
    final children = dashboardData?['children'] as List<dynamic>? ?? [];

    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.child_care_outlined,
                size: 80,
                color: AppColors.gray400,
              ),
              const SizedBox(height: 16),
              Text(
                "No children added yet",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add a child to view their learning progress",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gray600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index] as Map<String, dynamic>;
        final childId = child['childId']?.toString() ?? '';
        final name = child['name']?.toString() ?? 'Unknown Child';
        final grade = child['grade']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
              child: Icon(
                Icons.person,
                color: AppColors.primaryTeal,
                size: 32,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              grade.isNotEmpty ? "Grade $grade" : "No grade specified",
              style: TextStyle(
                color: AppColors.gray700,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.primaryTeal,
            ),
            onTap: () {
              if (childId.isNotEmpty) {
                Get.to(
                  () => ChildProgressScreen(childId: childId),
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Child ID not available',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        );
      },
    );
  }
}
