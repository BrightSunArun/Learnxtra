import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<AppStateController>();
    final api = Get.find<ApiService>();
    controller.loadSubjects(api);
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
      body: Obx(() {
        if (controller.subjectsLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }
        if (controller.subjectsError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load subjects: ${controller.subjectsError}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        final subjects = controller.availableSubjects;
        if (subjects.isEmpty) {
          return const Center(
            child: Text(
              "No subjects available",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 52),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];

              return _SubjectCard(
                subject: subject,
                color: _getColorForSubject(subject),
                onTap: () {
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
        );
      }),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final Color color;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subject,
              textAlign: TextAlign.center,
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
}
