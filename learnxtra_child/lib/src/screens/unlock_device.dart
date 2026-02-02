import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';

class UnlockDevice extends StatelessWidget {
  const UnlockDevice({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStateController>();

    return Container(
      color: AppColors.backgroundCream,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/Logo.png",
              height: 240,
              width: 240,
            ),
            const SizedBox(height: 40),
            const Text(
              "Enjoy your device!\nYou've earned it!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                controller.isLocked.value = true;
                await controller.saveState();

                Get.snackbar(
                  "Device Locked",
                  "Locked until next quiz unlock",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.teal.withOpacity(0.9),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Lock Again",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
