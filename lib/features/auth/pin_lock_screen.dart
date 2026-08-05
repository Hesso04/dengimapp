import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/pin_lock_service.dart';
import 'services/auth_service.dart';
import 'login_screen.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool isSettingPinMode;

  const PinLockScreen({
    super.key,
    required this.onUnlocked,
    this.isSettingPinMode = false,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _firstPinAttempt = '';
  bool _isConfirming = false;
  String _errorMessage = '';
  bool _isError = false;

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isError = false;
      _errorMessage = '';
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _processPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      _errorMessage = '';
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _processPin() async {
    if (widget.isSettingPinMode) {
      if (!_isConfirming) {
        // İlk PIN girildi
        setState(() {
          _firstPinAttempt = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        // İkinci doğrulama PIN'i girildi
        if (_enteredPin == _firstPinAttempt) {
          final success = await PinLockService().setPin(_enteredPin);
          if (success && mounted) {
            HapticFeedback.mediumImpact();
            widget.onUnlocked();
          }
        } else {
          HapticFeedback.vibrate();
          setState(() {
            _isError = true;
            _errorMessage = 'PIN kodları eşleşmedi! Lütfen tekrar deneyin.';
            _enteredPin = '';
            _firstPinAttempt = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Normal Kilit Açma Modu
      final isValid = await PinLockService().verifyPin(_enteredPin);
      if (isValid) {
        HapticFeedback.mediumImpact();
        widget.onUnlocked();
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isError = true;
          _errorMessage = 'Hatalı PIN kodu! Lütfen tekrar giriniz.';
          _enteredPin = '';
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14161B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Çıkış Yapılsın mı?',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Oturumunuz kapatılacak ve yeniden giriş yapmanız gerekecek.',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İPTAL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ÇIKIŞ YAP', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await PinLockService().removePin();
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090A0C) : const Color(0xFFF7F8FA);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    String titleText = 'GÜVENLİK KİLİDİ';
    String subtitleText = 'Uygulamaya erişmek için 4 haneli PIN kodunuzu girin.';

    if (widget.isSettingPinMode) {
      titleText = _isConfirming ? 'PIN KODUNU ONAYLAYIN' : 'YENİ PIN KODU BELİRLEYİN';
      subtitleText = _isConfirming
          ? 'Doğrulamak için 4 haneli PIN kodunuzu tekrar girin.'
          : 'Uygulamanızı korumak için 4 haneli bir PIN belirleyin.';
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),

              // Kilit İkonu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),

              // Başlık & Açıklama
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // PIN Noktaları (● ● ● ●)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? AppColors.error
                          : isFilled
                              ? AppColors.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: _isError
                            ? AppColors.error
                            : isFilled
                                ? AppColors.primary
                                : (isDark ? Colors.white38 : Colors.black26),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const Spacer(),

              // Nümerik Tuş Takımı (3x4)
              _buildKeypad(isDark, textColor),

              const SizedBox(height: 24),

              // Çıkış Yap / Hesabı Yeniden Aç Butonu
              if (!widget.isSettingPinMode)
                TextButton(
                  onPressed: _handleLogout,
                  child: Text(
                    'Şifremi Unuttum / Çıkış Yap',
                    style: GoogleFonts.outfit(
                      color: subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark, Color textColor) {
    final keyBg = isDark ? const Color(0xFF1E212A) : const Color(0xFFEFEFEF);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((digit) => _buildKeyButton(digit, keyBg, textColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((digit) => _buildKeyButton(digit, keyBg, textColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((digit) => _buildKeyButton(digit, keyBg, textColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72),
            _buildKeyButton('0', keyBg, textColor),
            InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(36),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Center(
                  child: Icon(Icons.backspace_outlined, color: textColor, size: 24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyButton(String digit, Color keyBg, Color textColor) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: keyBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
