// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentModeScreen extends StatelessWidget {
  const ParentModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppStateController>();
    final apiService = Get.find<ApiService>();

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
      body: Obx(() {
        final isParent = appController.isParentMode.value;

        return ListView(
          padding: const EdgeInsets.only(
            top: 46,
            left: 16,
            right: 16,
          ),
          children: [
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      isParent ? Icons.security : Icons.child_care,
                      size: 80,
                      color: isParent
                          ? Colors.red.shade700
                          : AppColors.primaryTeal,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isParent ? 'Parent Mode ACTIVE' : 'Child Mode Active',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isParent ? Colors.red.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isParent
                          ? 'Restricted access • Monitoring ON'
                          : 'Full learning experience for child',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              value: isParent,
              onChanged: (bool value) async {
                if (value == true && !isParent) {
                  final success = await _showPinDialog(
                    context,
                    apiService: apiService,
                    appController: appController,
                  );
                  print(" \n\n The success is : $success");
                } else {
                  appController.toggleParentMode();
                }
              },
              title: const Text(
                'Parent Mode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isParent
                    ? 'Tap to switch to child mode'
                    : 'Tap to enable parent controls',
              ),
              secondary: Icon(
                isParent ? Icons.lock : Icons.lock_open,
                color: isParent ? Colors.red : Colors.grey,
              ),
              activeColor: Colors.red.shade700,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            const Divider(height: 40),
          ],
        );
      }),
    );
  }

  Future<bool> _showPinDialog(
    BuildContext context, {
    required ApiService apiService,
    required AppStateController appController,
  }) async {
    final TextEditingController pinController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('childId');

    if (childId == null || childId.isEmpty) {
      Get.snackbar('Error', 'No child selected. Please try again.');
      return false;
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.black,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text('Parent Mode PIN'),
                          ],
                        ),
                        SizedBox(width: 60),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Enter PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            errorText: errorMessage,
                            counterText: "",
                          ),
                          autofocus: true,
                          enabled: !isLoading,
                          onSubmitted: (_) => _validateAndUnlock(
                            pinController,
                            setDialogState,
                            context,
                            apiService,
                            appController,
                            childId,
                            (loading) =>
                                setDialogState(() => isLoading = loading),
                            (msg) => setDialogState(() => errorMessage = msg),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isLoading)
                          const CircularProgressIndicator()
                        else
                          const Text(
                            'This PIN protects parent controls',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => _validateAndUnlock(
                                  pinController,
                                  setDialogState,
                                  context,
                                  apiService,
                                  appController,
                                  childId,
                                  (loading) =>
                                      setDialogState(() => isLoading = loading),
                                  (msg) =>
                                      setDialogState(() => errorMessage = msg),
                                ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Confirm'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ) ??
        false;
  }

  Future<void> _validateAndUnlock(
    TextEditingController controller,
    StateSetter setDialogState,
    BuildContext context,
    ApiService apiService,
    AppStateController appController,
    String childId,
    void Function(bool) setLoading,
    void Function(String?) setError,
  ) async {
    final pin = controller.text.trim();

    if (pin.isEmpty) {
      setError('Please enter the PIN');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      final response = await apiService.unlockParentMode(
        childId: childId,
        pinCode: pin,
      );

      if (response['success'] == true && response['unlocked'] == true) {
        appController.toggleParentMode();
        Navigator.pop(context, true);
      } else {
        String msg = response['message'] ?? 'Failed to unlock parent mode';

        if (msg == 'INVALID_PIN') {
          msg = 'Incorrect PIN. Please try again.';
        }

        setError(msg);
      }
    } catch (e) {
      setError('Could not unlock parent mode. Please try again.');
    } finally {
      setLoading(false);
    }
  }
}
