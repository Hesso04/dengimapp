import 'package:flutter/material.dart';

/// DENGİM Renk Paleti — Modern Dating App (Tinder/Bumble/Hinge segmenti)
class AppColors {
  AppColors._();

  // ─── Ana Renkler ──────────────────────────────────────────────────
  static const Color scaffold = Color(0xFFFDFDFD);       // Light arka plan
  static const Color scaffoldDark = Color(0xFF0F0F0F);   // Dark arka plan
  static const Color primary = Color(0xFFFF4B55);        // Rose-Red — sadece aksiyon
  static const Color primaryLight = Color(0xFFFF8A8F);   // Gradient uç rengi
  static const Color secondary = Color(0xFF6B7280);      // Kaliteli Gri

  // ─── Soft Accent ──────────────────────────────────────────────────
  static const Color blue = Color(0xFF4FA8D1);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF59E0B);
  static const Color vibrantGold = Color(0xFFD4AF37);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Gradient Tanımları ───────────────────────────────────────────
  /// Premium Rose-Red gradient — Platinum/Kredi kartı ve FAB
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4B55), Color(0xFFFF8A8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// VIP / Gold gradient
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFA67C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Metin Renkleri ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF9CA3AF);  // Soluk gri (son mesaj vb.)
  static const Color textTertiary = Color(0xFFD1D5DB);

  // ─── Yüzey Renkleri ───────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF2F2F2);   // Input, search bar dolgusu
  static const Color surfaceDark = Color(0xFF1A1A1A);    // Dark mode input dolgusu
  static const Color cardDark = Color(0xFF1C1C1E);       // Dark mode kart arka planı
  static const Color borderLight = Color(0xFFF0F0F0);    // Çok hafif border (isteğe bağlı)
  static const Color borderDark = Color(0xFF2A2A2E);

  // ─── Durum Renkleri ───────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ─── Tasarım Tokenları ────────────────────────────────────────────
  /// Standart border-radius: buton, input, kart
  static const double neoRadius = 16.0;
  static const double neoRadiusSmall = 10.0;
  static const double neoRadiusLarge = 24.0;
  static const double neoRadiusXL = 32.0;

  // Border genişlikleri (minimalist)
  static const double neoBorderWidth = 1.0;
  static const double neoBorderWidthPixels = 1.0;
  static const double neoBorderWidthSmall = 0.5;
  static const double neoBorderWidthSmallPixels = 0.5;
  static const double neoBorderWidthLarge = 1.5;
  static const double neoBorderWidthLargePixels = 1.5;

  // ─── Soft Shadows (0 4px 20px rgba(0,0,0,0.05)) ──────────────────
  static BoxShadow get neoShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    offset: const Offset(0, 4),
    blurRadius: 20,
    spreadRadius: 0,
  );

  static BoxShadow get neoShadowLarge => BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    offset: const Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
  );

  static BoxShadow get neoShadowSmall => BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    offset: const Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  /// Primary renk gölgesi — aksiyon butonları için
  static BoxShadow get primaryShadow => BoxShadow(
    color: primary.withValues(alpha: 0.30),
    offset: const Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );
}
