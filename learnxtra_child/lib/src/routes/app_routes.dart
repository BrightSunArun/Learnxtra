import 'package:LearnXtraChild/src/screens/auth/home_screen.dart';
import 'package:get/get.dart';
import 'package:LearnXtraChild/src/screens/auth/splash.dart';
import 'package:LearnXtraChild/src/screens/auth/bottom_navigation_bar.dart';
import 'package:LearnXtraChild/src/screens/auth/link_device.dart';
import 'package:LearnXtraChild/src/screens/lock_device.dart';
import 'package:LearnXtraChild/src/screens/unlock_device.dart';
import 'package:LearnXtraChild/src/screens/emergency_call_screen.dart';
import 'package:LearnXtraChild/src/screens/sos_screen.dart';
import 'package:LearnXtraChild/src/screens/parent_mode_screen.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_instructions.dart';
import 'package:LearnXtraChild/src/screens/quiz/subject_selection_screen.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_screen.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_passed.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_failed.dart';
import 'package:LearnXtraChild/src/screens/quiz/quiz_results_screen.dart';

class AppRoutes {
  // 🟦 AUTH + INIT
  static const String splash = '/splash';
  static const String bottomNavigation = '/bottomNavigation';
  static const String linkDevice = '/link-device';

  // 🟩 HOME FLOW
  static const String home = '/home';
  static const String locked = '/locked';
  static const String unlocked = '/unlocked';

  // 🟥 QUIZ FLOW
  static const String quizInstruction = '/quiz/instruction';
  static const String quizSubject = '/quiz/subject';
  static const String quizStart = '/quiz/start';
  static const String quizPassed = '/quiz/passed';
  static const String quizFailed = '/quiz/failed';
  static const String quizResults = '/quiz/results';

  // 🟧 OTHER SCREENS
  static const String emergency = '/emergency';
  static const String sos = '/sos';
  static const String parent = '/parent';
  static const String profile = '/profile';

  // 🟪 ROUTES LIST
  static final List<GetPage> pages = [
    // AUTH & SPLASH
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: bottomNavigation,
      page: () => const PersistentNavBar(),
      transition: Transition.fade,
    ),
    GetPage(
      name: linkDevice,
      page: () => const LinkDeviceScreen(),
      transition: Transition.rightToLeftWithFade,
    ),

    // HOME FLOW
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: locked,
      page: () => const LockedScreen(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: unlocked,
      page: () => const UnlockDevice(),
      transition: Transition.fadeIn,
    ),

    // QUIZ FLOW
    GetPage(
      name: quizInstruction,
      page: () => const DailyQuizInstructionScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: quizSubject,
      page: () => const SubjectSelectionScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: quizStart,
      page: () => QuizScreen(subject: Get.arguments),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: quizPassed,
      page: () => QuizPassedScreen(
        correct: Get.arguments["correct"],
        quizSummary: Get.arguments["summary"],
      ),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: quizFailed,
      page: () => QuizFailedScreen(
        correct: Get.arguments["correct"],
        quizSummary: Get.arguments["summary"],
      ),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: quizResults,
      page: () {
        final dynamic args = Get.arguments;
        List<Map<String, dynamic>> summary = [];
        String? calledFrom;

        if (args is Map) {
          // If callers passed a map like {'summary': [...], 'calledFrom': 'pass'}
          final dynamic rawSummary = args['summary'];
          if (rawSummary is List) {
            // Attempt to cast list elements to Map<String, dynamic>
            summary = List<Map<String, dynamic>>.from(
              rawSummary.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
          if (args.containsKey('calledFrom')) {
            calledFrom = args['calledFrom'] as String?;
          }
        } else if (args is List) {
          // If callers passed the list directly
          summary = List<Map<String, dynamic>>.from(
            args.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }

        return QuizResultsScreen(
          quizSummary: summary,
          calledFrom: calledFrom,
        );
      },
      transition: Transition.upToDown,
    ),

    // OTHER
    GetPage(
      name: emergency,
      page: () => const EmergencyCallScreen(),
      transition: Transition.leftToRightWithFade,
    ),
    GetPage(
      name: sos,
      page: () => const SOSScreen(),
      transition: Transition.leftToRightWithFade,
    ),
    GetPage(
      name: parent,
      page: () => const ParentModeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: profile,
      page: () => const UnlockDevice(),
      transition: Transition.leftToRightWithFade,
    ),
  ];
}
