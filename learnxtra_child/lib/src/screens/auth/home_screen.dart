import 'package:LearnXtraChild/src/screens/quiz/quiz_instructions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/screens/lock_device.dart';
import 'package:LearnXtraChild/src/screens/unlock_device.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Get.find<AppStateController>();

    return Obx(() {
      if (app.isAttemptingQuiz.value) {
        return const DailyQuizInstructionScreen();
      }
      if (app.isLocked.value) {
        return const LockedScreen();
      }
      return const UnlockDevice();
    });
  }
}
