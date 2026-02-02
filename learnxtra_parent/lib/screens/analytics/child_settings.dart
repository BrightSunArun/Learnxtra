// ignore_for_file: deprecated_member_use

import 'package:LearnXtraParent/screens/main_navigation.dart';
import 'package:LearnXtraParent/services/api_service.dart'; // ← added
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';

class ChildScreenTimeSettings extends StatefulWidget {
  final String childId;
  final String childName;
  final int? dailyUnlockCount;
  final int? unlockDurationMinutes;

  const ChildScreenTimeSettings({
    super.key,
    required this.childId,
    required this.childName,
    this.dailyUnlockCount = 3,
    this.unlockDurationMinutes = 60,
  });

  @override
  State<ChildScreenTimeSettings> createState() =>
      _ChildScreenTimeSettingsState();
}

class _ChildScreenTimeSettingsState extends State<ChildScreenTimeSettings> {
  late int _dailyUnlockCount;
  late int _unlockDurationMinutes;

  bool _isSaving = false;

  final ApiService _apiService =
      Get.find<ApiService>(); // ← assuming ApiService is registered in GetX

  @override
  void initState() {
    super.initState();
    _dailyUnlockCount = widget.dailyUnlockCount ?? 3;
    _unlockDurationMinutes = widget.unlockDurationMinutes ?? 60;
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final response = await _apiService.saveChildSettings(
        childId: widget.childId,
        dailyUnlockCount: _dailyUnlockCount,
        unlockDuration: _unlockDurationMinutes,
      );

      getSnackbar(
        title: "Success",
        message: "Screen time settings saved for ${widget.childName}!",
      );
      Get.back();

      print("This is the response: $response");
    } catch (e) {
      String errorMsg = "Failed to save settings";

      getSnackbar(
        title: "Error",
        message: errorMsg,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Text(
          "Screen Time – ${widget.childName}",
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "${widget.childName}'s Screen Time Rules",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Set daily unlock limits for learning sessions",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSettingCard(
                      title: "Daily Unlock Count",
                      description:
                          "Number of times the app can be unlocked per day",
                      value: _dailyUnlockCount,
                      minValue: 1,
                      maxValue: 8,
                      unit: "times",
                      onChanged: (v) => setState(() => _dailyUnlockCount = v),
                    ),
                    const SizedBox(height: 20),
                    _buildSettingCard(
                      title: "Unlock Duration",
                      description: "Duration of each unlock session",
                      value: _unlockDurationMinutes,
                      minValue: 5,
                      maxValue: 180,
                      step: 5,
                      unit: "minutes",
                      onChanged: (v) =>
                          setState(() => _unlockDurationMinutes = v),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Save Settings",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        Get.offAll(() => const MainNavigation());
                      },
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required int value,
    required int minValue,
    required int maxValue,
    int step = 1,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                Icons.remove,
                value > minValue ? () => onChanged(value - step) : null,
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    "$value",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              _controlButton(
                Icons.add,
                value < maxValue ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback? onPressed) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled
            ? AppColors.primaryTeal.withOpacity(0.15)
            : Colors.grey[200],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: enabled ? AppColors.primaryTeal : Colors.grey,
        ),
        iconSize: 24,
        padding: const EdgeInsets.all(12),
        onPressed: onPressed,
      ),
    );
  }
}
