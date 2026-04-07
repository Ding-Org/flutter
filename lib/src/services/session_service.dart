import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/constants.dart';

class SessionService {
  static Future<String?> getSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(signatureKey);
  }

  static Future<void> saveSignature(String signature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(signatureKey, signature);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(signatureKey);
  }
}
