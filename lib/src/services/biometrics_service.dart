import 'package:local_auth/local_auth.dart';

class BiometricsService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final available = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!available || !isDeviceSupported) {
        return true; // No biometrics, proceed without auth
      }

      return await _auth.authenticate(
        localizedReason: 'Confirm payment',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
