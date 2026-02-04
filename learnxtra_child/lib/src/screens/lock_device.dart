import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockedScreen extends StatefulWidget {
  const LockedScreen({super.key});

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  final ApiService _api = ApiService();
  final app = Get.find<AppStateController>();

  Map<String, dynamic>? screenTimeData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScreenTime();
  }

  Future<void> _loadScreenTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString("childId");

      final result = await _api.getScreenTime(childId: childId!);

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
    if (screenTimeData == null) return "Loading...";
    final isLocked = screenTimeData!['isLocked'] == true;
    return isLocked ? "Device is locked" : "Device is unlocked";
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 100,
                  color: Colors.white70,
                ),
                const SizedBox(height: 24),

                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Info Card ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRow(
                                      icon: Icons.lock_clock,
                                      label: "Remaining unlocks today",
                                      value:
                                          "${screenTimeData!['remainingUnlocks'] ?? '—'}",
                                    ),
                                    _buildRow(
                                      icon: Icons.timer_outlined,
                                      label: "Unlock duration",
                                      value:
                                          "${screenTimeData!['unlockDurationMinutes'] ?? '—'} minutes",
                                    ),
                                    _buildRow(
                                      icon: Icons.access_time,
                                      label: "Allowed time window",
                                      value:
                                          "${screenTimeData!['startTime'] ?? '--:--'} am – ${screenTimeData!['endTime'] ?? '--:--'} pm",
                                    ),
                                    if (screenTimeData![
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

                const SizedBox(height: 48),

                Obx(
                  () => Text(
                    "${screenTimeData!['remainingUnlocks'] ?? '—'} unlocks left today",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon: const Icon(Icons.school_rounded, size: 28),
                  label: const Text(
                    "Start Learning to Unlock",
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowPage,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    app.resetDailyData();
                    app.startQuizFlow();
                  },
                ),

                const SizedBox(height: 24),
              ],
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
          Icon(icon, color: AppColors.primaryTeal, size: 28),
          const SizedBox(width: 16),
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
}
