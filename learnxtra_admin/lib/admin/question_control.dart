// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuestionsControlsPage extends StatefulWidget {
  const QuestionsControlsPage({super.key});

  @override
  State<QuestionsControlsPage> createState() => _QuestionsControlsPageState();
}

class _QuestionsControlsPageState extends State<QuestionsControlsPage> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchBoards(),
      _fetchGrades(),
      _fetchSubjects(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchBoards() async {
    final res = await _apiService.getBoards();
    if (res == null || !mounted) return;
    final raw = res['data'] ?? res['boards'];
    if (raw is List) {
      setState(() => _boards = raw.cast<Map<String, dynamic>>());
    }
  }

  Future<void> _fetchGrades() async {
    final res = await _apiService.getGrades();
    if (res == null || !mounted) return;
    final raw = res['data'] ?? res['grades'];
    if (raw is List) {
      setState(() => _grades = raw.cast<Map<String, dynamic>>());
    }
  }

  Future<void> _fetchSubjects() async {
    final res = await _apiService.getSubjects();
    if (res == null || !mounted) return;
    final raw = res['data'] ?? res['subjects'];
    if (raw is List) {
      setState(() => _subjects = raw.cast<Map<String, dynamic>>());
    }
  }

  int _getId(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    final sid = item['_id']?.toString();
    return int.tryParse(sid ?? '') ?? 0;
  }

  String _getUniqueBoardId(Map<String, dynamic> board) {
    final ubid = board['unique_board_id']?.toString();
    return ubid != null && ubid.isNotEmpty ? ubid : '';
  }

  String _getBoardDisplayName(Map<String, dynamic> board) {
    final name = board['name']?.toString() ?? 'Unnamed';
    final ubid = _getUniqueBoardId(board);
    return ubid.isNotEmpty ? '$name ($ubid)' : name;
  }

  Map<String, dynamic>? _findBoardByUniqueId(String uniqueBoardId) {
    for (final b in _boards) {
      if (_getUniqueBoardId(b) == uniqueBoardId) return b;
    }
    return null;
  }

  void _showValidationAlert(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid value'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static bool _isValidBoardName(String value) {
    return value.trim().isNotEmpty;
  }

  static bool _isValidGradeName(String value) {
    final s = value.trim();
    if (s.isEmpty || s.length > 2) return false;
    return RegExp(r'^\d+$').hasMatch(s);
  }

  static bool _isValidSubjectName(String value) {
    final s = value.trim();
    return s.isNotEmpty;
  }

  void _showCreateBoardDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add Board'),
        content: TextField(
          controller: nameCtrl,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. ICSE',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (!_isValidBoardName(nameCtrl.text)) {
                _showValidationAlert('Board name must be a non-empty string.');
                return;
              }
              final result = await _apiService.createBoard(name: name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (result != null) {
                await _fetchBoards();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditBoardDialog(Map<String, dynamic> board) {
    final nameCtrl =
        TextEditingController(text: board['name']?.toString() ?? '');
    final id = _getId(board);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit Board'),
        content: TextField(
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          ],
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (!_isValidBoardName(nameCtrl.text)) {
                _showValidationAlert('Board name must be a non-empty string.');
                return;
              }
              final result = await _apiService.updateBoard(id: id, name: name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (result != null) {
                await _fetchBoards();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBoard(int boardId) async {
    final ok = await _apiService.deleteBoard(boardId);
    if (!mounted) return;
    if (ok) {
      await _fetchBoards();
    }
  }

  void _showCreateGradeDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add Grade'),
        content: TextField(
          controller: nameCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: const InputDecoration(
            labelText: 'Grade name',
            hintText: 'e.g. 6',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (!_isValidGradeName(nameCtrl.text)) {
                _showValidationAlert(
                  'Grade must be digits only and at most 2 digits (e.g. 6 or 12).',
                );
                return;
              }
              final result = await _apiService.createGrade(name: name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (result != null) {
                await _fetchGrades();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGradeDialog(Map<String, dynamic> grade) {
    final nameCtrl =
        TextEditingController(text: grade['name']?.toString() ?? '');
    final gradeId = _getId(grade);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit Grade'),
        content: TextField(
          controller: nameCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: const InputDecoration(labelText: 'Grade name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (!_isValidGradeName(nameCtrl.text)) {
                _showValidationAlert(
                  'Grade must be digits only and at most 2 digits (e.g. 6 or 12).',
                );
                return;
              }
              final result =
                  await _apiService.updateGrade(id: gradeId, name: name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (result != null) {
                await _fetchGrades();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGrade(int gradeId) async {
    final ok = await _apiService.deleteGrade(gradeId);
    if (!mounted) return;
    if (ok) {
      await _fetchGrades();
    }
  }

  // ── ADD SUBJECT ───────────────────────────────────────────────────────────────
  void _showCreateSubjectDialog() {
    if (_grades.isEmpty || _boards.isEmpty) return;

    final nameCtrl = TextEditingController();

    int? selectedGradeId;
    String? selectedBoardUniqueId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grade Dropdown
              DropdownButtonFormField<int>(
                dropdownColor: Colors.white,
                value: selectedGradeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select Grade'),
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
                    // Reset board when grade changes (force explicit selection)
                    selectedBoardUniqueId = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Board Dropdown
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: selectedBoardUniqueId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Board',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select Board'),
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
                  });
                },
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameCtrl,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Subject name',
                  hintText: 'e.g. Science',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (!_isValidSubjectName(nameCtrl.text)) {
                  _showValidationAlert(
                    'Subject name must be a non-empty string.',
                  );
                  return;
                }
                if (selectedGradeId == null || selectedBoardUniqueId == null) {
                  _showValidationAlert(
                    'Please select both Grade and Board.',
                  );
                  return;
                }

                final result = await _apiService.createSubject(
                  gradeId: selectedGradeId!,
                  boardId: selectedBoardUniqueId!,
                  name: name,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (result != null) {
                  await _fetchSubjects();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── EDIT SUBJECT ──────────────────────────────────────────────────────────────
  void _showEditSubjectDialog(Map<String, dynamic> subject) {
    final nameCtrl =
        TextEditingController(text: subject['name']?.toString() ?? '');
    final subjectId = _getId(subject);

    int? selectedGradeId = subject['grade_id'] is int
        ? subject['grade_id']
        : int.tryParse(subject['grade_id']?.toString() ?? '');

    String? selectedBoardUniqueId = subject['board_id']?.toString() ??
        subject['unique_board_id']?.toString() ??
        subject['board_unique_id']?.toString();

    // Fallback if missing
    if (selectedGradeId == null && _grades.isNotEmpty) {
      selectedGradeId = _getId(_grades.first);
    }
    if (selectedBoardUniqueId == null && _boards.isNotEmpty) {
      selectedBoardUniqueId = _getUniqueBoardId(_boards.first);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grade Dropdown
              DropdownButtonFormField<int>(
                dropdownColor: Colors.white,
                value: selectedGradeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
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
                    // Reset board on grade change
                    selectedBoardUniqueId = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Board Dropdown
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: selectedBoardUniqueId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Board',
                  border: OutlineInputBorder(),
                ),
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
                  });
                },
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameCtrl,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Subject name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (!_isValidSubjectName(nameCtrl.text)) {
                  _showValidationAlert(
                    'Subject name must be a non-empty string.',
                  );
                  return;
                }
                if (selectedGradeId == null || selectedBoardUniqueId == null) {
                  _showValidationAlert(
                    'Please select both Grade and Board.',
                  );
                  return;
                }

                final result = await _apiService.updateSubject(
                  id: subjectId,
                  gradeId: selectedGradeId!,
                  boardId: selectedBoardUniqueId!,
                  name: name,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (result != null) {
                  await _fetchSubjects();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubject(int subjectId) async {
    final ok = await _apiService.deleteSubject(subjectId);
    if (!mounted) return;
    if (ok) {
      await _fetchSubjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Controls',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage the Boards → then Grades → and then Subjects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(
                color: AppColors.primaryTeal,
              )),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1100;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBoardsSection()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildGradesSection()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildSubjectsSection()),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBoardsSection(),
                          const SizedBox(height: 24),
                          _buildGradesSection(),
                          const SizedBox(height: 24),
                          _buildSubjectsSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardsSection() {
    return _section(
      title: 'Boards',
      addLabel: 'Add Board',
      onAdd: _showCreateBoardDialog,
      items: _boards,
      buildItem: (b) {
        final id = _getId(b);
        final ubid = _getUniqueBoardId(b);
        return _listTile(
          title: b['name']?.toString() ?? 'Board $id',
          subtitle: ubid.isNotEmpty ? ubid : null,
          onEdit: () => _showEditBoardDialog(b),
          onDelete: () => _deleteBoard(id),
        );
      },
    );
  }

  Widget _buildGradesSection() {
    return _section(
      title: 'Grades',
      addLabel: 'Add Grade',
      onAdd: _showCreateGradeDialog,
      items: _grades,
      buildItem: (g) {
        final id = _getId(g);
        return _listTile(
          title: 'Grade ${g['name']?.toString() ?? id}',
          onEdit: () => _showEditGradeDialog(g),
          onDelete: () => _deleteGrade(id),
        );
      },
    );
  }

  Widget _buildSubjectsSection() {
    return _section(
      title: 'Subjects',
      addLabel: 'Add Subject',
      onAdd: _showCreateSubjectDialog,
      items: _subjects,
      buildItem: (s) {
        final name = s['name']?.toString() ?? 'Subject ${_getId(s)}';
        final sbid = s['unique_subject_id']?.toString() ?? '';
        final boardIdStr = s['board_id']?.toString() ?? '';
        final board = _findBoardByUniqueId(boardIdStr);
        final boardDisplay =
            board != null ? _getBoardDisplayName(board) : 'Board $boardIdStr';

        String subtitle = name;
        if (sbid.isNotEmpty) {
          subtitle = '$sbid • $boardDisplay';
        } else if (boardDisplay.isNotEmpty) {
          subtitle = boardDisplay;
        }

        return _listTile(
          title: name,
          subtitle: subtitle,
          onEdit: () => _showEditSubjectDialog(s),
          onDelete: () => _deleteSubject(_getId(s)),
        );
      },
    );
  }

  Widget _section({
    required String title,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) buildItem,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.maxHeight != double.infinity;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onAdd,
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      addLabel,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasBoundedHeight)
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No ${title.toLowerCase()} yet',
                              style: TextStyle(
                                color: AppColors.mutedTeal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => buildItem(
                            items[index],
                          ),
                        ),
                )
              else
                items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No ${title.toLowerCase()} yet',
                            style: TextStyle(
                                color: AppColors.mutedTeal, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            buildItem(items[index]),
                      ),
            ],
          );
        },
      ),
    );
  }

  Widget _listTile({
    required String title,
    String? subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      dense: true,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          if (subtitle != null && subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 13,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.coralRed,
            ),
          ),
        ],
      ),
    );
  }
}
