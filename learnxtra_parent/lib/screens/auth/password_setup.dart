// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'package:LearnXtraParent/services/api_service.dart';

class ParentPasswordSetupScreen extends StatefulWidget {
  const ParentPasswordSetupScreen({super.key});

  @override
  State<ParentPasswordSetupScreen> createState() =>
      _ParentPasswordSetupScreenState();
}

class _ParentPasswordSetupScreenState extends State<ParentPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isPinAlreadySet = false;
  bool _isCheckingStatus = true;

  final ApiService _apiService = Get.find<ApiService>();

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    setState(() => _isCheckingStatus = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parentId');
      if (parentId == null) {
        getSnackbar(
          title: "Error",
          message: "Parent ID not found. Please login again.",
        );
        return;
      }

      final response = await _apiService.getParentPinStatus(
        parentId: parentId,
      );

      final bool hasPin = response['hasPin'] == true ||
          response['pinSet'] == true ||
          response['status'] == 'set';

      setState(() {
        _isPinAlreadySet = hasPin;
        _isCheckingStatus = false;
      });
    } catch (e) {
      print("Error fetching PIN status: $e");
      getSnackbar(
        title: "Error",
        message: "Could not load parent PIN status. Please try again.",
      );
      setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _savePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parentId');
      if (parentId == null) {
        getSnackbar(
          title: "Error",
          message: "Parent ID not found. Please login again.",
        );
        return;
      }

      if (_isPinAlreadySet) {
        // Change PIN
        final response = await _apiService.changeParentPin(
          parentId: parentId,
          oldPin: _oldPinController.text.trim(),
          newPin: _newPinController.text.trim(),
        );
        print(" \n\nThis is the response from save pin $response");

        if (response['success'] == true) {
          getSnackbar(
            title: "Success",
            message: "Parent mode PIN changed successfully",
          );
        }
      } else {
        // Set new PIN
        final response = await _apiService.setParentPin(
          parentId: parentId,
          pinCode: _newPinController.text.trim(),
        );
        print(" \n\nThis is the response from save pin $response");
        if (response['success'] == true) {
          getSnackbar(
            title: "Success",
            message: "Parent mode PIN changed successfully",
          );
        }
        setState(() => _isPinAlreadySet = true);
      }

      Get.back();
    } catch (e) {
      // ignore: unused_local_variable
      String message = "Failed to update parent PIN";
      if (e.toString().contains("401") || e.toString().contains("403")) {
        message = "Session expired. Please login again.";
      } else if (e.toString().contains("old pin")) {
        message = "Incorrect old PIN. Please try again.";
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validatePin(String? value, {bool isOld = false}) {
    if (value == null || value.isEmpty) {
      return 'Please enter PIN';
    }
    if (value.length != 6) {
      return 'PIN must be 6 digits';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your PIN';
    }
    if (value != _newPinController.text) {
      return 'PINs do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Parent Mode PIN",
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primaryTeal,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final title = _isPinAlreadySet ? "Change Parent PIN" : "Set Parent PIN";
    final subtitle = _isPinAlreadySet
        ? "Enter your current PIN and set a new one."
        : "Create a 6-digit PIN to protect parent controls.";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isPinAlreadySet) ...[
                        TextFormField(
                          textCapitalization: TextCapitalization.none,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          controller: _oldPinController,
                          obscureText: _obscureOld,
                          validator: (v) => _validatePin(v, isOld: true),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Current PIN',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureOld
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureOld = !_obscureOld),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            counterText: "",
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // New PIN
                      TextFormField(
                        textCapitalization: TextCapitalization.none,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        controller: _newPinController,
                        obscureText: _obscureNew,
                        validator: _validatePin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'New PIN',
                          hintText: '6 digits',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: "",
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),

                      // Confirm PIN
                      TextFormField(
                        textCapitalization: TextCapitalization.none,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        validator: _validateConfirm,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Confirm New PIN',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: "",
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _savePin(),
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _savePin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          label: Text(
                            _isLoading
                                ? 'Saving...'
                                : (_isPinAlreadySet ? 'Change PIN' : 'Set PIN'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          "• Use a strong, unique PIN\n"
                          "• Required to access Parent Mode",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Go Back",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
