import 'package:LearnXtraChild/src/screens/quiz/quiz_results_screen.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class QuizPassedScreen extends StatelessWidget {
  final int? correct;
  final int? total;
  final List<Map<String, dynamic>>? quizSummary;

  const QuizPassedScreen({
    super.key,
    this.correct,
    this.total,
    this.quizSummary,
  });

  @override
  Widget build(BuildContext context) {
    final int finalCorrect = correct ?? 0;
    final int finalTotal = total ?? 0;
    final List<Map<String, dynamic>> finalSummary = quizSummary ?? [];

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
        elevation: 10,
        surfaceTintColor: AppColors.primaryTeal,
        shadowColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 16,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.55),
                        blurRadius: 70,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    'assets/lottie/quiz_passed.json',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "AMAZING JOB!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryTeal.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$finalCorrect / $finalTotal",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "QUESTIONS CORRECT",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 40),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     const Icon(
                //       Icons.lock_open_rounded,
                //       size: 32,
                //     ),
                //     const SizedBox(width: 12),
                //     const Text(
                //       "Unlocked for 1.5 hours!",
                //       style: TextStyle(
                //         fontSize: 22,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.analytics_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    label: const Text(
                      "SEE YOUR RESULTS!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => QuizResultsScreen(
                            quizSummary: finalSummary,
                            total: finalTotal,
                            calledFrom: 'pass',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
