import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/log_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKeyBiometricEnabled = 'biometric_lock_enabled';

  /// Cihaz biyometrik kimlik doğrulamayı (Yüz / Parmak İzi) destekliyor mu?
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      LogService.e("isBiometricAvailable error", e);
      return false;
    }
  }

  /// Kullanıcı ayarlardan biyometrik kilidi aktif etmiş mi?
  Future<bool> isBiometricLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyBiometricEnabled) ?? false;
  }

  /// Biyometrik kilit tercihini kaydet
  Future<void> setBiometricLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyBiometricEnabled, enabled);
    LogService.i("Biometric lock enabled status updated: $enabled");
  }

  /// Biyometrik kimlik doğrulama iste (Face ID / Parmak İzi)
  Future<bool> authenticate() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return true; // Cihaz desteklemiyorsa kilit açılır

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Dengim uygulamasına erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      LogService.e("Biometric authentication error", e);
      return false;
    } catch (e) {
      LogService.e("Biometric authentication error general", e);
      return false;
    }
  }
}
