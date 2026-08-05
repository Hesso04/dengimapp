import 'package:shared_preferences/shared_preferences.dart';
import '../utils/log_service.dart';

/// 4-Haneli PIN Kodu Kilit Servisi
class PinLockService {
  static final PinLockService _instance = PinLockService._internal();
  factory PinLockService() => _instance;
  PinLockService._internal();

  static const String _keyPinEnabled = 'pin_lock_enabled';
  static const String _keyPinCode = 'pin_lock_code';

  /// PIN kilidi aktif mi?
  Future<bool> isPinLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyPinEnabled) ?? false;
      final code = prefs.getString(_keyPinCode);
      return enabled && code != null && code.length == 4;
    } catch (e) {
      LogService.e("PinLock isPinLockEnabled error", e);
      return false;
    }
  }

  /// Kayıtlı PIN kodunu getir
  Future<String?> getSavedPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyPinCode);
    } catch (e) {
      LogService.e("PinLock getSavedPin error", e);
      return null;
    }
  }

  /// Yeni PIN kodu kaydet ve kilidi aktifleştir
  Future<bool> setPin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPinCode, pin);
      await prefs.setBool(_keyPinEnabled, true);
      LogService.i("PIN lock set successfully.");
      return true;
    } catch (e) {
      LogService.e("PinLock setPin error", e);
      return false;
    }
  }

  /// Girilen PIN doğrulamasını yap
  Future<bool> verifyPin(String inputPin) async {
    final savedPin = await getSavedPin();
    return savedPin != null && savedPin == inputPin;
  }

  /// PIN kilidini tamamen kaldır
  Future<void> removePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPinCode);
      await prefs.setBool(_keyPinEnabled, false);
      LogService.i("PIN lock removed.");
    } catch (e) {
      LogService.e("PinLock removePin error", e);
    }
  }
}
