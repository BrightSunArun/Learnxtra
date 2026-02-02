import 'package:LearnXtraChild/src/screens/auth/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/screens/emergency_call_screen.dart';
import 'package:LearnXtraChild/src/screens/sos_screen.dart';
import 'package:LearnXtraChild/src/screens/parent_mode_screen.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';

class PersistentNavBar extends StatefulWidget {
  const PersistentNavBar({super.key});

  @override
  State<PersistentNavBar> createState() => _PersistentNavBarState();
}

class _PersistentNavBarState extends State<PersistentNavBar> {
  final controller = Get.put(NavController());

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }

  Future<bool> _onWillPop() async {
    final currentKey = _navigatorKeys[controller.currentIndex.value];
    if (currentKey.currentState != null && currentKey.currentState!.canPop()) {
      currentKey.currentState!.pop();
      return false;
    }

    if (controller.currentIndex.value != 0) {
      controller.changeTab(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Obx(
          () => IndexedStack(
            index: controller.currentIndex.value,
            children: [
              _buildTabNavigator(0, const HomeScreen()),
              _buildTabNavigator(1, const EmergencyCallScreen()),
              _buildTabNavigator(2, const SOSScreen()),
              _buildTabNavigator(3, const ParentModeScreen()),
            ],
          ),
        ),
        bottomNavigationBar: Obx(
          () => SizedBox(
            height: 100,
            child: BottomNavigationBar(
              landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
              elevation: 10,
              selectedLabelStyle: TextStyle(fontSize: 14),
              unselectedLabelStyle: TextStyle(fontSize: 10),
              selectedFontSize: 14,
              unselectedFontSize: 10,
              currentIndex: controller.currentIndex.value,
              onTap: controller.changeTab,
              backgroundColor: AppColors.primaryTeal,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.phone_in_talk),
                  label: 'Emergency',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sos),
                  label: 'SOS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Parent',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
