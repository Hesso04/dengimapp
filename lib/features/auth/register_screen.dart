// ImageFilter için gerekli
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'services/auth_service.dart';
import '../create_profile/create_profile_screen.dart';
import '../../core/utils/firebase_error_localizer.dart';
// import '../../features/main/main_scaffold.dart'; // Artık kullanılmıyor olabilir ama kalsın

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Şifreler eşleşmiyor.');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Şifre en az 6 karakter olmalıdır.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Kayıt başarılı, profil oluşturmaya yönlendir
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Profil oluşturmaya yönlendiriliyorsunuz...')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
          setState(() => _isLoading = false);
          _showError(FirebaseErrorLocalizer.localize(e));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "KAYIT OL",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black.withValues(alpha: 0.1), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Neo-Brutalist Icon Container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [AppColors.neoShadow],
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'HESAP OLUŞTUR',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aramıza katıl ve DENGİM dünyasının\nbir parçası ol.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 48),

              _buildTextField(
                controller: _emailController,
                hint: 'E-Posta Adresi',
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _passwordController,
                hint: 'Şifre',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Şifre Tekrar',
                icon: Icons.shield_outlined,
                isPassword: true,
              ),
              
              const SizedBox(height: 48),

              // Solid Button
              GestureDetector(
                onTap: _isLoading ? null : _register,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey.shade400 : AppColors.primary,
                    borderRadius: BorderRadius.circular(AppColors.neoRadius),
                    boxShadow: _isLoading ? [] : [AppColors.neoShadowSmall],
                  ),
                  child: Center(
                    child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                        : Text(
                            'KAYIT OL',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ZATEN HESABIN VAR MI? ',
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'GİRİŞ YAP',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary, // Sleek black highlighting instead of bright blue
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.neoRadius),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        enableSuggestions: !isPassword,
        autocorrect: !isPassword,
        style: GoogleFonts.outfit(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.black38,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: Colors.black54, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }
}
