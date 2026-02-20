// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:LearnXtraChild/src/utils/api_exception.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:LearnXtraChild/src/screens/auth/bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkDeviceScreen extends StatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final _apiService = Get.find<ApiService>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> saveProfileData(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();

    final parent = response['parent'] as Map<String, dynamic>;
    final child = response['child'] as Map<String, dynamic>;

    await prefs.setString('parent_data', jsonEncode(parent));
    await prefs.setString('child_data', jsonEncode(child));
  }

  Future<void> _handleLink() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim().toUpperCase();

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.linkChildDevice(
        childLinkCode: code,
        deviceUuid: "123",
      );

      print("here is response: $response");

      if (response['success'] == true) {
        final controller = Get.find<AppStateController>();

        controller.isLinked.value = true;
        controller.childId.value = response['child']['id'] ?? '';
        controller.deviceId.value = response['deviceId'] ?? '';
        controller.parentId.value = response['parentId'] ?? '';

        await controller.saveState();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('childId', response['child']['id']);
        await prefs.setString('parentId', response['parent']['id']);

        saveProfileData(response);

        Fluttertoast.showToast(
          msg: "Device linked successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.offAll(() => const PersistentNavBar());
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? "Linking failed",
          backgroundColor: Colors.orange,
        );
      }
    } on ApiException catch (e) {
      String msg;

      if (e.statusCode == 400) {
        msg = "Invalid or expired code. Please check.";
      } else if (e.statusCode == 404) {
        msg = "Code not found.";
      } else if (e.statusCode == 409) {
        msg = "This device is already linked elsewhere.";
      } else if (e.statusCode! >= 500) {
        msg = "Server error. Please try again later.";
      } else {
        msg = e.message;
      }

      Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    } catch (e) {
      print("catch block: $e");
      Fluttertoast.showToast(
        msg: "Something went wrong. Please try again.",
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        elevation: 8,
        surfaceTintColor: AppColors.primaryTeal,
        shadowColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        scrolledUnderElevation: 8,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Connect with Parent",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              Text(
                  "Enter the code from parent app\nor scan QR code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  enabled: !_isLoading,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "XXXXXX",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.primaryTeal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.primaryTeal),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primaryTeal,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim().toUpperCase();
                    if (trimmed.isEmpty) {
                      return 'Please enter the code';
                    }
                    if (trimmed.length != 6) {
                      return 'Code must be exactly 6 characters';
                    }
                    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(trimmed)) {
                      return 'Use letters (A-Z) and numbers only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLink,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(fontSize: 20),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
