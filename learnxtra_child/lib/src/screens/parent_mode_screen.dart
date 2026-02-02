import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';

class ParentModeScreen extends StatelessWidget {
  const ParentModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStateController>();

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
        final isParent = controller.isParentMode.value;

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
                // Trying to ENABLE parent mode → ask for password
                if (value == true && !isParent) {
                  final success = await _showPasswordDialog(context);
                  if (success) {
                    controller
                        .toggleParentMode(); // only toggle if password correct
                  }
                  // else: do nothing → switch stays OFF
                }
                // Trying to DISABLE parent mode → no password needed
                else {
                  controller.toggleParentMode();
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

  // ────────────────────────────────────────────────
  // Password Dialog
  // ────────────────────────────────────────────────
  Future<bool> _showPasswordDialog(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    String? errorMessage;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.security, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Parent Mode Password'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Enter password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          errorText: errorMessage,
                        ),
                        autofocus: true,
                        onSubmitted: (_) => _validateAndClose(
                          passwordController,
                          setStateDialog,
                          context,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This password protects parent controls',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _validateAndClose(
                        passwordController,
                        setStateDialog,
                        context,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  Future<void> _validateAndClose(
    TextEditingController controller,
    StateSetter setStateDialog,
    BuildContext context,
  ) async {
    final password = controller.text.trim();

    if (password.isEmpty) {
      setStateDialog(() {
        controller.text.isEmpty ? 'Please enter password' : null;
      });
      return;
    }

    bool isCorrect = await _verifyParentPassword(password);

    if (isCorrect) {
      Navigator.pop(context, true);
    } else {
      setStateDialog(() {
        'Incorrect password' as String?;
      });
    }
  }

  Future<bool> _verifyParentPassword(String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    const validPasswords = ['parent123', 'learnxtra2025', 'mychild2026'];

    return validPasswords.contains(password);
  }
}
