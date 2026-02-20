// ignore_for_file: deprecated_member_use, avoid_print

import 'package:LearnXtraParent/screens/dashboard/child_code.dart';
import 'package:LearnXtraParent/screens/main_navigation.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';

class ChildScreenTimeSettings extends StatefulWidget {
  final String? calledFrom;
  final String childId;
  final String childName;
  final int? dailyUnlockCount;
  final int? unlockDurationMinutes;

  const ChildScreenTimeSettings({
    this.calledFrom,
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
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = true;
  bool _isSaving = false;

  // Flags to know whether values were provided by API
  bool _hasApiDailyUnlock = false;
  bool _hasApiUnlockDuration = false;
  bool _hasApiStartTime = false;
  bool _hasApiEndTime = false;

  // Flags to know whether user modified the values locally
  bool _dailyUnlockModified = false;
  bool _durationModified = false;
  bool _startTimeModified = false;
  bool _endTimeModified = false;

// === Add this new state field near other state flags ===
  bool _settingsSavedSuccessfully =
      false; // becomes true after a successful save/create

  final ApiService _apiService = Get.find<ApiService>();

  @override
  void initState() {
    super.initState();
    _dailyUnlockCount = widget.dailyUnlockCount ?? 3;
    _unlockDurationMinutes = widget.unlockDurationMinutes ?? 60;
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final data = await _apiService.getChildScreenTime(widget.childId);

      // Reset flags before parsing
      _hasApiDailyUnlock = false;
      _hasApiUnlockDuration = false;
      _hasApiStartTime = false;
      _hasApiEndTime = false;

      // Parse remainingUnlocks
      try {
        final dynamic ru = data['remainingUnlocks'];
        if (ru != null) {
          final parsed = _parseIntNullable(ru);
          if (parsed != null) {
            _dailyUnlockCount = parsed;
            _hasApiDailyUnlock = true;
          } else {
            // ru exists but cannot be parsed -> treat as missing
            print(
                "[DEBUG] getChildScreenTime: 'remainingUnlocks' present but unparsable: $ru");
          }
        } else {
          print("[DEBUG] getChildScreenTime: 'remainingUnlocks' is null");
        }
      } catch (e) {
        print("[DEBUG] Error parsing 'remainingUnlocks': $e");
      }

      // Parse unlockDurationMinutes
      try {
        final dynamic ud = data['unlockDurationMinutes'];
        if (ud != null) {
          final parsed = _parseIntNullable(ud);
          if (parsed != null) {
            _unlockDurationMinutes = parsed;
            _hasApiUnlockDuration = true;
          } else {
            print(
                "[DEBUG] getChildScreenTime: 'unlockDurationMinutes' present but unparsable: $ud");
          }
        } else {
          print("[DEBUG] getChildScreenTime: 'unlockDurationMinutes' is null");
        }
      } catch (e) {
        print("[DEBUG] Error parsing 'unlockDurationMinutes': $e");
      }

      // Parse startTime
      try {
        final dynamic st = data['startTime'];
        final parsedSt = _parseTimeOfDayNullable(st);
        if (parsedSt != null) {
          _startTime = parsedSt;
          _hasApiStartTime = true;
        } else {
          print(
              "[DEBUG] getChildScreenTime: 'startTime' is null/unparsable: $st");
        }
      } catch (e) {
        print("[DEBUG] Error parsing 'startTime': $e");
      }

      // Parse endTime
      try {
        final dynamic et = data['endTime'];
        final parsedEt = _parseTimeOfDayNullable(et);
        if (parsedEt != null) {
          _endTime = parsedEt;
          _hasApiEndTime = true;
        } else {
          print(
              "[DEBUG] getChildScreenTime: 'endTime' is null/unparsable: $et");
        }
      } catch (e) {
        print("[DEBUG] Error parsing 'endTime': $e");
      }

      // When we successfully got some values from API, user hasn't modified them yet
      _dailyUnlockModified = false;
      _durationModified = false;
      _startTimeModified = false;
      _endTimeModified = false;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print(
          "[DEBUG] getChildScreenTime completed. hasApiDaily: $_hasApiDailyUnlock, hasApiDuration: $_hasApiUnlockDuration, hasApiStart: $_hasApiStartTime, hasApiEnd: $_hasApiEndTime");
    } catch (e) {
      // API threw - likely because backend returned nulls in unexpected way
      print("Failed to load screen time settings: $e");
      // Keep defaults and flags false so UI will require user input
      _hasApiDailyUnlock = false;
      _hasApiUnlockDuration = false;
      _hasApiStartTime = false;
      _hasApiEndTime = false;

      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Parses integers but returns null if unparsable
  int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  TimeOfDay? _parseTimeOfDayNullable(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    try {
      final parts = value.split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  String _formatTimeOfDay24h(TimeOfDay? time) {
    final effectiveTime = time ?? const TimeOfDay(hour: 0, minute: 0);
    return '${effectiveTime.hour.toString().padLeft(2, '0')}:${effectiveTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatEndTimeOfDay24h(TimeOfDay? time) {
    final effectiveTime = time ?? const TimeOfDay(hour: 0, minute: 0);
    return '${effectiveTime.hour.toString().padLeft(2, '0')}:${effectiveTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isNoChangeError(dynamic e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no fields') ||
        msg.contains('no change') ||
        msg.contains('nothing to update') ||
        msg.contains('unchanged') ||
        msg.contains('no values changed');
  }

  Future<void> postSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final response = await _apiService.createChildScreenTime(
        childId: widget.childId,
        dailyUnlockCount: _dailyUnlockCount,
        unlockDurationMinutes: _unlockDurationMinutes,
        startTime: _formatTimeOfDay24h(_startTime),
        endTime: _formatEndTimeOfDay24h(_endTime),
      );

      print("Settings created for ${widget.childName}! $response");

      getSnackbar(
        title: "Success",
        message: "Settings saved for ${widget.childName}!",
      );

      _hasApiDailyUnlock = true;
      _hasApiUnlockDuration = true;
      _hasApiStartTime = _startTime != null;
      _hasApiEndTime = _endTime != null;
      _dailyUnlockModified = false;
      _durationModified = false;
      _startTimeModified = false;
      _endTimeModified = false;

      setState(() {
        _settingsSavedSuccessfully = true;
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool("isScreenTimeSaved", true);
      prefs.setString("childId", widget.childId);
      prefs.setString("childName", widget.childName);

      print("[DEBUG] postSettings: settingsSavedSuccessfully set to true");
    } catch (e) {
      print("Create error: $e");
      String msg = "Failed to create settings";
      getSnackbar(title: "Error", message: msg);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final response = await _apiService.updateChildScreenTime(
        childId: widget.childId,
        defaultDailyUnlocks: _dailyUnlockCount,
        defaultUnlockDuration: _unlockDurationMinutes,
        startTime: _formatTimeOfDay24h(_startTime),
        endTime: _formatEndTimeOfDay24h(_endTime),
      );

      print("Settings updated for ${widget.childName}! $response");

      getSnackbar(
        title: "Success",
        message: "Settings saved for ${widget.childName}!",
      );

      _hasApiDailyUnlock = true;
      _hasApiUnlockDuration = true;
      _hasApiStartTime = _startTime != null;
      _hasApiEndTime = _endTime != null;
      _dailyUnlockModified = false;
      _durationModified = false;
      _startTimeModified = false;
      _endTimeModified = false;

      setState(() {
        _settingsSavedSuccessfully = true;
      });
      print("[DEBUG] _saveSettings: settingsSavedSuccessfully set to true");
    } catch (e) {
      print("Update error: $e");

      String msg = "Failed to save settings";
      if (_isNoChangeError(e)) {
        getSnackbar(
          title: "Success",
          message: "Settings are already up to date",
        );
      } else {
        getSnackbar(title: "Error", message: msg);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart
        ? _startTime ?? const TimeOfDay(hour: 0, minute: 0)
        : _endTime ?? const TimeOfDay(hour: 0, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _startTimeModified = true;
          print(
              "[DEBUG] User selected startTime: ${_formatTimeOfDay24h(picked)}");
        } else {
          _endTime = picked;
          _endTimeModified = true;
          print(
              "[DEBUG] User selected endTime: ${_formatTimeOfDay24h(picked)}");
        }
      });
    }
  }

  String _formatDisplayTime12h(TimeOfDay? time, {bool isEndTime = false}) {
    final effective = time ??
        (isEndTime
            ? const TimeOfDay(hour: 0, minute: 0)
            : const TimeOfDay(hour: 0, minute: 0));

    int hour = effective.hour;
    final minuteStr = effective.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minuteStr $period';
  }

  bool get _canProceed {
    final dailyValid = _hasApiDailyUnlock || _dailyUnlockModified;
    final durationValid = _hasApiUnlockDuration || _durationModified;
    final startValid = _hasApiStartTime || _startTimeModified;
    final endValid = _hasApiEndTime || _endTimeModified;

    final all = dailyValid && durationValid && startValid && endValid;
    print(
        "[DEBUG] _canProceed check -> dailyValid:$dailyValid durationValid:$durationValid startValid:$startValid endValid:$endValid => all:$all");
    return all;
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
            fontWeight: FontWeight.w800,
            fontSize: 21,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.childName}'s Screen Time Rules",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Daily limits & allowed time window",
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      title: "Daily Unlocks",
                      description: "Max unlocks per day",
                      value: _dailyUnlockCount,
                      minValue: 1,
                      maxValue: 8,
                      unit: "",
                      onChanged: (v) {
                        setState(() {
                          _dailyUnlockCount = v;
                          _dailyUnlockModified = true;
                          print("[DEBUG] User changed dailyUnlockCount to $v");
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      title: "Each Unlock",
                      description: "Duration per session",
                      value: _unlockDurationMinutes,
                      minValue: 5,
                      maxValue: 180,
                      step: 5,
                      unit: "min",
                      onChanged: (v) {
                        setState(() {
                          _unlockDurationMinutes = v;
                          _durationModified = true;
                          print(
                              "[DEBUG] User changed unlockDurationMinutes to $v");
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTimeCard(
                      title: "Start Time",
                      description: "Earliest unlock allowed",
                      timeText:
                          _formatDisplayTime12h(_startTime, isEndTime: false),
                      onTap: () => _selectTime(true),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeCard(
                      title: "End Time",
                      description: "Latest unlock allowed",
                      timeText:
                          _formatDisplayTime12h(_endTime, isEndTime: true),
                      onTap: () => _selectTime(false),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: (_isSaving || !_canProceed)
                            ? null
                            : widget.calledFrom == "add_child"
                                ? postSettings
                                : _saveSettings,
                        style:
                            ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Save Settings",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Provide hint to the user when button is disabled due to missing inputs
                    if (!_isLoading && !_canProceed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Please fill all fields before continuing.",
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          onPressed: (!_isSaving &&
                  (widget.calledFrom == "add_child"
                      ? _settingsSavedSuccessfully
                      : _canProceed))
              ? () {
                  if (widget.calledFrom == "add_child") {
                    print(
                        "[DEBUG] Navigating to ChildConnectionCodeScreen (after save)");
                    Get.offAll(
                      () => ChildConnectionCodeScreen(
                        childId: widget.childId,
                        childName: widget.childName,
                      ),
                    );
                  } else {
                    print("[DEBUG] Navigating to MainNavigation");
                    Get.offAll(
                      () => const MainNavigation(),
                    );
                  }
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.calledFrom == "add_child" ? "Generate Code" : "Done",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              widget.calledFrom == "add_child"
                  ? SizedBox(width: 10)
                  : SizedBox.shrink(),
              widget.calledFrom == "add_child"
                  ? Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: AppColors.white,
                    )
                  : SizedBox.shrink(),
            ],
          ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 3),
          Text(description,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(Icons.remove,
                  value > minValue ? () => onChanged(value - step) : null),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    "$value",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal),
                  ),
                  Text(unit,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(width: 20),
              _controlButton(Icons.add,
                  value < maxValue ? () => onChanged(value + step) : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String description,
    required String timeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 5,
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time,
                        color: AppColors.primaryTeal, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        icon: Icon(icon,
            color: enabled ? AppColors.primaryTeal : Colors.grey[500]),
        iconSize: 22,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: onPressed,
      ),
    );
  }
}
