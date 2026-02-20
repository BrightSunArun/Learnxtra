// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/main_navigation.dart';
import 'package:LearnXtraParent/services/api_service.dart';
import 'package:LearnXtraParent/services/local_storage.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';

class ParentProfileSetupScreen extends StatefulWidget {
  final String? mobileNumber;
  final String? calledFrom;

  const ParentProfileSetupScreen({
    super.key,
    this.mobileNumber,
    this.calledFrom,
  });

  @override
  State<ParentProfileSetupScreen> createState() =>
      _ParentProfileSetupScreenState();
}

class _ParentProfileSetupScreenState extends State<ParentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  String? _profileImageUrl;

  late final AppStateController _stateController;
  late final ApiService _apiService;

  bool _isLoading = false;
  bool _isFetchingProfile = false;

  @override
  void initState() {
    super.initState();
    _stateController = Get.find<AppStateController>();
    _apiService = Get.find<ApiService>();

    if (widget.calledFrom == "settings") {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isFetchingProfile = true);

    try {
      final profile = await _apiService.getParentProfile();

      _fullNameController.text = profile['fullName'];
      _emailController.text = profile['email'];
      _addressController.text = profile['address'];
      _pinCodeController.text = profile['pinCode'];

      final imageUrl = profile['profileImageUrl'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() => _profileImageUrl = imageUrl);
      }

      await LocalStorage.saveParentProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        address: _addressController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        imageUrl: _profileImageUrl,
      );
    } catch (e) {
      print("Error loading parent profile: $e");
      if (mounted) {
        getSnackbar(
          title: "Error",
          message: "Failed to load profile data. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingProfile = false);
      }
    }
  }

  void _handleImagePick() {
    getSnackbar(
      title: "Coming soon",
      message: 'Image picker not implemented yet (Placeholder)',
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null;
      final address = _addressController.text.trim();
      final pinCode = _pinCodeController.text.trim();

      final mobileNumber = await LocalStorage.getMobileNumber();
      print("Mobile Number: $mobileNumber");

      final response = await _apiService.createParentProfile(
        fullName: fullName,
        email: email ?? "",
        profileImageUrl: _profileImageUrl ?? "",
        address: address,
        pinCode: pinCode,
        mobileNumber: widget.mobileNumber ?? mobileNumber!,
      );

      print("API Profile Response: $response");

      await LocalStorage.saveParentProfile(
        fullName: fullName,
        email: email,
        address: address,
        pinCode: pinCode,
        imageUrl: _profileImageUrl,
      );

      await _stateController.completeProfile();

      if (!mounted) return;

      getSnackbar(
        title: "Success",
        message: 'Profile setup completed!',
      );

      Get.offAll(() => const MainNavigation());
    } catch (e) {
      print("Profile setup error: $e");

      String errorMsg = "Failed to save profile. Please try again.";
      if (e.toString().contains("401")) {
        errorMsg = "Session expired. Please login again.";
      } else if (e.toString().contains("mobile_number")) {
        errorMsg = "Mobile number is required.";
      }

      if (mounted) {
        getSnackbar(
          title: "Error",
          message: errorMsg,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null;
      final address = _addressController.text.trim();
      final pinCode = _pinCodeController.text.trim();

      final response = await _apiService.updateParentProfile(
        fullName: fullName,
        email: email ?? "",
        profileImageUrl: _profileImageUrl ?? "",
        address: address,
        pinCode: int.parse(pinCode),
      );

      print("Profile updated successfully: $response");

      getSnackbar(
        title: "Success",
        message: 'Profile updated successfully!',
      );

      Navigator.pop(context, true);

      await LocalStorage.saveParentProfile(
        fullName: fullName,
        email: email,
        address: address,
        pinCode: pinCode,
        imageUrl: _profileImageUrl,
      );
    } catch (e) {
      print("Profile update error: $e");

      String errorMsg = "Failed to update profile. Please try again.";
      if (e.toString().contains("401")) {
        errorMsg = "Session expired. Please login again.";
      }

      if (mounted) {
        getSnackbar(
          title: "Error",
          message: errorMsg,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Text(
          widget.calledFrom == "settings" ? "Update Profile" : "Setup Profile",
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
        child: _isFetchingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      widget.calledFrom == "settings"
                          ? const SizedBox.shrink()
                          : Text(
                              "Tell us a bit about yourself",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.gray900,
                              ),
                            ),
                      const SizedBox(height: 30),

                      // Profile Picture
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  AppColors.primaryTeal.withOpacity(0.1),
                              backgroundImage: _profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.gray400,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _handleImagePick,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryTeal,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Full Name
                      _buildTextField(
                        label: "Full Name",
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                          LengthLimitingTextInputFormatter(50),
                        ],
                        controller: _fullNameController,
                        icon: Icons.person_outline,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email (Optional)
                      _buildTextField(
                        textCapitalization: TextCapitalization.none,
                        label: "Email (Optional)",
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        label: "Address",
                        textCapitalization: TextCapitalization.words,
                        controller: _addressController,
                        icon: Icons.home_outlined,
                        maxLines: 2,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter your address'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Pin Code
                      _buildTextField(
                        label: "Pin Code",
                        textCapitalization: TextCapitalization.none,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        controller: _pinCodeController,
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'Please enter your pin code';
                          if (val.length != 6 ||
                              !RegExp(r'^\d{6}$').hasMatch(val)) {
                            return 'Pin code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : widget.calledFrom == "settings"
                                ? _updateProfile
                                : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.calledFrom == "settings"
                                    ? "Update Profile"
                                    : "Save & Continue",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter> inputFormatters = const [],
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
        const SizedBox(height: 5),
        TextFormField(
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(fontSize: 16, color: AppColors.textDark),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, color: AppColors.gray500, size: 22),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryTeal, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryTeal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }
}
