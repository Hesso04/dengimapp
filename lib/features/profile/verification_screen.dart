import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // YENİ
import 'dart:io'; // Sadece mobil içindir. Web'de File Image hata vermemesi için kIsWeb ile saklanmalı
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../auth/services/profile_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  XFile? _selfieImage; // Değiştirildi
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takeSelfie() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _selfieImage = photo;
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_selfieImage == null) return;

    setState(() => _isUploading = true);

    try {
      await ProfileService().requestVerification(_selfieImage!);
      
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
            ),
            title: Text('BAŞVURU ALINDI ✅', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900)),
            content: Text(
              'PROFİL DOĞRULAMA İSTEĞİN BİZE ULAŞTI. EDİTÖRLERİMİZ İNCELEYİP ONAYLAYACAK.',
              style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black, fontWeight: FontWeight.w700),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Screen
                },
                child: Text('TAMAM', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, "Yükleme hatası: $e");
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final scaffoldBg = isDark ? AppColors.scaffoldDark : AppColors.scaffold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: elementColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "PROFİLİ DOĞRULA",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: elementColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Icon & Info
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: isDark ? [] : [AppColors.neoShadow],
              ),
              child: const Icon(Icons.verified_user_rounded, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              "MAVİ TİK AL ☑️",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: elementColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "SAHTE PROFİLLERDEN BİZ DE SIKILDIK. GERÇEK BİR KİŞİ OLDUĞUNU KANITLAMAK İÇİN ANLIK BİR SELFİE ÇEK.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const Spacer(),
            
            // Image Preview Area
            if (_selfieImage != null)
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: isDark ? [] : [AppColors.neoShadow],
                  image: DecorationImage(
                    image: kIsWeb ? NetworkImage(_selfieImage!.path) : FileImage(File(_selfieImage!.path)) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: _takeSelfie,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isDark ? [] : [AppColors.neoShadow],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 64, color: elementColor),
                      const SizedBox(height: 16),
                      Text(
                        "SELFİE ÇEKMEK İÇİN DOKUN", 
                        style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w900)
                      ),
                    ],
                  ),
                ),
              ),
              
            const Spacer(),
            
            // Buttons
            if (_selfieImage == null)
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _takeSelfie,
                  icon: Icon(Icons.camera_alt, color: isDark ? Colors.white : Colors.black),
                  label: Text("KAMERAYI AÇ", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.neoRadius),
                    ),
                    elevation: 0,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: OutlinedButton(
                        onPressed: _isUploading ? null : _takeSelfie,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: elementColor,
                          side: BorderSide(color: borderColor, width: 1.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.neoRadius)),
                        ),
                        child: Text("TEKRAR ÇEK", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _submitVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: isDark ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppColors.neoRadius),
                          ),
                          elevation: 0,
                        ),
                        child: _isUploading 
                          ? CircularProgressIndicator(color: isDark ? Colors.white : Colors.black)
                          : Text("GÖNDER", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
