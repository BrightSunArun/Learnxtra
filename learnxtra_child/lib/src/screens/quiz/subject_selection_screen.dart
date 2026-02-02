import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_screen.dart';

class SubjectSelectionScreen extends StatelessWidget {
  const SubjectSelectionScreen({super.key});

  String _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'science':
        return "assets/lottie/science.json";
      case 'math':
        return "assets/lottie/maths.json";
      case 'geography':
        return "assets/lottie/geography.json";
      case 'english':
        return "assets/lottie/english.json";
      default:
        return "assets/lottie/science.json";
    }
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'science':
        return const Color.fromARGB(255, 122, 115, 255);
      case 'math':
        return const Color.fromARGB(255, 255, 96, 128);
      case 'geography':
        return const Color.fromARGB(255, 0, 151, 141);
      case 'english':
        return const Color.fromARGB(255, 227, 148, 1);
      default:
        return AppColors.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStateController>();
    final subjects = controller.availableSubjects;

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
      body: subjects.isEmpty
          ? const Center(
              child: Text(
                "No subjects available",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _SubjectCard(
                    subject: subject,
                    path: _getIconForSubject(subject),
                    color: _getColorForSubject(subject),
                    onTap: () {
                      // Note: startQuiz API currently does not accept subject.
                      // We still pass subject to the QuizScreen for display and
                      // for future API changes where subject will be sent.
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(subject: subject),
                        ),
                        (route) => false,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final String path;
  final Color color;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.path,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: _getPaddingForLottie(path),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Lottie.asset(
                path,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  EdgeInsets _getPaddingForLottie(String path) {
    if (path.contains('science')) {
      return const EdgeInsets.all(8);
    } else if (path.contains('english')) {
      return const EdgeInsets.only(right: 24, top: 12);
    } else {
      return const EdgeInsets.all(1);
    }
  }
}
