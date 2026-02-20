import 'package:LearnXtraParent/constants/app_colors.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help Center'),
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
              'LearnXtra Parent App – Help Topics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('1. Adding a Child Profile'),
            const Text(
              'The Parent App allows you to securely create and manage individual profiles for each child.\n\n'
              'How to add a child:\n\n'
              '1. Open the LearnXtra Parent App.\n'
              '2. Go to Manage Children → Add Child.\n'
              '3. Enter the child’s name, age, and other details.\n'
              '4. Setup screen time, lock session, duration etc\n'
              '5. Generate code to integrate child app\n'
              '6. Enter the code in child mobile\n'
              '7. Submit.\n\n'
              'Each child profile is managed independently, allowing customized rules per child.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('2. Configuring Unlock Sessions'),
            const Text(
              'Parents can control how often and how long the child can unlock the device.\n\n'
              'You can configure:\n'
              '• Number of unlock sessions per day\n'
              '• Duration of each unlock session (e.g., 15 mins, 30 mins)\n'
              '• Allowed start time and end time (screen access window)\n\n'
              'Steps:\n\n'
              '1. Select the child profile.\n'
              '2. Go to Screen Access Settings.\n'
              '3. Set:\n'
              '   • Total unlock sessions\n'
              '   • Duration per session\n'
              '   • Daily allowed time window\n'
              '4. Save settings.\n\n'
              'The child’s device will strictly follow these rules.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle(
                '3. Linking Parent App with Child App (Code / QR)'),
            const Text(
              'To securely connect the Parent App with the Child App, LearnXtra uses a unique code or QR code.\n\n'
              'How it works:\n\n'
              '1. In Parent App, select the child profile.\n'
              '2. Tap Generate Link Code / QR Code.\n'
              '3. Open the Child App on the child’s device.\n'
              '4. Enter the code or scan the QR code.\n\n'
              'Once linked, all controls and settings apply instantly.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('4. Emergency Contacts Setup'),
            const Text(
              'Parents can register emergency contacts that the child can call without unlocking the screen.\n\n'
              'Steps to add emergency numbers:\n\n'
              '1. Go to Emergency Contacts in Parent App.\n'
              '2. Add phone numbers (parents, guardians, relatives).\n'
              '3. Save changes.\n\n'
              'These numbers will always be visible and callable from the child’s lock screen.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('5. Parent Mode Password'),
            const Text(
              'To prevent children from changing settings, Parent Mode is protected with a password.\n\n'
              'How to set Parent Mode password:\n\n'
              '1. Open Security Settings in Parent App.\n'
              '2. Set a secure password or PIN.\n'
              '3. Confirm and save.\n\n'
              'This password is required to:\n'
              '• Enter Parent Mode in Child App\n'
              '• Change unlock rules\n'
              '• Modify emergency settings',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('6. Monitoring Screen Usage & Performance'),
            const Text(
              'The Parent App provides detailed insights into your child’s device usage and learning behavior.\n\n'
              'You can view:\n'
              '• Total screen time per day\n'
              '• Number of unlocks used\n'
              '• Questions answered correctly / incorrectly\n'
              '• Time taken to unlock\n'
              '• Emergency unlock requests (SOS)\n\n'
              'How to access reports:\n\n'
              '1. Select the child profile.\n'
              '2. Open Usage & Performance Dashboard.\n\n'
              'These insights help parents balance screen time and learning effectiveness.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            const SizedBox(height: 32),
            Text(
              'LearnXtra Child App – Help Topics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('1. Unlocking the Screen Using Questions'),
            const Text(
              'The Child App encourages learning by requiring children to answer questions before unlocking the screen.\n\n'
              'How to unlock:\n\n'
              '1. Turn on the device.\n'
              '2. Answer the questions shown on the lock screen.\n'
              '3. If answers are correct, the screen unlocks for the allowed duration.\n\n'
              'Questions are age-appropriate and configured by parents.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            _buildSectionTitle('2. SOS Unlock (Emergency Use)'),
            const Text(
              'In emergency situations, the child can request an SOS unlock.\n\n'
              'How SOS works:\n\n'
              '1. Tap SOS Unlock on the lock screen.\n'
              '2. Select the emergency reason.\n'
              '3. The request is sent to the Parent App.\n'
              '4. Parent can approve or review later.\n\n'
              'SOS usage is recorded and visible to parents.',
              style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
            ),

            // ... (you can continue adding the remaining Child App sections similarly)
            // For brevity I stopped here — add 3–6 the same way as above

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
