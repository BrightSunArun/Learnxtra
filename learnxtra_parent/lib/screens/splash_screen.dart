// ignore_for_file: avoid_print

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import 'auth/sign_in_screen.dart';
import 'main_navigation.dart';
import 'profile_setup/parent_profile_setup_screen.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AppStateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AppStateController>();
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    await _controller.initialize();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (!_controller.isAuthenticated.value) {
      Get.offAll(() => const SignInScreen());
    } else {
      final profile = await LocalStorage.getParentProfile();

      final hasProfile =
          profile['fullName'] != null && profile['fullName']!.isNotEmpty;
      print("hasProfile: $hasProfile");
      print("profile: $profile");

      final prefs = await SharedPreferences.getInstance();
      final mobileNumber = prefs.getString('mobileNumber');

      if (!hasProfile) {
        Get.offAll(
          () => ParentProfileSetupScreen(mobileNumber: mobileNumber!),
        );
      } else {
        await _controller.completeProfile();
        Get.offAll(() => const MainNavigation());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryTeal.withOpacity(0.7),
              AppColors.gray900,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                child: Container(
                  width: 240,
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCream,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 16,
                      )
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
              const SizedBox(height: 20),
              FadeInUp(
                child: Text(
                  "LearnXtra",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: const Text(
                  "Unlock Smarter, Learn Better!",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
