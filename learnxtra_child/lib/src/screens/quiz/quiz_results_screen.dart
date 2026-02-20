// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/routes/app_routes.dart';

class QuizResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? quizSummary;
  final String? calledFrom;
  final int? total;

  const QuizResultsScreen({
    super.key,
    this.quizSummary,
    this.calledFrom,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStateController>();

    // Use constructor parameters directly — no Get.arguments
    final List<Map<String, dynamic>> finalSummary = quizSummary ?? [];
    final int finalTotal = total ?? finalSummary.length;
    final bool isFromPass = (calledFrom == 'pass');

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        toolbarHeight: 80,
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
        elevation: 8,
        surfaceTintColor: AppColors.primaryTeal,
        shadowColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
          itemCount: finalSummary.isEmpty ? 2 : finalSummary.length + 1,
          itemBuilder: (context, index) {
            // If no summary → show a placeholder message
            if (finalSummary.isEmpty) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No results available",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Something went wrong while saving your quiz results.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // fall through to bottom button
            }

            if (index < finalSummary.length) {
              final item = finalSummary[index];
              final question = item['question'] as String? ?? '';
              final options = item['options'] as List<dynamic>? ?? [];
              final selectedLetter = item['selectedLetter'] as String? ?? '?';
              final isCorrect = item['isCorrect'] as bool? ?? false;
              // Correct answer from submit-answer API (e.g. "C" or full option text)
              final correctAnswerFromApi = item['correctAnswer'] as String?;
              final correctAnswerLetter = correctAnswerFromApi?.trim();

              // Get selected text
              String selectedText = '—';
              if (options.isNotEmpty &&
                  selectedLetter.isNotEmpty &&
                  'ABCDEFG'.contains(selectedLetter.toUpperCase())) {
                final idx = 'ABCDEFG'.indexOf(selectedLetter.toUpperCase());
                if (idx >= 0 && idx < options.length) {
                  selectedText = options[idx] as String? ?? '—';
                }
              }

              // Helper to get correct answer display text (from API-stored correctAnswer)
              String getCorrectAnswerText() {
                if (correctAnswerLetter == null ||
                    correctAnswerLetter.isEmpty) {
                  return '—';
                }
                if (options.isEmpty) {
                  return correctAnswerLetter;
                }
                // Single letter (e.g. "C") — show "C - option text"
                if (correctAnswerLetter.length == 1 &&
                    'ABCDEFG'.contains(correctAnswerLetter.toUpperCase())) {
                  final idx =
                      'ABCDEFG'.indexOf(correctAnswerLetter.toUpperCase());
                  if (idx >= 0 && idx < options.length) {
                    return '$correctAnswerLetter - ${options[idx]}';
                  }
                }
                // Full text or other format — show as-is
                return correctAnswerLetter;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCorrect
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ResultRow(
                        label: "Your Answer",
                        text: "$selectedLetter - $selectedText",
                        color: isCorrect ? AppColors.success : AppColors.error,
                        icon: isCorrect ? Icons.check : Icons.close,
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 8),
                        _ResultRow(
                          label: "Correct Answer",
                          text: getCorrectAnswerText(),
                          color: AppColors.success,
                          icon: Icons.check,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final app = Get.find<AppStateController>();
                    if (isFromPass) {
                      app.isLocked.value = false;
                    }
                    controller.endQuizFlow();
                    await controller.saveState();

                    Get.offAllNamed(AppRoutes.bottomNavigation);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        color: Colors.white,
                        isFromPass
                            ? Icons.rocket_launch_rounded
                            : Icons.refresh_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isFromPass ? "LET'S GO!" : "TRY AGAIN!",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final IconData icon;

  const _ResultRow({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
