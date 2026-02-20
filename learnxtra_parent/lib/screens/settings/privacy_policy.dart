// lib/screens/privacy_policy.dart
import 'package:LearnXtraParent/constants/app_colors.dart';
import 'package:flutter/material.dart';
// import 'package:learnxtra/constants/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '🔐 PRIVACY POLICY',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'LearnXtra Parent App & Child App',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('1. Introduction'),
            const Text(
              'LearnXtra Pvt. Ltd. respects your privacy and is committed to protecting personal data. This Privacy Policy explains how we collect, use, store, and protect data.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('2. Data We Collect'),
            const Text(
              'A. Parent App Data\n'
              '• Name, email address, phone number\n'
              '• Parent account credentials\n'
              '• App usage and configuration settings\n'
              '• Subscription details (via app stores)\n\n'
              'B. Child App Data\n'
              '• Child profile details (name, age group)\n'
              '• Screen usage statistics\n'
              '• Question performance data\n'
              '• Unlock attempts and duration\n'
              '• SOS usage records\n\n'
              'C. Device & Technical Data\n'
              '• Device ID (hashed)\n'
              '• App version\n'
              '• Operating system\n'
              '• Crash and diagnostic logs',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('3. Data We DO NOT Collect'),
            const Text(
              '• No real-time location tracking\n'
              '• No microphone or camera access (unless explicitly enabled)\n'
              '• No contact list access beyond emergency numbers added by parent\n'
              '• No advertising profiling of children',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            // Continue with sections 4–12 similarly...

            const SizedBox(height: 32),
            const Text(
              'Contact Information\n'
              'LearnXtra Pvt. Ltd.\n'
              '📧 Email: support@learnxtra.com\n'
              '📍 Bengaluru, Karnataka, India',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }
}
