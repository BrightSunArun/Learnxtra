import 'package:LearnXtraChild/src/screens/quiz/quiz_results_screen.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class QuizFailedScreen extends StatelessWidget {
  final int? correct;
  final int? total;
  final List<Map<String, dynamic>>? quizSummary;

  const QuizFailedScreen({
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

    final requiredToPass = (finalTotal * 0.7).ceil();

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Failed animation with glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Lottie.asset(
                      'assets/lottie/quiz_failed.json',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    "KEEP TRYING!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
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

                  // Score card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.15),
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
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const Text(
                          "SCORE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                            letterSpacing: 2,
                          ),
                        ),
                        const Divider(
                          color: AppColors.primaryTeal,
                          height: 32,
                          indent: 40,
                          endIndent: 40,
                        ),
                        Text(
                          "You need $requiredToPass correct "
                          "answer${requiredToPass > 1 ? 's' : ''}\n"
                          "to unlock your device today.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // See results button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: const Icon(
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
                              calledFrom: "quiz_failed",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
