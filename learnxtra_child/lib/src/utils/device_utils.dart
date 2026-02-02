import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceIdentifier() async {
  final deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {iosInfo.identifierForVendor}.toString();
    } else {
      return '';
    }
  } catch (e) {
    return 'fallback-${DateTime.now().millisecondsSinceEpoch}';
  }
}
