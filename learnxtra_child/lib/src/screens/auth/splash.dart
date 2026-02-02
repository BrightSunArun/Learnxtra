import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
import 'package:LearnXtraChild/src/screens/auth/bottom_navigation_bar.dart';
import 'package:LearnXtraChild/src/screens/auth/link_device.dart'; // ensure path matches your file
// If your link device file is named link_device_screen.dart change the import accordingly.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final app = Get.find<AppStateController>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await app.loadState();
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!app.isLinked.value) {
      // Not linked -> take user to LinkDevice screen
      Get.off(() => const LinkDeviceScreen());
    } else {
      // Already linked -> go to bottom navigation
      Get.off(() => const PersistentNavBar());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage("assets/images/Logo.png"),
          height: 360,
          width: 360,
        ),
      ),
    );
  }
}
