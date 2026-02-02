import 'package:LearnXtraParent/screens/safety/sos_center_screen.dart';
import 'package:LearnXtraParent/screens/settings/settings.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dashboard/parent_dashboard.dart';
import 'analytics/analytics_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final List<Widget> _screens = [
    const ParentDashboard(),
    const ProgressScreen(),
    const SOSCenterScreen(
      calledFrom: "main",
    ),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home,
              color: AppColors.primaryTeal,
            ),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(
              Icons.bar_chart,
              color: AppColors.primaryTeal,
            ),
            label: "Progress",
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency_outlined),
            selectedIcon: Icon(
              Icons.emergency,
              color: AppColors.primaryTeal,
            ),
            label: "SOS",
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.call_outlined),
          //   selectedIcon: Icon(
          //     Icons.call_outlined,
          //     color: AppColors.primaryTeal,
          //   ),
          //   label: "Emergency",
          // ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(
              Icons.settings,
              color: AppColors.primaryTeal,
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
