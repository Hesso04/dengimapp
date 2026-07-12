import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/log_service.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final configDoc = await _firestore.collection('system').doc('config').get();
      if (configDoc.exists) _updateConfig(configDoc.data()!);

      // 2. Initial resources
      final resDoc = await _firestore.collection('system').doc('resources').get();
      if (resDoc.exists) _updateResources(resDoc.data()!);

      // Listen for real-time changes
      _firestore.collection('system').doc('config').snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) _updateConfig(snapshot.data()!);
      });
      
      _firestore.collection('system').doc('resources').snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) _updateResources(snapshot.data()!);
      });
      
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
}
