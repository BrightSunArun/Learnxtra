// ignore_for_file: deprecated_member_use, avoid_print

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/analytics/child_settings.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:LearnXtraParent/utils/api_exception.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../models/child.dart';

class AddChildScreen extends StatefulWidget {
  final String? childId;
  final bool isEdit;

  const AddChildScreen({
    super.key,
    this.childId,
    this.isEdit = false,
  });

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolAddressController = TextEditingController();

  String? _selectedGrade;
  String? _selectedState;
  String? _selectedBoard;

  List<String> _grades = [];
  List<String> _boards = [];

  bool _isLoadingReferenceData = true;
  String? _loadError;

  final List<String> _indianStates = [
    // Union Territories
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry",

    // States
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
  ];

  late final AppStateController _stateController;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _stateController = Get.find<AppStateController>();
    _apiService = Get.find<ApiService>();

    _loadReferenceData();

    if (widget.isEdit && widget.childId != null) {
      loadChildData();
    }
  }

  Future<void> _loadReferenceData() async {
    setState(() {
      _isLoadingReferenceData = true;
      _loadError = null;
    });

    try {
      // Fetch both in parallel
      final results = await Future.wait([
        _apiService.getGrades(),
        _apiService.getBoards(),
      ]);

      final gradesResp = results[0];
      final boardsResp = results[1];

      List<String> fetchedGrades = [];
      List<String> fetchedBoards = [];

      // Handle grades response — show data[].name in dropdown
      if (gradesResp is List) {
        fetchedGrades = gradesResp
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (gradesResp is Map && gradesResp['data'] is List) {
        fetchedGrades = (gradesResp['data'] as List)
            .map((e) => (e is Map ? e['name']?.toString() : e.toString()) ?? '')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // Handle boards response — show data[].name in dropdown
      if (boardsResp is List) {
        fetchedBoards = boardsResp
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (boardsResp is Map) {
        if (boardsResp['data'] is List) {
          fetchedBoards = (boardsResp['data'] as List)
              .map((e) =>
                  (e is Map ? e['name']?.toString() : e.toString()) ?? '')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (boardsResp['boards'] is List) {
          fetchedBoards = (boardsResp['boards'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      if (mounted) {
        setState(() {
          _grades = fetchedGrades.isNotEmpty
              ? fetchedGrades
              : List.generate(8, (i) => "Grade ${i + 3}");

          _boards = fetchedBoards.isNotEmpty
              ? fetchedBoards
              : ["CBSE", "ICSE", "State Board", "IB", "IGCSE"];

          _isLoadingReferenceData = false;
        });
      }
    } catch (e, st) {
      print("Failed to load grades/boards: $e");
      print(st);

      if (mounted) {
        setState(() {
          _isLoadingReferenceData = false;
          _loadError = "Failed to load grades & boards. Using defaults.";
        });

        getSnackbar(
          title: "Connection Issue",
          message: "Couldn't load latest grades/boards. Using fallback values.",
        );
      }
    }
  }

  String? normalizeGradeValue(dynamic gradeVal) {
    if (gradeVal == null) return null;

    final str = gradeVal.toString().trim().toLowerCase();

    // Try to match "Grade 6", "6", "grade 6", "VI" etc.
    final num = int.tryParse(str.replaceAll(RegExp(r'[^0-9]'), ''));

    if (num != null && num >= 1 && num <= 12) {
      // Check if API uses "Grade X" format
      if (_grades.any((g) => g.toLowerCase().contains("grade"))) {
        return "Grade $num";
      }
      // Or just number
      else if (_grades.contains(num.toString())) {
        return num.toString();
      }
    }

    // Exact match attempt
    final exact = _grades.firstWhere(
      (g) => g.toLowerCase() == str,
      orElse: () => "",
    );

    if (exact.isNotEmpty) return exact;

    return null;
  }

  Future<void> loadChildData() async {
    if (widget.childId == null) return;

    try {
      final resp = await _apiService.getChildDetails(widget.childId!);

      print('DEBUG: response type = ${resp.runtimeType}');
      print('DEBUG: raw response  = $resp');

      Map<String, dynamic> childJson;
      if (resp['success'] == true && resp['child'] is Map<String, dynamic>) {
        childJson = Map<String, dynamic>.from(resp['child']);
      } else {
        childJson = Map<String, dynamic>.from(resp);
      }

      final name = childJson['name']?.toString().trim() ?? '';

      final ageRaw = childJson['age'];
      final ageText = ageRaw is num
          ? ageRaw.toInt().toString()
          : ageRaw?.toString().trim() ?? '';

      final schoolName = childJson['schoolName']?.toString().trim() ??
          childJson['school']?.toString().trim() ??
          '';

      final schoolAddress = childJson['schoolAddress']?.toString().trim() ?? '';

      final gradeNormalized = normalizeGradeValue(childJson['grade']);
      final boardFromServer = childJson['board']?.toString().trim();

      if (!mounted) return;

      setState(() {
        _nameController.text = name;
        _ageController.text = ageText;
        _schoolNameController.text = schoolName;
        _schoolAddressController.text = schoolAddress;
        _selectedGrade = _grades.contains(gradeNormalized)
            ? gradeNormalized
            : null; // only set if valid
        _selectedBoard =
            _boards.contains(boardFromServer) ? boardFromServer : null;
        _selectedState = childJson['state']?.toString().trim();
      });

      print('DEBUG: set grade → $_selectedGrade');
      print('DEBUG: set board → $_selectedBoard');
    } catch (e, st) {
      print('ERROR loading child: $e');
      print(st);
      if (mounted) {
        getSnackbar(
          title: "Error",
          message: "Failed to load child details: ${e.toString()}",
        );
      }
    }
  }

  Future<void> updateChild() async {
    print("Update child called");

    if (!_formKey.currentState!.validate()) return;

    if (_selectedGrade == null) {
      getSnackbar(title: "Error", message: "Please select grade");
      return;
    }

    if (_selectedBoard == null) {
      getSnackbar(title: "Error", message: "Please select board");
      return;
    }

    final name = _nameController.text.trim();
    final gradeStr = _selectedGrade!;
    final board = _selectedBoard!;

    // Extract numeric grade value
    final gradeNumber = int.tryParse(
      gradeStr.replaceAll(RegExp(r'[^0-9]'), '').trim(),
    );

    if (gradeNumber == null) {
      getSnackbar(title: "Invalid", message: "Invalid grade format");
      return;
    }

    try {
      final response = await _apiService.updateChildProfile(
        childId: widget.childId!,
        name: name,
        grade: gradeNumber,
        board: board,
        state: _selectedState!,
        age: int.parse(_ageController.text.trim()),
        schoolName: _schoolNameController.text.trim(),
        schoolAddress: _schoolAddressController.text.trim(),
        subjects: ["English", "Hindi", "Maths"], // ← still hardcoded
      );

      print("Update response: $response");

      final childIdFromServer = response['child']?['childId']?.toString() ??
          response['childId']?.toString();

      if (childIdFromServer == null || response['success'] != true) {
        throw Exception("Child update failed - invalid response");
      }

      final newChild = Child(
        id: childIdFromServer,
        parentId: _stateController.currentParentId.value ?? "current_parent_id",
        name: name,
        grade: gradeStr,
        age: int.tryParse(_ageController.text.trim()),
        state: _selectedState,
        board: board,
        schoolName: _schoolNameController.text.trim().isNotEmpty
            ? _schoolNameController.text.trim()
            : null,
        schoolAddress: _schoolAddressController.text.trim().isNotEmpty
            ? _schoolAddressController.text.trim()
            : null,
        strongSubjects: [],
        weakSubjects: [],
        createdAt: DateTime.now(),
      );

      _stateController.addChild(newChild);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      getSnackbar(
        title: "Success",
        message: "Child updated successfully!",
      );
    } catch (e) {
      if (!mounted) return;

      String errorMsg = "Failed to update child";
      if (e is ApiException) {
        errorMsg = e.message;
      } else {
        errorMsg = e.toString();
      }

      getSnackbar(
        title: "Error",
        message: errorMsg,
      );
    }
  }

  Future<void> submitChild() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGrade == null) {
      getSnackbar(title: "Error", message: "Please select grade");
      return;
    }

    if (_selectedBoard == null) {
      getSnackbar(title: "Error", message: "Please select board");
      return;
    }

    final name = _nameController.text.trim();
    final gradeStr = _selectedGrade!;
    final board = _selectedBoard!;

    final gradeNumber = int.tryParse(
      gradeStr.replaceAll(RegExp(r'[^0-9]'), '').trim(),
    );

    if (gradeNumber == null) {
      getSnackbar(title: "Invalid", message: "Invalid grade format");
      return;
    }

    try {
      final response = await _apiService.addChild(
        name: name,
        grade: gradeNumber,
        board: board,
        state: _selectedState!,
        age: int.parse(_ageController.text.trim()),
        schoolName: _schoolNameController.text.trim(),
        schoolAddress: _schoolAddressController.text.trim(),
      );

      final childIdFromServer = response['childId'] as String?;
      if (childIdFromServer == null || response['success'] != true) {
        throw Exception("Child creation failed - invalid response");
      }

      final newChild = Child(
        id: childIdFromServer,
        parentId: _stateController.currentParentId.value ?? "current_parent_id",
        name: name,
        grade: gradeStr,
        age: int.tryParse(_ageController.text.trim()),
        state: _selectedState,
        board: board,
        schoolName: _schoolNameController.text.trim().isNotEmpty
            ? _schoolNameController.text.trim()
            : null,
        schoolAddress: _schoolAddressController.text.trim().isNotEmpty
            ? _schoolAddressController.text.trim()
            : null,
        strongSubjects: [],
        weakSubjects: [],
        createdAt: DateTime.now(),
      );

      _stateController.addChild(newChild);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ChildScreenTimeSettings(
            childId: childIdFromServer,
            childName: name,
            calledFrom: "add_child",
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      String errorMsg = "Failed to add child";
      if (e is ApiException) errorMsg = e.message;

      getSnackbar(
        title: "Error",
        message: errorMsg,
      );
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter> inputFormatters = const [],
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.gray500, size: 22),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.gray500, size: 22),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingReferenceData) {
      return Scaffold(
        appBar: AppBar(title: const Text("Add your child")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading grades & boards..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Text(
          widget.isEdit ? "Edit your child details" : "Add your child",
          style: const TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.isEdit
                        ? "Added something wrong? Edit your child details"
                        : "Let's get started with their learning journey",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              AppColors.primaryTeal.withOpacity(0.1),
                          child: const Icon(
                            Icons.child_care,
                            size: 50,
                            color: AppColors.gray400,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Show error if API failed but we have fallback
                  if (_loadError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: Colors.orange.shade900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  buildTextField(
                    label: "Child's Full Name",
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    icon: Icons.person_outline,
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? "Please enter child's name"
                        : null,
                  ),
                  const SizedBox(height: 14),

                  buildDropdown(
                    label: "Grade",
                    value: _selectedGrade,
                    items: _grades,
                    icon: Icons.school_outlined,
                    onChanged: (val) => setState(() => _selectedGrade = val),
                    validator: (v) => v == null ? "Please select grade" : null,
                  ),
                  const SizedBox(height: 14),

                  buildTextField(
                    label: "Age",
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    keyboardType: TextInputType.number,
                    controller: _ageController,
                    icon: Icons.cake_outlined,
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? "Please enter child's age"
                        : null,
                  ),
                  const SizedBox(height: 14),

                  buildDropdown(
                    label: "Education Board",
                    value: _selectedBoard,
                    items: _boards,
                    icon: Icons.book_outlined,
                    onChanged: (val) => setState(() => _selectedBoard = val),
                    validator: (v) => v == null ? "Please select board" : null,
                  ),
                  const SizedBox(height: 14),

                  buildDropdown(
                    label: "State",
                    value: _selectedState,
                    items: _indianStates,
                    icon: Icons.map_outlined,
                    onChanged: (val) => setState(() => _selectedState = val),
                    validator: (v) => v == null ? "Please select state" : null,
                  ),
                  const SizedBox(height: 14),

                  buildTextField(
                    label: "School Name",
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    controller: _schoolNameController,
                    icon: Icons.school,
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? "Please enter school name"
                        : null,
                  ),
                  const SizedBox(height: 14),

                  buildTextField(
                    label: "School Address",
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    controller: _schoolAddressController,
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? "Please enter school address"
                        : null,
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: widget.isEdit ? updateChild : submitChild,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isEdit
                              ? "Update Child Details"
                              : "Proceed to Next",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!widget.isEdit) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    super.dispose();
  }
}
