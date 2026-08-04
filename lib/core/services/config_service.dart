import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/log_service.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _configSubscription;
  StreamSubscription? _resourcesSubscription;

  bool isVipEnabled = false;
  bool isAdsEnabled = true;
  bool isCreditsEnabled = false;

  // Resources
  String privacyPolicyUrl = "https://dengim.app/privacy";
  String termsOfServiceUrl = "https://dengim.app/terms";
  String supportEmail = "support@dengim.app";
  String appVersion = "1.0.0";
  bool maintenanceMode = false;
  String maintenanceMessage = "Bakımdayız.";

  Future<void> init() async {
    try {
      // 1. Initial config
      try {
        final configDoc = await _firestore.collection('system').doc('config').get();
        if (configDoc.exists && configDoc.data() != null) _updateConfig(configDoc.data()!);
      } catch (e) {
        LogService.w("Config fetch warning (unauthenticated or offline): $e");
      }

      // 2. Initial resources
      try {
        final resDoc = await _firestore.collection('system').doc('resources').get();
        if (resDoc.exists && resDoc.data() != null) _updateResources(resDoc.data()!);
      } catch (e) {
        LogService.w("Resources fetch warning (unauthenticated or offline): $e");
      }

      // Listen for real-time changes
      _configSubscription = _firestore.collection('system').doc('config').snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) _updateConfig(snapshot.data()!);
      }, onError: (e) => LogService.w("Config stream warning: $e"));
      
      _resourcesSubscription = _firestore.collection('system').doc('resources').snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) _updateResources(snapshot.data()!);
      }, onError: (e) => LogService.w("Resources stream warning: $e"));
      
      LogService.i("Config & Resource Services initialized.");
    } catch (e) {
      LogService.e("Error initializing Config/Resource Service", e);
    }
  }

  void _updateConfig(Map<String, dynamic> data) {
    isVipEnabled = data['isVipEnabled'] ?? false;
    isAdsEnabled = data['isAdsEnabled'] ?? true;
    isCreditsEnabled = data['isCreditsEnabled'] ?? false;
  }

  void _updateResources(Map<String, dynamic> data) {
    privacyPolicyUrl = data['privacyPolicyUrl'] ?? privacyPolicyUrl;
    termsOfServiceUrl = data['termsOfServiceUrl'] ?? termsOfServiceUrl;
    supportEmail = data['supportEmail'] ?? supportEmail;
    appVersion = data['appVersion'] ?? appVersion;
    maintenanceMode = data['maintenanceMode'] ?? false;
    maintenanceMessage = data['maintenanceMessage'] ?? maintenanceMessage;
    LogService.i("Resources updated from remote.");
  }

  void dispose() {
    _configSubscription?.cancel();
    _resourcesSubscription?.cancel();
  }
}
