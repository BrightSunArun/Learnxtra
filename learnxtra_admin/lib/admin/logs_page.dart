import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SOS & Abuse Reports",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side:
                        BorderSide(color: AppColors.gray200.withOpacity(0.5))),
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: const Icon(FontAwesomeIcons.circleExclamation,
                      color: AppColors.coralRed),
                  title: const Text("SOS Request - ChildID: 4492"),
                  subtitle: const Text(
                      "Approved by Emergency Contact • Response Time: 45s"),
                  trailing: const Text("12:45 PM",
                      style: TextStyle(color: AppColors.mutedTeal)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
