// Mobile implementation for PurchaseService
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // YENİ
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/utils/log_service.dart';

class PurchaseService {
  static const String _googleApiKey = "goog_SİZİN_REVENUECAT_ANAHTARINIZ";
  static const String _appleApiKey = "appl_SİZİN_REVENUECAT_ANAHTARINIZ";
  static const String entitlementId = "dengim_premium";

  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  Future<void> init() async {
    if (kIsWeb) return; // Web support for RevenueCat is limited/different

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      if (_googleApiKey.contains("SİZİN")) {
        LogService.w("UYARI: RevenueCat Android API Key ayarlanmamış!");
        return;
      }
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      if (_appleApiKey.contains("SİZİN")) {
        LogService.w("UYARI: RevenueCat iOS API Key ayarlanmamış!");
        return;
      }
      configuration = PurchasesConfiguration(_appleApiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
  }

  Future<void> logIn(String userId) async {
    if (kIsWeb) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      LogService.w("PurchaseService Info: $e");
    }
  }

  Future<void> logOut() async {
    if (kIsWeb) return;
    await Purchases.logOut();
  }

  Future<Offerings?> getOfferings() async {
    if (kIsWeb) return null;
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings;
      } else {
        LogService.w("PurchaseService: Current offering is null");
      }
    } on PlatformException catch (e) {
      LogService.e("PurchaseService Error (getOfferings): $e");
    }
    return null;
  }

  Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        LogService.e("PurchaseService Error (purchase): $e");
      }
      return false;
    }
  }

  Future<bool> checkPremiumStatus() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      LogService.e("PurchaseService Error (checkStatus): $e");
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      LogService.e("PurchaseService Error (restore): $e");
      return false;
    }
  }
}
