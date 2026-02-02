import 'package:LearnXtraParent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void getSnackbar({required String title, required String message}) {
  Get.snackbar(
    snackStyle: SnackStyle.FLOATING,
    isDismissible: true,
    title,
    message,
    backgroundColor: AppColors.primaryTeal,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
  );
}
