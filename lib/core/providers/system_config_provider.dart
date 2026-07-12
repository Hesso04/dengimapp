import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin panelinden yönetilen sistem ayarlarını dinleyen provider
/// Firestore'daki system/config dokümanını gerçek zamanlı olarak dinler
class SystemConfigProvider extends ChangeNotifier {
  // Sistem Ayarları (config)
  bool _isVipEnabled = false;
  bool _isAdsEnabled = true;
  bool _isCreditsEnabled = false;
  bool _isMapEnabled = false;
  int _minimumAge = 18;
  int _maxDistance = 100;
  int _dailyLikeLimit = 25;
  
  // Uygulama Kaynakları (resources)
  String _privacyPolicyUrl = 'https://dengim.app/privacy';
  String _termsOfServiceUrl = 'https://dengim.app/terms';
  String _supportEmail = 'support@dengim.app';
  String _appVersion = '1.0.0';
  bool _isMaintenanceMode = false;
  String _maintenanceMessage = 'Şu anda bakım çalışması yapıyoruz.';
  
  // Algoritma Parametreleri
  int _locationWeight = 35;
  int _interestsWeight = 40;
  int _activityWeight = 25;
  
  StreamSubscription<DocumentSnapshot>? _configSubscription;
  StreamSubscription<DocumentSnapshot>? _resourcesSubscription;
  bool _isLoading = true;
  String? _error;

  // Getters
  bool get isVipEnabled => _isVipEnabled;
  bool get isAdsEnabled => _isAdsEnabled;
  bool get isCreditsEnabled => _isCreditsEnabled;
  bool get isMapEnabled => _isMapEnabled;
  int get minimumAge => _minimumAge;
  int get maxDistance => _maxDistance;
  int get dailyLikeLimit => _dailyLikeLimit;
  bool get isMaintenanceMode => _isMaintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;
  String get privacyPolicyUrl => _privacyPolicyUrl;
  String get termsOfServiceUrl => _termsOfServiceUrl;
  String get supportEmail => _supportEmail;
  String get appVersion => _appVersion;
  int get locationWeight => _locationWeight;
  int get interestsWeight => _interestsWeight;
  int get activityWeight => _activityWeight;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SystemConfigProvider() {
    _initListeners();
  }

  void _initListeners() {
    // Listen to system/config
    _configSubscription = FirebaseFirestore.instance
        .collection('system')
        .doc('config')
        .snapshots()
        .listen(_onConfigUpdate);

    // Listen to system/resources
    _resourcesSubscription = FirebaseFirestore.instance
        .collection('system')
        .doc('resources')
        .snapshots()
        .listen(_onResourcesUpdate);
  }

  void _onConfigUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    _isVipEnabled = data['isVipEnabled'] ?? false;
    _isAdsEnabled = data['isAdsEnabled'] ?? true;
    _isCreditsEnabled = data['isCreditsEnabled'] ?? false;
    _isMapEnabled = data['isMapEnabled'] ?? false;
    _minimumAge = data['minimumAge'] ?? 18;
    _maxDistance = data['maxDistance'] ?? 100;
    _dailyLikeLimit = data['dailyLikeLimit'] ?? 25;
    
    // Config'deki bakım modu değerlerini koru (geriye dönük uyum için)
    if (data.containsKey('isMaintenanceMode')) {
      _isMaintenanceMode = data['isMaintenanceMode'];
      _maintenanceMessage = data['maintenanceMessage'] ?? '';
    }

    _locationWeight = data['locationWeight'] ?? 35;
    _interestsWeight = data['interestsWeight'] ?? 40;
    _activityWeight = data['activityWeight'] ?? 25;

    _isLoading = false;
    notifyListeners();
  }

  void _onResourcesUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    _privacyPolicyUrl = data['privacyPolicyUrl'] ?? _privacyPolicyUrl;
    _termsOfServiceUrl = data['termsOfServiceUrl'] ?? _termsOfServiceUrl;
    _supportEmail = data['supportEmail'] ?? _supportEmail;
    _appVersion = data['appVersion'] ?? _appVersion;
    
    // Resources'daki bakım modu değerlerini tercih et (yeni sistem)
    _isMaintenanceMode = data['maintenanceMode'] ?? _isMaintenanceMode;
    _maintenanceMessage = data['maintenanceMessage'] ?? _maintenanceMessage;

    _isLoading = false;
    notifyListeners();
  }

  // ... diğer yardımcı metodlar
  
  @override
  void dispose() {
    _configSubscription?.cancel();
    _resourcesSubscription?.cancel();
    super.dispose();
  }
}
