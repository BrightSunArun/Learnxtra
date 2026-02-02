// ignore_for_file: deprecated_member_use
import 'package:LearnXtraAdmin/admin/accounts_page.dart';
import 'package:LearnXtraAdmin/admin/admin_login_page.dart';
import 'package:LearnXtraAdmin/admin/logo.dart';
import 'package:LearnXtraAdmin/admin/logs_page.dart';
import 'package:LearnXtraAdmin/admin/overview_page.dart';
import 'package:LearnXtraAdmin/admin/platform_control.dart';
import 'package:LearnXtraAdmin/admin/policy_page.dart';
import 'package:LearnXtraAdmin/admin/questions_page.dart';
import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LearnXtra Admin',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: AppColors.gray900,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int selectedIndex = 0;

  final List<Widget> _pages = [
    const OverviewPage(),
    const PolicyPage(),
    const QuestionBankPage(),
    const AccountsPage(),
    const LogsPage(),
    const PlatformControlsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.primaryTeal.withOpacity(0.6),
              Colors.white,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: AppColors.gray900,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      gradient: RadialGradient(
                        radius: 1.4,
                        colors: [
                          Colors.white,
                          AppColors.gray800,
                        ],
                      ),
                    ),
                    height: 220,
                    child: Center(
                      child: LearnXtraLogo(size: 180),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _navItem(0, "Dashboard", FontAwesomeIcons.house),
                  _navItem(1, "Policy Settings", FontAwesomeIcons.shield),
                  _navItem(2, "Question Bank", FontAwesomeIcons.bookOpen),
                  _navItem(3, "User Accounts", FontAwesomeIcons.userGroup),
                  _navItem(4, "Audit & Reports", FontAwesomeIcons.fileContract),
                  _navItem(5, "Platform Controls", FontAwesomeIcons.gears),
                  const Spacer(),
                  const Divider(
                      color: Colors.white60, indent: 20, endIndent: 20),
                  _navItem(99, "Logout", FontAwesomeIcons.rightFromBracket),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // MAIN CONTENT AREA
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _pages[selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(height: 4, color: AppColors.gray800),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                "Welcome back, Admin",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              const Icon(Icons.notifications_none, color: AppColors.mutedTeal),
              const SizedBox(width: 20),
              const CircleAvatar(
                backgroundColor: AppColors.cyanAccent,
                child: Icon(Icons.person, color: Colors.white),
              )
            ],
          ),
        ),
        Container(height: 4, color: AppColors.gray800),
      ],
    );
  }

  Widget _navItem(int index, String title, IconData icon) {
    bool isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        onTap: () {
          if (index == 99) {
            _showLogoutDialog();
          } else {
            setState(() => selectedIndex = index);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor:
            isSelected ? AppColors.white.withOpacity(0.1) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.yellowPage : AppColors.mutedTeal,
          size: 18,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? AppColors.white
                : AppColors.white.withOpacity(0.85),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shadowColor: Colors.black54,
          backgroundColor: AppColors.gray900,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  fontSize: 32,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: const Text(
              "Are you sure you want to logout?",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 20,
                      backgroundColor: AppColors.gray200,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 20,
                      backgroundColor: AppColors.gray200,
                      foregroundColor: Colors.redAccent.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.redAccent.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
