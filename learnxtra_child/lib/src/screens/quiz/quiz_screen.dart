// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/routes/app_routes.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String subject;

  const QuizScreen({
    super.key,
    required this.subject,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int correctCount = 0;
  String? selectedAnswer;
  bool hasAnswered = false;

  late final AppStateController controller;
  List<Map<String, dynamic>> questions = [];
  final List<Map<String, dynamic>> quizSummary = [];

  String? quizId;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AppStateController>();
    _startQuizFromApi();
  }

  Future<void> _startQuizFromApi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final childId = controller.childId.value.trim();
      if (childId.isEmpty) {
        throw Exception("Child ID is missing");
      }

      final payload = {
        'childId': childId,
        'grade': controller.grade.value,
        'board': controller.board.value,
      };

      print(' \n\n\n╔═══════════════════════════════════════════════');
      print('║ START QUIZ API CALL');
      print('║ Sending → $payload');
      print('╚═══════════════════════════════════════════════ \n\n\n ');

      final response = await ApiService().startQuiz(
        childId: childId,
        grade: controller.grade.value,
        board: controller.board.value,
      );

      print(' \n\n\n╔═══════════════════════════════════════════════');
      print('║ START QUIZ RESPONSE');
      print('║ $response');
      print('╚═══════════════════════════════════════════════ \n\n\n');

      quizId =
          response['quizId'] as String? ?? response['sessionId'] as String?;

      final rawQuestions = (response['questions'] as List<dynamic>?) ?? [];

      questions = rawQuestions.map<Map<String, dynamic>>((q) {
        final qMap = q as Map<String, dynamic>;

        List<String> optionsList = [];

        final rawOptions = qMap['options'];
        if (rawOptions is List) {
          for (final item in rawOptions) {
            String text = '';
            if (item is String) {
              text = item;
            } else if (item is Map) {
              text = item['text']?.toString() ??
                  item['option']?.toString() ??
                  item['value']?.toString() ??
                  item['label']?.toString() ??
                  item['title']?.toString() ??
                  '';
            }
            if (text.isNotEmpty) {
              optionsList.add(text);
            }
          }
        } else if (rawOptions is Map) {
          optionsList = rawOptions.values.map((e) => e.toString()).toList();
        }

        return {
          'id': qMap['id']?.toString() ?? '',
          'question': qMap['question_text']?.toString() ??
              qMap['question']?.toString() ??
              'Question not available',
          'options': optionsList,
        };
      }).toList();

      if (questions.isNotEmpty) {
        setState(() => isLoading = false);
        return;
      }
    } catch (e, stack) {
      print(' \n\n\n╔═══════════════════════════════════════════════');
      print('║ START QUIZ API FAILED');
      print('║ Error: $e');
      print('║ Stack: $stack');
      print('╚═══════════════════════════════════════════════ \n\n\n');

      errorMessage = "Failed to load quiz: ${e.toString().split('\n').first}";
    }

    setState(() {
      questions = controller.getQuestionsForSubject(widget.subject);
      isLoading = false;
    });
  }

  String _indexToLetter(int index) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    return index >= 0 && index < letters.length ? letters[index] : '';
  }

  Future<Map<String, dynamic>?> _submitAnswerToApi(
    String questionId,
    String selectedLetter,
  ) async {
    if (quizId == null) return null;

    final payload = {
      'childId': controller.childId.value,
      'questionId': questionId,
      'selectedAnswer': selectedLetter,
      'quizId': quizId, // added for clarity (even if not used in every backend)
    };

    print(' \n\n\n╔═══════════════════════════════════════════════');
    print('║ SUBMIT ANSWER API CALL (Q#$questionId)');
    print('║ Sending → $payload');
    print('╚═══════════════════════════════════════════════ \n\n\n');

    try {
      final response = await ApiService().submitQuizAnswer(
        childId: controller.childId.value,
        questionId: questionId,
        selectedAnswer: selectedLetter,
      );

      print(' \n\n\n╔═══════════════════════════════════════════════');
      print('║ SUBMIT ANSWER RESPONSE');
      print('║ $response');
      print('╚═══════════════════════════════════════════════ \n\n\n');

      return response as Map<String, dynamic>?;
    } catch (e, stack) {
      print(' \n\n\n╔═══════════════════════════════════════════════');
      print('║ SUBMIT ANSWER API FAILED');
      print('║ Error: $e');
      print('║ Stack: $stack');
      print('╚═══════════════════════════════════════════════ \n\n\n');
      return null;
    }
  }

  void _handleAnswer(String selectedText, int selectedIndex) {
    if (hasAnswered) return;

    final currentQuestion = questions[currentIndex];
    final questionId = currentQuestion['id'] as String?;

    setState(() {
      selectedAnswer = selectedText;
      hasAnswered = true;
    });

    if (questionId == null || questionId.isEmpty) {
      Future.delayed(const Duration(milliseconds: 900), _moveToNext);
      return;
    }

    final letter = _indexToLetter(selectedIndex);
    if (letter.isEmpty) {
      Future.delayed(const Duration(milliseconds: 900), _moveToNext);
      return;
    }

    _submitAnswerToApi(questionId, letter).then((apiResponse) {
      final bool isCorrect = apiResponse?['isCorrect'] == true;

      setState(() {
        quizSummary.add({
          'question': currentQuestion['question'],
          'options': currentQuestion['options'],
          'selectedText': selectedText,
          'selectedLetter': letter,
          'isCorrect': isCorrect,
        });

        if (isCorrect) correctCount++;
      });

      Future.delayed(const Duration(milliseconds: 1200), _moveToNext);
    }).catchError((e) {
      debugPrint("Submit error: $e");
      Future.delayed(const Duration(milliseconds: 900), _moveToNext);
    });
  }

  void _moveToNext() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        hasAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final total = questions.length;

    controller.endQuizFlow();

    Map<String, dynamic> resultData = {
      'correct': correctCount,
      'total': total,
      'summary': quizSummary,
      'passed': correctCount >= (total * 0.7).ceil(),
      'unlockGranted': false,
    };

    if (quizId != null && quizId!.isNotEmpty) {
      print('   \n\n\n╔═══════════════════════════════════════════════');
      print('║ COMPLETE QUIZ API CALL');
      print('║ quizId → $quizId');
      print('║ Local correct count so far → $correctCount');
      print('╚═══════════════════════════════════════════════ \n\n\n');

      try {
        final apiResult = await ApiService().completeQuiz(
          quizId: quizId!,
        );

        print(' \n\n\n╔═══════════════════════════════════════════════');
        print('║ COMPLETE QUIZ RESPONSE');
        print('║ $apiResult');
        print('╚═══════════════════════════════════════════════ \n\n\n');

        if (apiResult['success'] == true) {
          final serverCorrect =
              int.tryParse(apiResult['correctAnswers'].toString()) ??
                  correctCount;
          final serverPassed = apiResult['isPassed'] == true;
          final unlock = apiResult['unlockGranted'] == true;

          resultData = {
            'correct': serverCorrect,
            'total': total,
            'summary': quizSummary,
            'passed': serverPassed,
            'unlockGranted': unlock,
            'fromServer': true,
          };

          // Update today's correct count from server (more trustworthy)
          controller.correctAnswersToday.value += serverCorrect;
          controller.saveState();
        }
      } catch (e, stack) {
        print(' \n\n\n╔═══════════════════════════════════════════════');
        print('║ COMPLETE QUIZ API FAILED');
        print('║ Error: $e');
        print('║ Stack: $stack');
        print('╚═══════════════════════════════════════════════ \n\n\n');

        // fallback — use local calculation
        controller.correctAnswersToday.value += correctCount;
        controller.saveState();
      }
    } else {
      print('No quizId → using local count only');
      controller.correctAnswersToday.value += correctCount;
      controller.saveState();
    }

    if (resultData['passed'] == true) {
      Get.offAllNamed(AppRoutes.quizPassed, arguments: resultData);
    } else {
      Get.offAllNamed(AppRoutes.quizFailed, arguments: resultData);
    }
  }

  Future<bool> _onWillPop() async {
    controller.endQuizFlow();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // build method remains completely unchanged
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          title: const Text('Quiz'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          title: const Text('Quiz'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              errorMessage ?? "No questions found for ${widget.subject}.",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final question = questions[currentIndex];
    final options = question['options'] as List<dynamic>;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: AppColors.primaryTeal,
          title: Column(
            children: [
              Text(
                widget.subject,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${currentIndex + 1}/${questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 8,
          surfaceTintColor: AppColors.primaryTeal,
          shadowColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      question['question'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ...List.generate(options.length, (i) {
                  final optionText = options[i] as String;
                  final isSelected = selectedAnswer == optionText;

                  bool isCorrect = false;
                  bool isWrong = false;

                  if (hasAnswered && isSelected) {
                    final entry = quizSummary.lastWhere(
                      (e) => e['question'] == question['question'],
                      orElse: () => <String, dynamic>{},
                    );
                    isCorrect = entry['isCorrect'] == true;
                    isWrong = !isCorrect;
                  }

                  Color buttonColor = AppColors.primaryTeal;
                  Color textColor = Colors.white;

                  if (hasAnswered) {
                    if (isSelected) {
                      buttonColor = isCorrect
                          ? AppColors.success
                          : isWrong
                              ? AppColors.error
                              : Colors.orange;
                      textColor = Colors.white;
                    } else {
                      buttonColor = Colors.grey[200]!;
                      textColor = AppColors.textDark;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: hasAnswered
                            ? null
                            : () => _handleAnswer(optionText, i),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: textColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: isSelected ? 10 : 6,
                        ),
                        child: Text(
                          optionText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      "$correctCount correct so far",
                      style: TextStyle(
                        color: AppColors.textDark.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (currentIndex) / questions.length,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
