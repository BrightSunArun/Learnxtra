import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:flutter/material.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Policy Configurations",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                  child: _policyBox("Screen-Time Settings", [
                _inputField("Default Daily Unlocks", "5"),
                _inputField("Unlock Duration (mins)", "30"),
              ])),
              const SizedBox(width: 20),
              Expanded(
                  child: _policyBox("Learning Gate Rules", [
                _inputField("Quiz Questions Count", "10"),
                _inputField("Min. Pass Score", "7"),
              ])),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: const Text("UPDATE GLOBAL POLICIES",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _policyBox(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                  fontSize: 18)),
          const SizedBox(height: 20),
          ...items
        ],
      ),
    );
  }

  Widget _inputField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedTeal),
          hintText: hint,
          filled: true,
          fillColor: AppColors.gray100,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
