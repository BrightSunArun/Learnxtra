import 'package:kiosk_mode/kiosk_mode.dart';

class KioskService {
  static Future<void> enableKiosk() async {
    await startKioskMode();
  }

  static Future<void> disableKiosk() async {
    await stopKioskMode();
  }
}
