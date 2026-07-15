import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Illustration Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Center(
                    child: _buildFaceScanIllustration(),
                  ),
                ),
              ),
            ),

            // Headline
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Text(
                'Profilini Doğrula',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Body Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'DENGIM topluluğunun güvenliğini sağlamak ve daha fazla prestijli eşleşme yakalamak için kimliğini doğrula. Sadece birkaç saniye sürer.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Benefits List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildBenefitRow(Icons.verified, 'Doğrulanmış rozeti al'),
                  const SizedBox(height: 16),
                  _buildBenefitRow(Icons.security, 'Güvenilir bir profil oluştur'),
                  const SizedBox(height: 16),
                  _buildBenefitRow(Icons.trending_up, '%80 daha fazla etkileşim'),
                ],
              ),
            ),

            const Spacer(),

            // CTA Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    // Start camera/verification process
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    'Şimdi Doğrula',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceScanIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Rings
        Container(
          width: 200,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          ),
        ),
        Container(
          width: 170,
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
          ),
        ),
        // Face Icon
        Icon(
          Icons.face_retouching_natural,
          size: 96,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
        // Scan Line
        Positioned(
          top: 130,
          child: Container(
            width: 200,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
