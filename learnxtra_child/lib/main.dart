import 'package:LearnXtraChild/src/routes/app_routes.dart';
import 'package:LearnXtraChild/src/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/controller/app_controller.dart';
// import 'package:LearnXtraChild/src/services/kiosk_mode.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ApiService());
  Get.put(AppStateController());
  await Get.find<AppStateController>().loadState();

  // await KioskService.enableKiosk();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LX Child',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryTeal,
        scaffoldBackgroundColor: AppColors.backgroundCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.shade500.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 24,
            ),
            elevation: 8,
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      getPages: AppRoutes.pages,
      initialRoute: AppRoutes.splash,
    );
  }
}
