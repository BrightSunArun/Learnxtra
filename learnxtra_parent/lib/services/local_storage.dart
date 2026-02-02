import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveParentProfile({
    required String fullName,
    String? email,
    required String address,
    required String pinCode,
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('parent_full_name', fullName);
    await prefs.setString('parent_address', address);
    await prefs.setString('parent_pin_code', pinCode);

    if (email != null) {
      await prefs.setString('parent_email', email);
    }

    if (imageUrl != null) {
      await prefs.setString('parent_image_url', imageUrl);
    }
  }

  static Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber');
  }

  static Future<Map<String, dynamic>> getParentProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'fullName': prefs.getString('parent_full_name'),
      'email': prefs.getString('parent_email'),
      'address': prefs.getString('parent_address'),
      'pinCode': prefs.getString('parent_pin_code'),
      'imageUrl': prefs.getString('parent_image_url'),
    };
  }
}
