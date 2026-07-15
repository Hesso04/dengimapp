import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Yüzeyselliğe Veda",
      description: "Sadece fotoğraflara bakarak karar vermekten sıkılmadın mı? Karakterin ön planda.",
      color: AppColors.secondary, // Neo Pink
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    OnboardingData(
      title: "Uyumunu Keşfet",
      description: "Burç uyumları ve ortak zevklere dayalı eşleşme sistemiyle kimyanı bul.",
      color: AppColors.primary, // Neo Yellow
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingData(
      title: "Canlı Topluluk",
      description: "Canlı odalara katıl, sesli sohbet et ve seninle aynı vibe'a sahip insanlarla tanış.",
      color: AppColors.blue, // Neo Blue
      icon: Icons.radio_rounded,
    )
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_currentPage];
    
    return Scaffold(
      backgroundColor: current.color,
      body: Stack(
        children: [
          // Dotted Background
          CustomPaint(
            painter: DottedPainter(),
            size: Size.infinite,
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Top Indicators & Skip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(_pages.length, (index) => _buildIndicator(index)),
                      ),
                      TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          textStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black,
                            decorationThickness: 2,
                          ),
                        ),
                        child: const Text('ATLA'),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Icon/Graphic Container
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      key: ValueKey(_currentPage),
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                        boxShadow: [AppColors.neoShadowSmall],
                      ),
                      child: Center(
                        child: Icon(
                          current.icon,
                          size: 100,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Title Area
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                      boxShadow: [AppColors.neoShadowSmall],
                    ),
                    child: Text(
                      current.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                      boxShadow: [AppColors.neoShadowSmall],
                    ),
                    child: Text(
                      current.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Navigation Button
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          setState(() => _currentPage++);
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: AppTheme.lightTheme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: const WidgetStatePropertyAll(Colors.white),
                        foregroundColor: const WidgetStatePropertyAll(Colors.black),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'PROFİLİ OLUŞTUR' : 'İLERİ',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_rounded, 
                            color: Colors.black,
                            weight: 900,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
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
