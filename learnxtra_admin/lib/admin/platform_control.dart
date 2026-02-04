// ignore_for_file: deprecated_member_use

import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:flutter/material.dart';

class PlatformControlsPage extends StatelessWidget {
  const PlatformControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          _controlTile("Emergency Unlock Mode",
              "Enable system-wide unlock for all users", true),
          _controlTile("Maintenance Mode",
              "Disable app access for scheduled updates", false),
          _controlTile("Quiz Integration",
              "Global toggle for the Learning Gate feature", true),
        ],
      ),
    );
  }

  Widget _controlTile(String title, String sub, bool val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textDark)),
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                ),
              ),
            ],
          ),
          const Spacer(),
          Switch(
            value: val,
            activeColor: AppColors.cyanAccent,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }
}
