// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:html' as html;
import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  final ApiService _apiService = ApiService();

  // Selection state
  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];

  String? _selectedBoardDisplay; // what user sees
  String? _selectedBoardClean; // what we send to API
  String? _selectedGrade;

  // Questions
  List<Map<String, dynamic>> _questions = [];
  bool _isLoadingQuestions = false;
  String? _errorMessage;

  bool _isLoadingFilters = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _searchController.addListener(() {
      setState(() {}); // trigger rebuild for client-side search
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoadingFilters = true);

    final boardsRes = await _apiService.getBoards();
    final gradesRes = await _apiService.getGrades();
    final subjectsRes = await _apiService.getSubjects();

    if (!mounted) return;

    if (boardsRes != null && boardsRes['data'] is List) {
      _boards = List<Map<String, dynamic>>.from(boardsRes['data']);
    } else if (boardsRes != null && boardsRes['boards'] is List) {
      _boards = List<Map<String, dynamic>>.from(boardsRes['boards']);
    }

    if (gradesRes != null && gradesRes['data'] is List) {
      _grades = List<Map<String, dynamic>>.from(gradesRes['data']);
    } else if (gradesRes != null && gradesRes['grades'] is List) {
      _grades = List<Map<String, dynamic>>.from(gradesRes['grades']);
    }

    if (subjectsRes != null && subjectsRes['data'] is List) {
      _subjects = List<Map<String, dynamic>>.from(subjectsRes['data']);
    } else if (subjectsRes != null && subjectsRes['subjects'] is List) {
      _subjects = List<Map<String, dynamic>>.from(subjectsRes['subjects']);
    }

    setState(() => _isLoadingFilters = false);

    // Auto select first valid items
    if (_boards.isNotEmpty) {
      final first = _boards.first;
      _selectedBoardDisplay = _getBoardDisplayName(first);
      _selectedBoardClean = _getCleanBoardName(first);
    }

    if (_grades.isNotEmpty) {
      _selectedGrade = _grades.first['name']?.toString();
    }

    // Load initial questions
    _tryLoadQuestions();
  }

  String _getBoardDisplayName(Map<String, dynamic> board) {
    final name = board['name']?.toString() ?? 'Unknown';
    final ubid = board['unique_board_id']?.toString() ?? '';
    return ubid.isNotEmpty ? '$name ($ubid)' : name;
  }

  String _getCleanBoardName(Map<String, dynamic> board) {
    return board['name']?.toString() ?? 'Unknown';
  }

  String _getUniqueBoardId(Map<String, dynamic> board) {
    final ubid = board['unique_board_id']?.toString();
    return ubid != null && ubid.isNotEmpty ? ubid : '';
  }

  int _getId(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    final sid = item['_id']?.toString();
    return int.tryParse(sid ?? '') ?? 0;
  }

  Map<String, dynamic>? _findBoardByUniqueId(String uniqueBoardId) {
    for (final b in _boards) {
      if (_getUniqueBoardId(b) == uniqueBoardId) return b;
    }
    return null;
  }

  List<Map<String, dynamic>> _filterSubjectsFor({
    required int? gradeId,
    required String? boardUniqueId,
  }) {
    if (gradeId == null || boardUniqueId == null || boardUniqueId.isEmpty) {
      return _subjects;
    }
    final filtered = _subjects.where((s) {
      final sGradeId = s['grade_id'] is int
          ? s['grade_id'] as int
          : int.tryParse(s['grade_id']?.toString() ?? '');
      final sBoardIdStr =
          s['board_id']?.toString() ?? s['unique_board_id']?.toString() ?? '';
      bool boardMatches = sBoardIdStr == boardUniqueId;
      if (!boardMatches && sBoardIdStr.isNotEmpty) {
        for (final b in _boards) {
          if (_getId(b).toString() == sBoardIdStr ||
              _getUniqueBoardId(b) == sBoardIdStr) {
            if (_getUniqueBoardId(b) == boardUniqueId) {
              boardMatches = true;
              break;
            }
          }
        }
      }
      return sGradeId == gradeId && boardMatches;
    }).toList();
    return filtered.isEmpty ? _subjects : filtered;
  }

  String? _getSelectedBoardForApi() {
    if (_selectedBoardClean != null) return _selectedBoardClean;
    if (_selectedBoardDisplay == null) return null;

    // fallback: strip anything in parentheses
    final clean = _selectedBoardDisplay!.split(' (').first.trim();
    return clean.isNotEmpty ? clean : null;
  }

  void _tryLoadQuestions() {
    final board = _getSelectedBoardForApi();
    final gradeStr = _selectedGrade;

    if (board == null || gradeStr == null) return;

    final gradeInt = int.tryParse(gradeStr);
    if (gradeInt == null) {
      debugPrint("Invalid grade format: $gradeStr");
      return;
    }

    debugPrint("Fetching questions → board: '$board', grade: $gradeInt");

    _fetchQuestions(board: board, grade: gradeInt);
  }

  Future<void> _fetchQuestions({
    required String board,
    required int grade,
  }) async {
    setState(() {
      _isLoadingQuestions = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getQuestions(
        grade: grade,
        board: board,
      );

      if (!mounted) return;

      if (response != null && response['data'] is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(response['data']);
          _isLoadingQuestions = false;
        });
        debugPrint("Loaded ${_questions.length} questions");
      } else {
        setState(() {
          _errorMessage = "No data returned from server";
          _isLoadingQuestions = false;
        });
        debugPrint("API response invalid: $response");
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error loading questions: $e";
        _isLoadingQuestions = false;
      });
      debugPrint("Fetch error: $e\n$st");
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final success = await _apiService.deleteQuestion(questionId);
    if (success) {
      setState(() {
        _questions.removeWhere(
            (q) => q['_id'] == questionId || q['id'] == questionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Question deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete question")),
      );
    }
  }

  static const List<String> _validCorrectAnswers = ['A', 'B', 'C', 'D'];

  static String _normalizeCorrectAnswer(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    return _validCorrectAnswers.contains(s) ? s : 'A';
  }

  void _showEditDialog(Map<String, dynamic> question) {
    final TextEditingController questionCtrl = TextEditingController(
      text: question['question_text'] ?? '',
    );
    String selectedCorrectAnswer = _normalizeCorrectAnswer(
      question['correct_answer']?.toString(),
    );

    final currentBoard =
        question['board']?.toString() ?? _getSelectedBoardForApi() ?? 'CBSE';
    final currentGrade = question['grade']?.toString() ?? _selectedGrade ?? '5';
    final currentSubject = question['subject']?.toString() ?? 'English';

    // Resolve initial dropdown values from question
    String? selectedBoardUniqueId;
    for (final b in _boards) {
      if (_getCleanBoardName(b) == currentBoard ||
          _getUniqueBoardId(b) == currentBoard) {
        final ubid = _getUniqueBoardId(b);
        if (ubid.isNotEmpty) selectedBoardUniqueId = ubid;
        break;
      }
    }
    selectedBoardUniqueId ??=
        _boards.isNotEmpty ? _getUniqueBoardId(_boards.first) : null;
    if (selectedBoardUniqueId != null && selectedBoardUniqueId.isEmpty) {
      selectedBoardUniqueId =
          _boards.length > 1 ? _getUniqueBoardId(_boards[1]) : null;
    }

    int? selectedGradeId;
    for (final g in _grades) {
      if (g['name']?.toString() == currentGrade) {
        selectedGradeId = _getId(g);
        break;
      }
    }
    selectedGradeId ??= _grades.isNotEmpty ? _getId(_grades.first) : null;

    final initialFiltered = _filterSubjectsFor(
      gradeId: selectedGradeId,
      boardUniqueId: selectedBoardUniqueId,
    );
    String? selectedSubjectName = currentSubject;
    if (!initialFiltered
        .any((s) => (s['name']?.toString() ?? '') == currentSubject)) {
      selectedSubjectName = initialFiltered.isNotEmpty
          ? initialFiltered.first['name']?.toString()
          : null;
    }

    final List<String> currentOptions = [];
    final optionsData = question['options'];

    if (optionsData is Map) {
      currentOptions.addAll(['A', 'B', 'C', 'D']
          .map((key) => optionsData[key]?.toString() ?? ''));
    } else if (optionsData is List) {
      currentOptions.addAll(optionsData.map((e) => e?.toString() ?? ''));
    } else {
      currentOptions.addAll(List.filled(4, ''));
    }

    final List<TextEditingController> optionCtrls = List.generate(
      4,
      (i) => TextEditingController(text: currentOptions[i]),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredSubjects = _filterSubjectsFor(
            gradeId: selectedGradeId,
            boardUniqueId: selectedBoardUniqueId,
          );
          final boardItems = _boards
              .map((b) => _getUniqueBoardId(b))
              .where((ubid) => ubid.isNotEmpty)
              .toList();
          final gradeIds = _grades.map((g) => _getId(g)).toList();
          final validBoardValue = selectedBoardUniqueId != null &&
                  boardItems.contains(selectedBoardUniqueId)
              ? selectedBoardUniqueId
              : null;
          final validGradeValue =
              selectedGradeId != null && gradeIds.contains(selectedGradeId)
                  ? selectedGradeId
                  : null;
          final validSubjectValue = selectedSubjectName != null &&
                  filteredSubjects.any((s) =>
                      (s['name']?.toString() ?? '') == selectedSubjectName)
              ? selectedSubjectName
              : null;
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Edit Question"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.75,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Board dropdown (first)
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: validBoardValue,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
                      decoration: const InputDecoration(
                        labelText: "Board",
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select Board"),
                      items: _boards
                          .map((b) {
                            final ubid = _getUniqueBoardId(b);
                            if (ubid.isEmpty) return null;
                            return DropdownMenuItem<String>(
                              value: ubid,
                              child: Text(_getBoardDisplayName(b)),
                            );
                          })
                          .whereType<DropdownMenuItem<String>>()
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedBoardUniqueId = value;
                          final nextFiltered = _filterSubjectsFor(
                            gradeId: selectedGradeId,
                            boardUniqueId: value,
                          );
                          selectedSubjectName = nextFiltered.isNotEmpty
                              ? nextFiltered.first['name']?.toString()
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Grade dropdown (second)
                    DropdownButtonFormField<int>(
                      dropdownColor: Colors.white,
                      value: validGradeValue,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
                      decoration: const InputDecoration(
                        labelText: "Grade",
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select Grade"),
                      items: _grades.map((g) {
                        final id = _getId(g);
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('Grade ${g['name'] ?? id}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGradeId = value;
                          final nextFiltered = _filterSubjectsFor(
                            gradeId: value,
                            boardUniqueId: selectedBoardUniqueId,
                          );
                          selectedSubjectName = nextFiltered.isNotEmpty
                              ? nextFiltered.first['name']?.toString()
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Subject dropdown (third)
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: validSubjectValue,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
                      decoration: const InputDecoration(
                        labelText: "Subject",
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select Subject"),
                      items: filteredSubjects.map((s) {
                        final name = s['name']?.toString() ?? 'Subject';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedSubjectName = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: questionCtrl,
                      decoration:
                          const InputDecoration(labelText: "Question Text"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: optionCtrls[i],
                          decoration:
                              InputDecoration(labelText: "Option ${i + 1}"),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: selectedCorrectAnswer,
                      decoration: const InputDecoration(
                        labelText: "Correct Answer (A, B, C or D)",
                        border: OutlineInputBorder(),
                      ),
                      items: _validCorrectAnswers
                          .map((letter) => DropdownMenuItem<String>(
                                value: letter,
                                child: Text(letter),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCorrectAnswer = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final updatedOptions =
                      optionCtrls.map((c) => c.text.trim()).toList();

                  if (questionCtrl.text.trim().isEmpty ||
                      updatedOptions.any((o) => o.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }
                  if (selectedBoardUniqueId == null ||
                      selectedGradeId == null ||
                      selectedSubjectName == null ||
                      selectedSubjectName!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Please select Board, Grade and Subject")),
                    );
                    return;
                  }

                  final boardMap = _findBoardByUniqueId(selectedBoardUniqueId!);
                  Map<String, dynamic>? gradeMap;
                  for (final g in _grades) {
                    if (_getId(g) == selectedGradeId) {
                      gradeMap = g;
                      break;
                    }
                  }
                  final boardName = boardMap != null
                      ? _getCleanBoardName(boardMap)
                      : selectedBoardUniqueId!;
                  final gradeName = gradeMap?['name']?.toString() ??
                      selectedGradeId.toString();

                  final success = await _apiService.updateQuestion(
                    grade: gradeName,
                    board: boardName,
                    subject: selectedSubjectName!,
                    questionId: question['_id']?.toString() ??
                        question['id']?.toString() ??
                        '',
                    questionText: questionCtrl.text.trim(),
                    option1: updatedOptions[0],
                    option2: updatedOptions[1],
                    option3: updatedOptions[2],
                    option4: updatedOptions[3],
                    correctAnswer: selectedCorrectAnswer,
                  );

                  if (!ctx.mounted) return;
                  if (success != null) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Question updated successfully")),
                    );
                    _tryLoadQuestions();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Failed to update question")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddQuestionDialog() {
    final TextEditingController questionCtrl = TextEditingController();
    String selectedCorrectAnswer = 'A';
    final List<TextEditingController> optionCtrls =
        List.generate(4, (_) => TextEditingController());

    String? selectedBoardUniqueId =
        _boards.isNotEmpty ? _getUniqueBoardId(_boards.first) : null;
    if (selectedBoardUniqueId != null && selectedBoardUniqueId.isEmpty) {
      selectedBoardUniqueId =
          _boards.length > 1 ? _getUniqueBoardId(_boards[1]) : null;
    }
    int? selectedGradeId = _grades.isNotEmpty ? _getId(_grades.first) : null;
    final initialFiltered = _filterSubjectsFor(
      gradeId: selectedGradeId,
      boardUniqueId: selectedBoardUniqueId,
    );
    String? selectedSubjectName = initialFiltered.isNotEmpty
        ? (initialFiltered.first['name']?.toString())
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredSubjects = _filterSubjectsFor(
            gradeId: selectedGradeId,
            boardUniqueId: selectedBoardUniqueId,
          );
          final boardItems = _boards
              .map((b) => _getUniqueBoardId(b))
              .where((ubid) => ubid.isNotEmpty)
              .toList();
          final gradeIds = _grades.map((g) => _getId(g)).toList();
          final validBoardValue = selectedBoardUniqueId != null &&
                  boardItems.contains(selectedBoardUniqueId)
              ? selectedBoardUniqueId
              : null;
          final validGradeValue =
              selectedGradeId != null && gradeIds.contains(selectedGradeId)
                  ? selectedGradeId
                  : null;
          final validSubjectValue = selectedSubjectName != null &&
                  filteredSubjects.any((s) =>
                      (s['name']?.toString() ?? '') == selectedSubjectName)
              ? selectedSubjectName
              : null;
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Add New Question"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.75,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Board dropdown (first)
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: validBoardValue,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
                      decoration: const InputDecoration(
                        labelText: "Board",
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select Board"),
                      items: _boards
                          .map((b) {
                            final ubid = _getUniqueBoardId(b);
                            if (ubid.isEmpty) return null;
                            return DropdownMenuItem<String>(
                              value: ubid,
                              child: Text(_getBoardDisplayName(b)),
                            );
                          })
                          .whereType<DropdownMenuItem<String>>()
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedBoardUniqueId = value;
                          selectedSubjectName = filteredSubjects.isNotEmpty
                              ? filteredSubjects.first['name']?.toString()
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Grade dropdown (second)
                    DropdownButtonFormField<int>(
                      dropdownColor: Colors.white,
                      value: validGradeValue,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
                      decoration: const InputDecoration(
                        labelText: "Grade",
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select Grade"),
                      items: _grades.map((g) {
                        final id = _getId(g);
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('Grade ${g['name'] ?? id}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGradeId = value;
                          final nextFiltered = _filterSubjectsFor(
                            gradeId: value,
                            boardUniqueId: selectedBoardUniqueId,
                          );
                          selectedSubjectName = nextFiltered.isNotEmpty
                              ? nextFiltered.first['name']?.toString()
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Subject dropdown (third)
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: validSubjectValue,
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
                      decoration: const InputDecoration(
                        labelText: "Subject",
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select Subject"),
                      items: filteredSubjects.map((s) {
                        final name = s['name']?.toString() ?? 'Subject';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedSubjectName = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: questionCtrl,
                      decoration:
                          const InputDecoration(labelText: "Question Text"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: optionCtrls[i],
                          decoration: InputDecoration(
                              labelText: "Option ${_validCorrectAnswers[i]}"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: selectedCorrectAnswer,
                      decoration: const InputDecoration(
                        labelText: "Correct Answer (A, B, C or D)",
                        border: OutlineInputBorder(),
                      ),
                      items: _validCorrectAnswers
                          .map((letter) => DropdownMenuItem<String>(
                                value: letter,
                                child: Text(letter),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCorrectAnswer = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final options =
                      optionCtrls.map((c) => c.text.trim()).toList();
                  if (questionCtrl.text.trim().isEmpty ||
                      options.any((o) => o.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }
                  if (selectedBoardUniqueId == null ||
                      selectedGradeId == null ||
                      selectedSubjectName == null ||
                      selectedSubjectName!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Please select Board, Grade and Subject")),
                    );
                    return;
                  }
                  final boardMap = _findBoardByUniqueId(selectedBoardUniqueId!);
                  Map<String, dynamic>? gradeMap;
                  for (final g in _grades) {
                    if (_getId(g) == selectedGradeId) {
                      gradeMap = g;
                      break;
                    }
                  }
                  final boardName = boardMap != null
                      ? _getCleanBoardName(boardMap)
                      : selectedBoardUniqueId!;
                  final gradeName = gradeMap?['name']?.toString() ??
                      selectedGradeId.toString();

                  final response = await _apiService.createQuestion(
                    grade: gradeName,
                    board: boardName,
                    questionText: questionCtrl.text.trim(),
                    option1: options[0],
                    option2: options[1],
                    option3: options[2],
                    option4: options[3],
                    correctAnswer: selectedCorrectAnswer,
                    subject: selectedSubjectName!,
                  );

                  if (!ctx.mounted) return;
                  if (response != null) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Question added successfully"),
                      ),
                    );
                    _tryLoadQuestions();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to add question"),
                      ),
                    );
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadExcelTemplate() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Template download is only supported on web at the moment"),
        ),
      );
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue("Question no"),
        TextCellValue("Board"),
        TextCellValue("Grade"),
        TextCellValue("Subject"),
        TextCellValue("Question"),
        TextCellValue("Option A"),
        TextCellValue("Option B"),
        TextCellValue("Option C"),
        TextCellValue("Option D"),
        TextCellValue("Correct Option"),
      ]);

      sheet.appendRow([
        TextCellValue("1"),
        TextCellValue("CBSE"),
        TextCellValue("4"),
        TextCellValue("English"),
        TextCellValue('What is the opposite of "Huge"?'),
        TextCellValue("Large"),
        TextCellValue("Tiny"),
        TextCellValue("Big"),
        TextCellValue("Giant"),
        TextCellValue("B"),
      ]);

      for (int col = 0; col < 11; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: col),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          textWrapping: TextWrapping.WrapText,
        );
      }

      sheet.setColumnWidth(0, 12);
      sheet.setColumnWidth(1, 12);
      sheet.setColumnWidth(2, 8);
      sheet.setColumnWidth(3, 14);
      sheet.setColumnWidth(4, 40);
      sheet.setColumnWidth(5, 18);
      sheet.setColumnWidth(6, 18);
      sheet.setColumnWidth(7, 18);
      sheet.setColumnWidth(8, 18);
      sheet.setColumnWidth(9, 16);
      sheet.setColumnWidth(10, 28);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception("Failed to encode Excel file");
      }

      final base64 = base64Encode(bytes);
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(
        href:
            'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64',
      )
        ..setAttribute('download', 'Question_Upload_Template.xlsx')
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template downloaded successfully")),
      );
    } catch (e) {
      debugPrint("Error downloading template: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download template: $e")),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredQuestions {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isEmpty) return _questions;

    return _questions.where((q) {
      final text = q['question_text']?.toString().toLowerCase() ?? '';
      return text.contains(term);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          // Controls row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Search
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primaryTeal),
                    hintText: "Search questions by text...",
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Board dropdown
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Board",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_isLoadingFilters)
                      const SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: _selectedBoardDisplay,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _boards.map((b) {
                          final display = _getBoardDisplayName(b);
                          return DropdownMenuItem(
                            value: display,
                            child: Text(display),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedBoardDisplay = value;
                            final boardMap = _boards.firstWhere(
                              (b) => _getBoardDisplayName(b) == value,
                              orElse: () =>
                                  {'name': value.split(' (').first.trim()},
                            );
                            _selectedBoardClean = _getCleanBoardName(boardMap);
                          });
                          _tryLoadQuestions();
                        },
                        hint: const Text("Select Board"),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Grade dropdown
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Grade",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (_isLoadingFilters)
                      const SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: _selectedGrade,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        items: _grades.map((g) {
                          final name = g['name']?.toString() ?? '?';
                          return DropdownMenuItem(
                            value: name,
                            child: Text("Grade $name"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGrade = value);
                          _tryLoadQuestions();
                        },
                        hint: const Text("Select Grade"),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Action buttons
              _actionBtn(
                "Add Single Question",
                Icons.add_circle_outline,
                Colors.green.shade900,
                onPressed: _showAddQuestionDialog,
              ),
              const SizedBox(width: 12),
              _actionBtn(
                "Upload Excel",
                FontAwesomeIcons.fileExcel,
                Colors.green.shade900,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              _actionBtn(
                "Download Excel Template",
                Icons.download,
                Colors.green.shade900,
                onPressed: _downloadExcelTemplate,
              ),
            ],
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: _buildQuestionListArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionListArea() {
    if (_isLoadingFilters) {
      return const Center(
          child: CircularProgressIndicator(
        color: AppColors.primaryTeal,
      ));
    }

    if (_selectedBoardDisplay == null || _selectedGrade == null) {
      return const Center(
        child: Text(
          "Please select board and grade",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (_isLoadingQuestions) {
      return const Center(
          child: CircularProgressIndicator(
        color: AppColors.primaryTeal,
      ));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _tryLoadQuestions,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final displayed = _filteredQuestions;

    if (displayed.isEmpty) {
      return const Center(child: Text("No questions found"));
    }

    return ListView.separated(
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final q = displayed[index];
        final questionText =
            q['question_text']?.toString() ?? "No question text";
        final grade = q['grade']?.toString() ?? "?";
        final board = q['board']?.toString() ?? "?";
        final subject = q['subject']?.toString() ?? "—";
        final questionId = q['_id']?.toString() ?? q['id']?.toString() ?? '';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          title: Text("Q${index + 1}: $questionText",
              maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text("$grade • $board • $subject"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditDialog(q),
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primaryTeal),
              ),
              IconButton(
                onPressed: questionId.isNotEmpty
                    ? () => _deleteQuestion(questionId)
                    : null,
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.coralRed),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color,
      {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
