import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SOSController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();

  final RxString selectedReason = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isCheckingStatus = false.obs;
  final RxString currentSosId = ''.obs;
  final RxString sosStatus = ''.obs;
  final RxString statusMessage = 'Checking status...'.obs;

  Timer? _statusPollingTimer;

  final List<String> reasons = [
    'Quiz failed / Feeling stuck',
    'Bullying or feeling unsafe',
    'Feeling very anxious/sad',
    'Health emergency',
    'Other (please explain)',
  ];

  @override
  void onInit() {
    super.onInit();
    _checkExistingSosStatus();
  }

  @override
  void onClose() {
    _statusPollingTimer?.cancel();
    super.onClose();
  }

  Future<void> _checkExistingSosStatus() async {
    isCheckingStatus.value = true;
    statusMessage.value = 'Checking for active SOS...';

    try {
      final lastSosId = await _getLastSosId();

      if (lastSosId == null || lastSosId.isEmpty) {
        sosStatus.value = '';
        statusMessage.value = '';
        return;
      }

      currentSosId.value = lastSosId;
      await _fetchAndUpdateSosStatus(lastSosId);
    } catch (e) {
      statusMessage.value = 'Could not check status';
    } finally {
      isCheckingStatus.value = false;
    }
  }

  Future<void> _fetchAndUpdateSosStatus(String sosId) async {
    try {
      final response = await apiService.getSosStatus(sosId: sosId);

      final status = response.status.toLowerCase();
      sosStatus.value = status;

      if (status == 'pending') {
        statusMessage.value = 'SOS request is pending approval...';
        _startPolling(sosId);
      } else if (status == 'approved') {
        statusMessage.value = 'SOS was approved';
        _stopPolling();
      } else if (status == 'rejected') {
        statusMessage.value = 'SOS request was not accepted';
        _stopPolling();
      } else {
        statusMessage.value = 'SOS is $status';
        _stopPolling();
      }
    } catch (e) {
      statusMessage.value = 'Status check failed';
      _stopPolling();
    }
  }

  void _startPolling(String sosId) {
    _stopPolling();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _fetchAndUpdateSosStatus(sosId);
    });
  }

  void _stopPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
  }

  Future<String?> _getLastSosId() async {
    return currentSosId.value.isNotEmpty ? currentSosId.value : null;
  }

  Future<void> sendSOS() async {
    if (selectedReason.value.isEmpty) {
      Get.snackbar('Missing Reason', 'Please select a reason',
          backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
      return;
    }

    isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('childId');

      final response = await apiService.sendSosRequest(
        childId: childId.toString(),
        reason: selectedReason.value,
      );

      if (response['success'] == true) {
        final newSosId = response['sosRequestId']?.toString() ?? '';

        if (newSosId.isNotEmpty) {
          currentSosId.value = newSosId;
        }

        sosStatus.value = 'pending';
        statusMessage.value = 'SOS request sent • Waiting for approval...';

        Get.snackbar(
          'SOS Sent',
          'Your parents/guardians have been notified.',
          backgroundColor: Colors.white,
          colorText: AppColors.primaryTeal,
          duration: const Duration(seconds: 5),
        );

        _startPolling(newSosId);

        selectedReason.value = '';
      } else {
        Get.snackbar('Error', 'Failed to send SOS',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send SOS: ${e.toString()}',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          duration: const Duration(seconds: 6));
    } finally {
      isLoading.value = false;
    }
  }

  bool get canSendNewSos => sosStatus.value != 'pending';
}

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SOSController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: AppColors.primaryTeal,
        title: const Text(
          'LearnXtra',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: true,
        elevation: 16,
        surfaceTintColor: AppColors.primaryTeal,
        shadowColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(
        () => SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: controller.isLoading.value || controller.isCheckingStatus.value
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                    strokeWidth: 5,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: Colors.redAccent.shade700,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "SOS Help Request",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Your parents will be notified immediately.\nUse this only when you really need help.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 56),
                      if (controller.sosStatus.value.isNotEmpty) ...[
                        Card(
                          color: controller.sosStatus.value == 'pending'
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  controller.sosStatus.value == 'pending'
                                      ? Icons.hourglass_top_rounded
                                      : Icons.info_outline_rounded,
                                  color: controller.sosStatus.value == 'pending'
                                      ? Colors.red.shade800
                                      : Colors.blue.shade800,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.statusMessage.value,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: controller.sosStatus.value ==
                                              'pending'
                                          ? Colors.red.shade900
                                          : Colors.blue.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (controller.canSendNewSos) ...[
                        Card(
                          color: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Why do you need help?",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...controller.reasons.map(
                                  (reason) => Obx(
                                    () => RadioListTile<String>(
                                      value: reason,
                                      groupValue:
                                          controller.selectedReason.value,
                                      title: Text(reason),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: AppColors.primaryTeal,
                                      onChanged: (val) {
                                        if (val != null) {
                                          controller.selectedReason.value = val;
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    final confirmed =
                                        await _showConfirmDialog(context);
                                    if (confirmed == true) {
                                      controller.sendSOS();
                                    }
                                  },
                            icon: const Icon(
                              Icons.call_made_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "SEND SOS NOW",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.red.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            "You currently have an active SOS request.\nPlease wait until it is resolved.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Confirm SOS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          "This will immediately notify your parents/guardians.\nAre you sure?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black, width: 2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Send SOS"),
          ),
        ],
      ),
    );
  }
}
