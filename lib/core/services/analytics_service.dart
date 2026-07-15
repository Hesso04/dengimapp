import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // --- AUTH EVENTS ---

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // --- MONETIZATION EVENTS ---

  Future<void> logViewPremiumPage(String source) async {
    await _analytics.logEvent(
      name: 'view_premium_page',
      parameters: {'from_source': source},
    );
  }

  Future<void> logPurchaseInitiated(String tier, String duration) async {
    await _analytics.logEvent(
      name: 'premium_purchase_initiated',
      parameters: {
        'tier': tier,
        'duration': duration,
      },
    );
  }

  Future<void> logPurchaseSuccess(String tier, double price, String currency) async {
    await _analytics.logPurchase(
      value: price,
      currency: currency,
      items: [
        AnalyticsEventItem(
          itemId: 'dengim_$tier',
          itemName: 'Dengim ${tier.toUpperCase()}',
          itemCategory: 'subscription',
          price: price,
        ),
      ],
    );
  }

  // --- ENGAGEMENT EVENTS ---

  Future<void> logSwipe(String direction, String targetUserId) async {
    await _analytics.logEvent(
      name: 'user_swipe',
      parameters: {
        'direction': direction,
        'target_id': targetUserId,
      },
    );
  }

  Future<void> logMatchCreated(String matchId) async {
    await _analytics.logEvent(
      name: 'match_created',
      parameters: {'match_id': matchId},
    );
  }

  Future<void> logMessageSent(String type) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {'message_type': type},
    );
  }

  // --- USER PROPERTIES ---

  Future<void> setUserProperties(String tier, String gender) async {
    await _analytics.setUserProperty(name: 'subscription_tier', value: tier);
    await _analytics.setUserProperty(name: 'user_gender', value: gender);
  }

  // --- APP PERFORMANCE ---

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logEvent({required String name, Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name, 
      parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
    );
  }
}
