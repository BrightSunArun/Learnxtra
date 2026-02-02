import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateController extends GetxController {
  // ── Existing fields ──
  var isLinked = false.obs;
  var isLocked = true.obs;
  var unlocksToday = 0.obs;
  final int maxUnlocksPerDay = 3;
  var isAttemptingQuiz = false.obs;
  var childId = ''.obs;
  var deviceId = ''.obs;
  var parentId = ''.obs;
  var grade = 5.obs;
  var board = 'CBSE'.obs;

  var correctAnswersToday = 0.obs;
  Rx<DateTime?> lastQuizDate = Rx<DateTime?>(null);

  List<String> get availableSubjects {
    return const ['Science', 'Math', 'English', 'Geography'];
  }

  List<Map<String, dynamic>> getQuestionsForSubject(String subject) {
    return []; // ← implement later
  }

  // ── NEW: Parent Mode ──
  var isParentMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadState(); // ensure loaded early
  }

  void resetDailyData() {
    final now = DateTime.now();
    if (lastQuizDate.value == null || !isSameDay(lastQuizDate.value!, now)) {
      unlocksToday.value = 0;
      correctAnswersToday.value = 0;
      lastQuizDate.value = now;
      saveState(); // persist reset
    }
  }

  bool canUnlock() => unlocksToday.value < maxUnlocksPerDay;

  void useUnlock() {
    if (canUnlock()) {
      unlocksToday.value++;
      isLocked.value = false;
      saveState();
    }
  }

  void startQuizFlow() => isAttemptingQuiz.value = true;
  void endQuizFlow() => isAttemptingQuiz.value = false;

  // ── Parent mode toggle ──
  void toggleParentMode() {
    isParentMode.value = !isParentMode.value;
    saveState();

    // Optional feedback
    Get.snackbar(
      backgroundColor: AppColors.primaryTeal,
      colorText: Colors.white,
      isParentMode.value ? "Parent Mode" : "Child Mode",
      isParentMode.value
          ? "Parent controls activated"
          : "Back to learning mode",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLinked', isLinked.value);
    await prefs.setBool('isLocked', isLocked.value);
    await prefs.setInt('unlocksToday', unlocksToday.value);

    await prefs.setString('childId', childId.value);
    await prefs.setString('deviceId', deviceId.value);
    await prefs.setString('parentId', parentId.value);

    await prefs.setInt('grade', grade.value);
    await prefs.setString('board', board.value);

    // NEW
    await prefs.setBool('isParentMode', isParentMode.value);
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();

    isLinked.value = prefs.getBool('isLinked') ?? false;
    isLocked.value = prefs.getBool('isLocked') ?? true;
    unlocksToday.value = prefs.getInt('unlocksToday') ?? 0;

    childId.value = prefs.getString('childId') ?? '';
    deviceId.value = prefs.getString('deviceId') ?? '';
    parentId.value = prefs.getString('parentId') ?? '';

    grade.value = prefs.getInt('grade') ?? 5;
    board.value = prefs.getString('board') ?? 'CBSE';

    isParentMode.value = prefs.getBool('isParentMode') ?? false;
  }
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
