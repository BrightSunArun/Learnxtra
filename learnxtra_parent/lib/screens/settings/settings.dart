// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:LearnXtraParent/controller/app_state.dart';
import 'package:LearnXtraParent/screens/analytics/control_screen.dart';
import 'package:LearnXtraParent/screens/auth/password_setup.dart';
import 'package:LearnXtraParent/screens/profile_setup/parent_profile_setup_screen.dart';
import 'package:LearnXtraParent/screens/safety/emergency_contacts_screen.dart';
import 'package:LearnXtraParent/screens/safety/sos_center_screen.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 0,
        leading: SizedBox.shrink(),
        title: Text(
          "Settings",
          style: TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader("Account"),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: "Profile",
              subtitle: "Parent Name • Parent Account",
              onTap: () {
                Get.to(() => ParentProfileSetupScreen(
                      calledFrom: "settings",
                    ));
              },
            ),

            _SettingsTile(
              icon: Icons.password_rounded,
              title: "Parent Mode Password",
              subtitle: "Set or change password for parent mode",
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal),
              onTap: () {
                Get.to(() => const ParentPasswordSetupScreen());
              },
            ),

            const SizedBox(height: 24),

            _buildSectionHeader("Child & Safety"),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.timer_outlined,
              title: "Child Screen Time Control",
              subtitle: "Daily limits, schedules, app restrictions",
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScreenTimeControlScreen(),
                  ),
                );
              },
            ),

            _SettingsTile(
              icon: Icons.contact_emergency,
              title: "Emergency Contacts",
              subtitle: "Manage trusted contacts for alerts",
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal),
              onTap: () {
                Get.to(
                  () => const EmergencyContactsScreen(),
                );
              },
            ),

            _SettingsTile(
              icon: Icons.sos_rounded,
              title: "SOS Requests",
              subtitle: "View & manage emergency help requests",
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal),
              onTap: () {
                Get.to(
                  () => const SOSCenterScreen(
                    calledFrom: "settings",
                  ),
                );
              },
            ),

            // _SettingsTile(
            //   icon: Icons.location_on_outlined,
            //   title: "Live Location Sharing",
            //   subtitle: "Real-time tracking settings",
            //   trailing: const Icon(Icons.chevron_right_rounded,
            //       color: AppColors.primaryTeal),
            //   onTap: () {
            //     getSnackbar(
            //       title: "Coming Soon",
            //       message: "Location sharing coming soon",
            //     );
            //   },
            // ),

            const SizedBox(height: 24),

            // ── App Preferences ──────────────────────────────────────────────────
            _buildSectionHeader("App Preferences"),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: "Notifications",
              subtitle: "Alerts, reminders, push settings",
              trailing: Switch(
                value: true,
                activeColor: AppColors.primaryTeal,
                onChanged: (v) {
                  getSnackbar(
                    title: "Toggle",
                    message: "Notifications ${v ? 'enabled' : 'disabled'}",
                  );
                },
              ),
            ),

            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: "Appearance",
              subtitle: "Light / Dark mode",
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal),
              onTap: () {
                getSnackbar(
                  title: "Coming Soon",
                  message: "Theme settings coming soon",
                );
              },
            ),

            _SettingsTile(
              icon: Icons.language,
              title: "Language",
              subtitle: "English (default)",
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal),
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // ── Support & Legal ──────────────────────────────────────────────────
            _buildSectionHeader("Help & Support"),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: "Help Center",
              subtitle: "Get help with any issues",
              onTap: () {
                getSnackbar(
                  title: "Coming Soon",
                  message: "Help center under construction",
                );
              },
            ),

            _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: "About LearnXtra",
                subtitle: "Version 1.0.0 • © 2026",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: AppColors.primaryTeal,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            const Text("LearnXtra Parent"),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Helping parents keep children safe and focused.",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Version 1.0.0 • © 2026",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Close"),
                          ),
                        ],
                      );
                    },
                  );
                }),

            _SettingsTile(
              icon: Icons.logout_rounded,
              title: "Log Out",
              subtitle: "Log in using different credentials?",
              textColor: Colors.red[700],
              iconColor: Colors.red[700],
              onTap: () => _showLogoutDialog(),
            ),

            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: "Delete Account",
              subtitle: "Once deleted, your account cannot be recovered",
              textColor: Colors.red[700],
              iconColor: Colors.red[700],
              onTap: () => _showDeleteAccountDialog(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.gray800,
        elevation: 12,
        title: const Text(
          "Delete Account",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Are you sure you want to delete your account?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Get.back();
                    // Get.toNamed(Routes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Delete",
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.gray800,
        elevation: 12,
        title: const Text(
          "Logout",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Are you sure you want to log out?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final controller = Get.find<AppStateController>();
                    await controller.logout();
                    Get.offAllNamed('/'); // or Get.offAll(() => SplashScreen())
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal.withOpacity(0.9),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.primaryTeal,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryTeal,
                  size: 20,
                )
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
    );
  }
}
