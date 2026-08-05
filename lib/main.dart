import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_scaffold.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/auth/login_screen.dart';
import 'core/utils/error_handler.dart';
import 'features/create_profile/create_profile_screen.dart';
import 'core/widgets/responsive_center_wrapper.dart'; // Web Wrapper
import 'core/widgets/network_wrapper.dart'; // Network Wrapper
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/discovery_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/badge_provider.dart';
import 'core/providers/likes_provider.dart';
import 'core/providers/map_provider.dart';
import 'core/providers/system_config_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/credit_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/utils/log_service.dart';

import 'features/auth/services/profile_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/config_service.dart';
import 'core/services/feature_flag_service.dart';
import 'features/ads/services/ad_service.dart';
import 'package:geolocator/geolocator.dart';

import 'core/widgets/maintenance_screen.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LogService.i('Handling a background message: ${message.messageId}');
  
  final data = message.data;
  final chatId = data['chatId'];
  final messageId = data['messageId'];
  
  if (chatId != null && messageId != null) {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDelivered': true});
      LogService.i('Message $messageId marked as delivered in background.');
    } catch (e) {
      LogService.e('Failed to mark message as delivered in background: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fix for Google Fonts loading issues on some platforms
  GoogleFonts.config.allowRuntimeFetching = true;
  
  // Global error handling
  ErrorHandler.initialize();
  
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  try {
    LogService.i("Firebase initializing...");
    await Firebase.initializeApp(
      options: kIsWeb 
        ? const FirebaseOptions(
            apiKey: "AIzaSyCQRAqILl3fdNCwEvGAJeIzQ-XSfiyeVp8",
            authDomain: "dengim-kim.firebaseapp.com",
            projectId: "dengim-kim",
            storageBucket: "dengim-kim.firebasestorage.app",
            messagingSenderId: "12239103870",
            appId: "1:12239103870:web:b0dd97ac27cda36a21f52f",
            measurementId: "G-7TK4QPEWFN"
          )
        : null,
    );
    LogService.i("Firebase initialized successfully.");

    // ═══ Crashlytics init (release modda anlamlı) ═══
    if (!kDebugMode) {
      try {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        LogService.i("Crashlytics enabled.");
      } catch (e) {
        LogService.w("Crashlytics init warning: $e");
      }
    }

    // ConfigService, FeatureFlagService ve AdService'ı arka planda başlat
    // (Startup hızı için bloklama yok — fire-and-forget)
    unawaited(ConfigService().init());
    unawaited(FeatureFlagService().init());
    unawaited(AdService().init());

    // Bildirim servisini arka planda başlat (bloklama yok)
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      unawaited(NotificationService().initialize());
    } catch (e) {
      LogService.w("Notification init warning: $e");
    }
    
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    }
  } catch (e) {
    LogService.e("Firebase initialization error", e);
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => LikesProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => SystemConfigProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<UserProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider()..init(),
          update: (_, userProvider, subProvider) {
            if (subProvider != null) {
              subProvider.updateTierFromProfile(userProvider.currentUser?.subscriptionTier);
            }
            return subProvider ?? SubscriptionProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => CreditProvider()),
      ],
      child: const DengimApp(),
    ),
  );
}




class DengimApp extends StatefulWidget {
  const DengimApp({super.key});

  @override
  State<DengimApp> createState() => _DengimAppState();
}

class _DengimAppState extends State<DengimApp> with WidgetsBindingObserver {
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
    _updateLocationBackground();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
      _updateLocationBackground();
    } else {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    if (FirebaseAuth.instance.currentUser != null) {
      _profileService.updateOnlineStatus(isOnline);
    }
  }

  Future<void> _updateLocationBackground() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
          await _profileService.updateLocation(position.latitude, position.longitude);
        }
      }
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SystemConfigProvider, ThemeProvider>(
      builder: (context, config, themeProvider, child) {
        return MaterialApp(
          title: 'DENGİM',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          builder: (context, child) => ResponsiveCenterWrapper(
            child: NetworkWrapper(child: child!),
          ),
          home: config.isMaintenanceMode 
              ? const MaintenanceScreen() 
              : const SplashScreen(),
        );
      },
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _checkFirstTime();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    try {
      // Ekran ilk karesinin çizilmesi ve logo animasyonu için 500ms bekle
      await Future.delayed(const Duration(milliseconds: 500));

      final prefsFuture = SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await prefsFuture;
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (!mounted) return;

      if (isFirstTime) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (user == null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.loadCurrentUser();
          
          if (!mounted) return;

          // CreditProvider'i arka planda başlat (ekran yönlendirmesini beklemesin)
          final creditProvider = Provider.of<CreditProvider>(context, listen: false);
          unawaited(creditProvider.init().then((_) => creditProvider.claimDailyReward()));

          Widget nextScreen = userProvider.currentUser != null 
              ? MainScaffold(key: MainScaffold.scaffoldKey) 
              : const CreateProfileScreen();

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        } catch (e) {
          LogService.e("Profile check error", e);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
            );
          }
        }
      }
    } catch (e) {
      LogService.e("SPLASH ERROR", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Premium dark theme matching vitrine
      body: Stack(
        children: [
          // Dotted Background Effect (very subtle in dark mode)
          CustomPaint(
            painter: DottedPainter(),
            size: Size.infinite,
          ),
          
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Sleek Logo with Gradient
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF4B55),
                            Color(0xFFECB613),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4B55).withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 70,
                          color: Colors.black, // Dark contrast fire icon
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Brand Name - Elegant White Typography
                    Text(
                      'DENGİM',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Subtle elegant subtitle
                    Text(
                      'SESİNLE BAĞLAN',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 2;

    const double gap = 24;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
