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
    final args = Get.arguments;

    List<Map<String, dynamic>> finalSummary = [];
    int finalTotal = 0;
    String? calledFrom;

    if (args is Map) {
      finalSummary =
          (args['summary'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      finalTotal = args['total'] as int? ?? finalSummary.length;
      calledFrom = args['calledFrom'] as String?;
    } else if (args is List) {
      finalSummary = List<Map<String, dynamic>>.from(args);
      finalTotal = finalSummary.length;
    }

    final isFromPass = calledFrom == 'pass';

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
          itemCount: finalSummary.length + 1,
          itemBuilder: (context, index) {
            if (index < finalSummary.length) {
              final item = finalSummary[index];
              final question = item['question'] as String? ?? '';
              final options = item['options'] as List<dynamic>? ?? [];
              final selectedLetter = item['selectedLetter'] as String? ?? '?';
              final isCorrect = item['isCorrect'] as bool? ?? false;

              final selectedText = options.isNotEmpty &&
                      selectedLetter.isNotEmpty &&
                      'ABCD'.contains(selectedLetter)
                  ? options['ABCD'.indexOf(selectedLetter)] as String? ?? '—'
                  : '—';

              final correctText = isCorrect
                  ? selectedText
                  : options.isNotEmpty
                      ? options.firstWhere(
                          (opt) => false,
                          orElse: () => '—',
                        )
                      : '—';

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
                          text: "— (not revealed)",
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
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    controller.endQuizFlow();
                    await controller.saveState();
                    Get.offAllNamed(AppRoutes.bottomNavigation);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFromPass
                            ? Icons.rocket_launch_rounded
                            : Icons.refresh_rounded,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isFromPass ? "LET'S GO!" : "TRY AGAIN!",
                        style: const TextStyle(
                          fontSize: 24,
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
