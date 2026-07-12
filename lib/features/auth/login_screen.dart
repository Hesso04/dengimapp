import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'services/auth_service.dart';
import 'register_screen.dart';
import '../create_profile/create_profile_screen.dart';
import '../../features/main/main_scaffold.dart';

import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/log_service.dart';
import '../../core/utils/firebase_error_localizer.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        if (!mounted) return;
        await _checkProfileAndNavigate();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      LogService.e("Google Sign In Error", e);
      _showError(FirebaseErrorLocalizer.localize(e));
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser();
      
      if (!mounted) return;

      if (userProvider.currentUser != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
        );
      }
    } catch (e) {
      LogService.e("Profile Navigation Error", e);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
      );
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      LogService.e("Could not launch $urlString", e);
    }
  }

  void _showEmailLoginForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
        ),
        child: _EmailLoginForm(
          authService: _authService,
          onSuccess: _checkProfileAndNavigate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold, // Changed to pure/premium white background
      body: Stack(
        children: [
          // Dotted Background
          CustomPaint(
            painter: DottedPainter(),
            size: Size.infinite,
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Hero Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                              boxShadow: [AppColors.neoShadowLarge],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_fire_department_rounded, 
                                color: Colors.black, 
                                size: 70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Brand Name Plate
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black, // Sleek black badge
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [AppColors.neoShadow],
                            ),
                            child: Text(
                              'DENGİM',
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white, // White text
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [AppColors.neoShadowSmall],
                            ),
                            child: Text(
                              'RUH EŞİNİ BUL.',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 64),
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          _LoginButton(
                            icon: Icons.account_circle_rounded,
                            text: 'Google ile Giriş Yap',
                            color: Colors.white,
                            textColor: Colors.black,
                            onTap: _signInWithGoogle,
                          ),
                          const SizedBox(height: 16),
                          _LoginButton(
                            icon: Icons.alternate_email_rounded,
                            text: 'E-Posta ile Giriş Yap',
                            color: Colors.black,
                            textColor: Colors.white,
                            onTap: _showEmailLoginForm,
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              "HESABIN YOK MU? KAYIT OL",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 64),
                    
                    // Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'Devam ederek '),
                              TextSpan(
                                text: 'Kullanım Koşullarını',
                                style: const TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _launchUrl('https://dengim.app/terms'),
                              ),
                              const TextSpan(text: ' ve '),
                              TextSpan(
                                text: 'Gizlilik Politikamızı',
                                style: const TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _launchUrl('https://dengim.app/privacy'),
                              ),
                              const TextSpan(text: ' kabul etmiş olursunuz.'),
                            ],
                          ),
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

class _LoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _LoginButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppColors.neoRadius),
        border: color == Colors.white 
            ? Border.all(color: Color(0xFFEEEEEE), width: 1.0) 
            : null, // No border needed if background is solid black
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet Form for Email/Password
class _EmailLoginForm extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSuccess;

  const _EmailLoginForm({required this.authService, required this.onSuccess});

  @override
  State<_EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<_EmailLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = "Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = FirebaseErrorLocalizer.localize(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GİRİŞ YAP',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3), width: 1.0),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
            ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'E-posta',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Şifre',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white, // White text on black button
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.neoRadius),
              ),
              elevation: 0,
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
              : Text('GİRİŞ YAP', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
          ),
          const SizedBox(height: 32),
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
