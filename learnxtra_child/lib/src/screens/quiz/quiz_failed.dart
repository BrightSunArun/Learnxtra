import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:LearnXtraChild/src/routes/app_routes.dart';

class QuizFailedScreen extends StatelessWidget {
  // Accept optional constructor parameters, but prefer Get.arguments.
  final int? correct;
  final int? total;
  final List<Map<String, dynamic>>? quizSummary;
  final String? sessionId;

  const QuizFailedScreen({
    super.key,
    this.correct,
    this.total,
    this.quizSummary,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    // Try to get values from Get.arguments (Map) if provided.
    final args = Get.arguments;
    final int finalCorrect = correct ??
        (args is Map && args['isCorrect'] is int ? args['correct'] as int : 0);
    final int finalTotal = total ??
        (args is Map && args['total'] is int ? args['total'] as int : 0);
    final List<Map<String, dynamic>> finalSummary = quizSummary ??
        (args is Map && args['summary'] is List
            ? List<Map<String, dynamic>>.from(args['summary'])
            : (args is List ? List<Map<String, dynamic>>.from(args) : []));

    final requiredToPass = (finalTotal * 0.7).ceil();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade700,
            Colors.red.shade500,
            Colors.red.shade400,
          ],
        ),
      ),
      child: SafeArea(
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
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
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
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "SCORE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                        const Divider(
                          color: Colors.white24,
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
                            color: Colors.white,
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
                        color: Color(0xFFD32F2F),
                        size: 32,
                      ),
                      label: const Text(
                        "SEE YOUR RESULTS!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD32F2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        // Pass summary to results screen. Keep API-compatible shape.
                        Get.offAllNamed(
                          AppRoutes.quizResults,
                          arguments: {
                            'summary': finalSummary,
                            'total': finalTotal,
                            'calledFrom': 'fail',
                          },
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
