import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_scaffold.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/theme/app_colors.dart';
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
import 'core/providers/story_provider.dart';
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

import 'features/spaces/providers/space_provider.dart';
import 'core/widgets/maintenance_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LogService.i('Handling a background message: ${message.messageId}');
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

    // Remote Configuration'ı başlat
    await ConfigService().init();
    await FeatureFlagService().init();
    await AdService().init();

    // Bildirim servisini başlat
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
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
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => SystemConfigProvider()),
        ChangeNotifierProvider(create: (_) => SpaceProvider()),
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
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.bounceOut)),
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
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final prefs = await SharedPreferences.getInstance();
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
      } else {
        final user = FirebaseAuth.instance.currentUser;
        
        if (user == null) {
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

            final creditProvider = Provider.of<CreditProvider>(context, listen: false);
            await creditProvider.init();
            await creditProvider.claimDailyReward();

            if (!mounted) return;

            Widget nextScreen = userProvider.currentUser != null 
                ? const MainScaffold() 
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
      }
    } catch (e) {
      LogService.e("SPLASH ERROR", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue, // Neo Blue background
      body: Stack(
        children: [
          // Dotted Background Effect
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
                    // Neo Logo Container
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.black, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(8, 8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 90,
                          color: AppColors.primary, // Yellow flame
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Brand Name
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'DENGİM',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'RUH EŞİNİ BUL',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
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
