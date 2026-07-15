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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  void _signInWithGoogle() async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        if (!mounted) return;
        await _checkProfileAndNavigate();
      }
    } catch (e) {
      if (!mounted) return;
      LogService.e("Google Sign In Error", e);
      _showError(FirebaseErrorLocalizer.localize(e));
    }
  }

  void _signInWithFacebook() async {
    try {
      final userCredential = await _authService.signInWithFacebook();
      if (userCredential != null) {
        if (!mounted) return;
        await _checkProfileAndNavigate();
      }
    } catch (e) {
      if (!mounted) return;
      LogService.e("Facebook Sign In Error", e);
      _showError(FirebaseErrorLocalizer.localize(e));
    }
  }

  void _showPhoneLoginForm() {
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
        child: _PhoneLoginForm(
          authService: _authService,
          onSuccess: _checkProfileAndNavigate,
        ),
      ),
    );
  }

  void _showEmailLinkLoginForm() {
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
        child: _EmailLinkLoginForm(
          authService: _authService,
          onSuccess: _checkProfileAndNavigate,
        ),
      ),
    );
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
                          const SizedBox(height: 16),
                          _LoginButton(
                            icon: Icons.phone_iphone_rounded,
                            text: 'Telefon Numarası ile Giriş',
                            color: Colors.white,
                            textColor: Colors.black,
                            onTap: _showPhoneLoginForm,
                          ),
                          const SizedBox(height: 16),
                          _LoginButton(
                            icon: Icons.link_rounded,
                            text: 'E-Posta Linki (Şifresiz) Giriş',
                            color: Colors.white,
                            textColor: Colors.black,
                            onTap: _showEmailLinkLoginForm,
                          ),
                          const SizedBox(height: 16),
                          _LoginButton(
                            icon: Icons.facebook_outlined,
                            text: 'Facebook ile Giriş Yap',
                            color: const Color(0xFF1877F2),
                            textColor: Colors.white,
                            onTap: _signInWithFacebook,
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

// Bottom Sheet Form for Phone / OTP Login
class _PhoneLoginForm extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSuccess;

  const _PhoneLoginForm({required this.authService, required this.onSuccess});

  @override
  State<_PhoneLoginForm> createState() => _PhoneLoginFormState();
}

class _PhoneLoginFormState extends State<_PhoneLoginForm> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = "Lütfen telefon numaranızı girin.");
      return;
    }

    // Format phone if it doesn't start with +
    final formattedPhone = phone.startsWith('+') ? phone : '+$phone';

    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verId) {
          if (mounted) {
            setState(() {
              _verificationId = verId;
              _isLoading = false;
              _error = null;
            });
          }
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = FirebaseErrorLocalizer.localize(e);
            });
          }
        },
        onVerificationCompleted: (credential) async {
          // Auto login on native devices if detected
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) {
              Navigator.pop(context);
              widget.onSuccess();
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = FirebaseErrorLocalizer.localize(e);
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = FirebaseErrorLocalizer.localize(e);
        });
      }
    }
  }

  void _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      setState(() => _error = "Lütfen doğrulama kodunu girin.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.signInWithPhoneCode(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = FirebaseErrorLocalizer.localize(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showOtpField = _verificationId != null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            showOtpField ? 'SMS KODUNU GİRİN' : 'TELEFON İLE GİRİŞ',
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
          
          if (!showOtpField) ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Telefon Numarası (Örn: +905551234567)',
                prefixIcon: Icon(Icons.phone_outlined, color: Colors.black),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.neoRadius),
                ),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : Text('KOD GÖNDER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '6 Haneli Doğrulama Kodu',
                prefixIcon: Icon(Icons.security, color: Colors.black),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _verificationId = null;
                  _codeController.clear();
                });
              },
              child: Text(
                'Numarayı Değiştir',
                style: GoogleFonts.outfit(color: Colors.black54, fontWeight: FontWeight.w900),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Bottom Sheet Form for Passwordless Email Link Login
class _EmailLinkLoginForm extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSuccess;

  const _EmailLinkLoginForm({required this.authService, required this.onSuccess});

  @override
  State<_EmailLinkLoginForm> createState() => _EmailLinkLoginFormState();
}

class _EmailLinkLoginFormState extends State<_EmailLinkLoginForm> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _linkSent = false;

  @override
  void initState() {
    super.initState();
    _loadStoredEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email_link_login_email');
    if (storedEmail != null && storedEmail.isNotEmpty && mounted) {
      _emailController.text = storedEmail;
    }
  }

  void _sendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Lütfen e-posta adresinizi girin.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      // Save email for linking verification later
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_link_login_email', email);

      await widget.authService.sendSignInLinkToEmail(email);
      if (mounted) {
        setState(() {
          _linkSent = true;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = FirebaseErrorLocalizer.localize(e);
        });
      }
    }
  }

  void _verifyLink() async {
    final link = _linkController.text.trim();
    final email = _emailController.text.trim();
    
    if (link.isEmpty) {
      setState(() => _error = "Lütfen e-postanıza gelen linki yapıştırın.");
      return;
    }

    if (!widget.authService.isSignInWithEmailLink(link)) {
      setState(() => _error = "Geçersiz giriş bağlantısı. Lütfen tekrar deneyin.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.signInWithEmailLink(email, link);
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = FirebaseErrorLocalizer.localize(e);
        });
      }
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
            _linkSent ? 'GİRİŞ LİNKİNİ ONAYLA' : 'ŞİFRESİZ MAİL GİRİŞİ',
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
          
          if (!_linkSent) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'E-posta Adresi',
                prefixIcon: Icon(Icons.email_outlined, color: Colors.black),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.neoRadius),
                ),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : Text('GİRİŞ LİNKİ GÖNDER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
                boxShadow: [AppColors.neoShadowSmall],
              ),
              child: Column(
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 48, color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    'Bağlantı Gönderildi!',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_emailController.text} adresine gönderilen linke tıklayabilir veya o linki kopyalayıp aşağıdaki kutuya yapıştırarak giriş yapabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _linkController,
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Giriş linkini buraya yapıştırın...',
                prefixIcon: Icon(Icons.link_outlined, color: Colors.black),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _linkSent = false;
                  _linkController.clear();
                });
              },
              child: Text(
                'E-postayı Değiştir / Yeniden Gönder',
                style: GoogleFonts.outfit(color: Colors.black54, fontWeight: FontWeight.w900),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
