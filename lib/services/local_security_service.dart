import 'package:local_auth/local_auth.dart';

class LocalSecurityService {
  const LocalSecurityService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authorizeSensitiveAction(String reason) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return true;

      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      if (!canCheckBiometrics && biometrics.isEmpty) {
        final deviceAuthAvailable = await _auth.authenticate(
          localizedReason: reason,
          biometricOnly: false,
          sensitiveTransaction: true,
          persistAcrossBackgrounding: true,
        );
        return deviceAuthAvailable;
      }

      return _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      if (error.code == LocalAuthExceptionCode.noBiometricHardware ||
          error.code == LocalAuthExceptionCode.noBiometricsEnrolled ||
          error.code == LocalAuthExceptionCode.noCredentialsSet) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
