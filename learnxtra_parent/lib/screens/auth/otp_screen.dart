// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/main_navigation.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../profile_setup/parent_profile_setup_screen.dart';

class OTPScreen extends StatefulWidget {
  final String mobileNumber;

  const OTPScreen({
    super.key,
    required this.mobileNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final api = Get.find<ApiService>();
  bool _isVerifying = false;
  late final AppStateController _stateController;

  @override
  void initState() {
    super.initState();
    _stateController = Get.find<AppStateController>();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isVerifying = true);
    try {
      final otp = _pinController.text.trim();

      if (otp.length != 6) {
        throw Exception("Please enter complete 6-digit OTP");
      }
      final result = await api.verifyOtp(
        mobileNumber: widget.mobileNumber,
        otp: otp,
      );

      print("Verify OTP response: $result");

      if (!mounted) return;

      if (result['success'] == true) {
        final accessToken = result['accessToken'] as String?;
        final refreshToken = result['refreshToken'] as String?;
        final parentId = result['parentId'] as String?;
        final isNewUser = result['isNewUser'] as bool? ?? false;

        if (accessToken == null || refreshToken == null || parentId == null) {
          throw Exception(
              "Invalid response from server - missing token, refresh token or parentId");
        }

        api.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        await _stateController.login(
          tokenValue: accessToken,
          parentId: parentId,
          isNewUser: isNewUser,
          mobileNumber: widget.mobileNumber,
        );

        getSnackbar(
          title: "Success",
          message: "Login successful!",
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('parentMobileNumber', widget.mobileNumber);
        print("Mobile number saved: ${widget.mobileNumber}");

        bool hasProfile = isNewUser == true ? false : true;

        if (mounted) {
          if (hasProfile) {
            await _stateController.completeProfile();
            Get.offAll(
              () => const MainNavigation(),
            );
          } else {
            Get.offAll(
              () => ParentProfileSetupScreen(mobileNumber: widget.mobileNumber),
            );
          }
        }
      } else {
        throw Exception(
            "Server returned success: false - ${result['message'] ?? 'Unknown error'}");
      }
    } catch (e, stack) {
      print("OTP verification error: $e");
      print("Stack trace: $stack");

      if (!mounted) return;

      String errorMessage =
          "OTP verification failed. The code may be incorrect or expired. Please try again or request a new OTP.";

      getSnackbar(
        title: "OTP Verification Failed",
        message: errorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTeal,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          reverse: true,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryTeal.withOpacity(0.4),
                    const Color(0xFFE6F7F5),
                    const Color(0xFFF5FCFB),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      child: Container(
                        width: 240,
                        height: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCream,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 4,
                            top: 8,
                            bottom: 8,
                          ),
                          child: Image.asset(
                            'assets/images/Logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Enter the 6 digit code sent to\n+91-${widget.mobileNumber}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Pinput(
                      controller: _pinController,
                      length: 6,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(
                            color: AppColors.primaryTeal,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryTeal.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      submittedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 6) {
                          return 'Enter complete 6-digit OTP';
                        }
                        return null;
                      },
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      cursor: Container(
                        width: 2,
                        height: 40,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyOtp,
                        child: _isVerifying
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Verify & Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
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
