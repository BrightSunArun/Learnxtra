// ignore_for_file: deprecated_member_use, avoid_print

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/dashboard/child_code.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:LearnXtraParent/utils/api_exception.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
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

  final List<String> _grades = List.generate(8, (i) => "Grade ${i + 3}");
  final List<String> _indianStates = [
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

  final List<String> _boards = ["CBSE", "ICSE", "State Board", "IB", "IGCSE"];

  late final AppStateController _stateController;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _stateController = Get.find<AppStateController>();
    _apiService = Get.find<ApiService>();
    if (widget.isEdit) {
      loadChildData();
    }
  }

  String? normalizeGradeValue(dynamic gradeVal) {
    if (gradeVal == null) return null;

    final num = int.tryParse(gradeVal.toString().trim()) ??
        double.tryParse(gradeVal.toString().trim())?.toInt();

    if (num != null && num >= 3 && num <= 10) {
      return "Grade $num";
    }
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

      print('DEBUG: child keys     = ${childJson.keys.toList()}');
      print('DEBUG: raw grade      = ${childJson['grade']}');
      print(
          'DEBUG: normalized     = ${normalizeGradeValue(childJson['grade'])}');

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

      if (!mounted) return;

      setState(() {
        _nameController.text = name;
        _ageController.text = ageText;
        _schoolNameController.text = schoolName;
        _schoolAddressController.text = schoolAddress;
        _selectedGrade = gradeNormalized;
        _selectedState = childJson['state']?.toString().trim();
        _selectedBoard = childJson['board']?.toString().trim();
      });

      print('DEBUG: set grade → $_selectedGrade');
      print('DEBUG: grade in list? ${_grades.contains(_selectedGrade)}');
    } catch (e, st) {
      print('ERROR loading child: $e');
      print(st);
      if (mounted) {
        getSnackbar(
          title: "Error",
          message: "Failed to load child: ${e.toString()}",
        );
      }
    }
  }

  Future<void> updateChild() async {
    print("Update child called");

    if (!_formKey.currentState!.validate()) return;

    if (_selectedGrade == null) {
      getSnackbar(
        title: "Error",
        message: "Please select grade",
      );
      return;
    }

    final name = _nameController.text.trim();
    final gradeStr = _selectedGrade!;
    final board = _selectedBoard ?? "CBSE";

    final gradeNumber = int.tryParse(
      gradeStr.replaceAll("Grade ", "").trim(),
    );

    if (gradeNumber == null) {
      getSnackbar(
        title: "Invalid",
        message: "Invalid grade format",
      );
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
        subjects: ["English", "Hindi", "Maths"],
      );

      print("This is the response: $response");

      final childIdFromServer = response['child']['childId'] as String?;
      if (childIdFromServer == null || response['success'] != true) {
        throw Exception("Child update failed - invalid response");
      }

      final newChild = Child(
        id: childIdFromServer,
        parentId: _stateController.currentParentId.value ?? "current_parent_id",
        name: name,
        grade: gradeStr,
        age: _ageController.text.trim().isNotEmpty
            ? int.tryParse(_ageController.text.trim())
            : null,
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

      print("This is the newChild: $newChild");

      _stateController.addChild(newChild);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      getSnackbar(
        title: "Success",
        message: "Child updated successfully!",
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
      getSnackbar(
        title: "Error",
        message: "Please select grade",
      );
      return;
    }

    final name = _nameController.text.trim();
    final gradeStr = _selectedGrade!;
    final board = _selectedBoard ?? "CBSE";

    final gradeNumber = int.tryParse(
      gradeStr.replaceAll("Grade ", "").trim(),
    );

    if (gradeNumber == null) {
      getSnackbar(
        title: "Invalid",
        message: "Invalid grade format",
      );
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
        subjects: ["English", "Hindi", "Maths"],
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
        age: _ageController.text.trim().isNotEmpty
            ? int.tryParse(_ageController.text.trim())
            : null,
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

      print("This is the newChild: $newChild");

      _stateController.addChild(newChild);

      if (!mounted) return;

      getSnackbar(
        title: "Success",
        message: "Child added successfully!",
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildConnectionCodeScreen(
            childId: childIdFromServer,
            childName: name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      String errorMsg = "Failed to add child";
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

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
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
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(fontSize: 15),
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
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1,
              ),
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
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.gray500,
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: SizedBox.shrink(),
        title: Text(
          widget.isEdit ? "Edit your child details" : "Add your child",
          style: TextStyle(
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
          child: SafeArea(
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
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray900,
                      ),
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
                    buildTextField(
                      label: "Child's Full Name",
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
                      onChanged: (val) => setState(
                        () => _selectedGrade = val,
                      ),
                      validator: (v) =>
                          v == null ? "Please select grade" : null,
                    ),
                    const SizedBox(height: 14),
                    buildTextField(
                      label: "Age",
                      controller: _ageController,
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
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
                      onChanged: (val) => setState(
                        () => _selectedBoard = val,
                      ),
                      validator: (v) =>
                          v == null ? "Please select board" : null,
                    ),
                    const SizedBox(height: 14),
                    buildDropdown(
                      label: "State",
                      value: _selectedState,
                      items: _indianStates,
                      icon: Icons.map_outlined,
                      onChanged: (val) => setState(
                        () => _selectedState = val,
                      ),
                      validator: (v) =>
                          v == null ? "Please select state" : null,
                    ),
                    const SizedBox(height: 14),
                    buildTextField(
                      label: "School Name",
                      controller: _schoolNameController,
                      icon: Icons.school,
                      validator: (v) => v?.trim().isEmpty ?? true
                          ? "Please enter school name"
                          : null,
                    ),
                    const SizedBox(height: 14),
                    buildTextField(
                      label: "School Address",
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
                      child: Text(
                        widget.isEdit
                            ? "Update Child Details"
                            : "Generate Connection Code",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
