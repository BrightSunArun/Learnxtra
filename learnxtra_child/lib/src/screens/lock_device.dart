import 'package:LearnXtraChild/src/screens/profile_details.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LearnXtraChild/src/screens/usage_screen.dart';
import 'package:LearnXtraChild/src/screens/performance_screen.dart';

class LockedScreen extends StatefulWidget {
  const LockedScreen({super.key});

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  final ApiService _api = ApiService();
  final app = Get.find<AppStateController>();
  late String? childID;

  Map<String, dynamic>? screenTimeData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScreenTime();
  }

  Future<void> _loadScreenTime() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      screenTimeData = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString("childId");

      if (childId == null || childId.trim().isEmpty) {
        setState(() {
          errorMessage = "Child ID not found";
          isLoading = false;
        });
        return;
      }

      setState(() {
        childID = childId;
      });

      final result = await _api.getScreenTime(childId: childId);

      if (result is Map<String, dynamic>) {
        setState(() {
          screenTimeData = result;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Invalid response format";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load: $e";
        isLoading = false;
      });
    }
  }

  String _getStatusText() {
    if (isLoading) return "Loading...";
    if (screenTimeData == null) return "Status unavailable";
    final isLocked = screenTimeData!['isLocked'] == true;
    return isLocked ? "Device is locked" : "Device is unlocked";
  }

  bool _canStartLearning() {
    if (screenTimeData == null) return false;
    final remaining = screenTimeData!['remainingUnlocks'] as num?;
    return (remaining ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 2, 37, 52),
            AppColors.primaryTeal,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 90,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white.withOpacity(0.96),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage != null
                                ? Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildRow(
                                        icon: Icons.lock_clock,
                                        label: "Remaining unlocks today",
                                        value:
                                            "${screenTimeData?['remainingUnlocks'] ?? '—'}",
                                      ),
                                      _buildRow(
                                        icon: Icons.timer_outlined,
                                        label: "Unlock duration",
                                        value:
                                            "${screenTimeData?['unlockDurationMinutes'] ?? '—'} minutes",
                                      ),
                                      _buildRow(
                                        icon: Icons.access_time,
                                        label: "Allowed time window",
                                        value:
                                            "${screenTimeData?['startTime'] ?? '--:--'} am – ${screenTimeData?['endTime'] ?? '--:--'} pm",
                                      ),
                                      if (screenTimeData != null &&
                                          screenTimeData![
                                                  'remainingUnlockMinutes'] !=
                                              null &&
                                          screenTimeData![
                                                  'remainingUnlockMinutes'] >
                                              0)
                                        _buildRow(
                                          icon: Icons.hourglass_bottom,
                                          label: "Time left in current unlock",
                                          value:
                                              "${screenTimeData!['remainingUnlockMinutes']} min",
                                          valueColor: Colors.green.shade700,
                                        ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canStartLearning()
                          ? AppColors.white
                          : Colors.grey.shade600,
                      foregroundColor: _canStartLearning()
                          ? AppColors.primaryTeal
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: _canStartLearning() ? 8 : 4,
                      shadowColor: _canStartLearning()
                          ? Colors.black.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    onPressed: _canStartLearning()
                        ? () {
                            app.resetDailyData();
                            app.startQuizFlow();
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_rounded, size: 30),
                        const SizedBox(width: 16),
                        const Text(
                          "Start Learning to Unlock",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.person_rounded,
                        label: "Profile",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileDetailScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.bar_chart_rounded,
                        label: "Usage",
                        onTap: () {
                          if (childID != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UsageScreen(childId: childID!),
                              ),
                            );
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.emoji_events_rounded,
                        label: "Results",
                        onTap: () {
                          if (childID != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PerformanceScreen(childId: childID!),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 30),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
