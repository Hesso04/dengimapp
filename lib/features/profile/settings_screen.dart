import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../auth/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'blocked_users_screen.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'verification_screen.dart';
import '../auth/services/profile_service.dart';
import '../payment/premium_offer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;
  bool _notificationsEnabled = true;

  String get _userEmail => FirebaseAuth.instance.currentUser?.email ?? 'E-posta bağlı değil';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    String themeLabel = 'Cihaz Teması';
    if (themeProvider.themeMode == ThemeMode.light) themeLabel = 'Açık';
    if (themeProvider.themeMode == ThemeMode.dark) themeLabel = 'Koyu';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: elementColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AYARLAR",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: theme.textTheme.titleLarge?.color ?? elementColor,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("HESAP"),
                _buildSettingItem(
                  context, 
                  "E-posta Adresi", 
                  Icons.email_outlined, 
                  trailing: _userEmail,
                  onTap: () => _showInfoDialog("E-posta Adresi", "E-posta adresinizi değiştirmek için çıkış yapıp yeni hesap oluşturmanız gerekmektedir."),
                ),
                _buildSettingItem(
                  context, 
                  "Hesap Doğrulama", 
                  Icons.verified_user_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VerificationScreen()),
                  ),
                ),
                _buildSettingItem(
                  context, 
                  "Şifre Değiştir", 
                  Icons.lock_outline,
                  onTap: _showChangePasswordDialog,
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader("GİZLİLİK"),
                _buildSettingItem(
                  context, 
                  "Engellenen Kullanıcılar", 
                  Icons.block,
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader("KEŞFET"),
                _buildSettingItem(
                  context, 
                  "Seyahat Modu (Pasaport)", 
                  Icons.public_rounded,
                  trailing: "Mevcut Konumun",
                  onTap: _onPassportTap,
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader("PREMIUM MODLAR"),
                Consumer<UserProvider>(
                  builder: (context, provider, _) {
                    final user = provider.currentUser;
                    final isPremium = user?.isPremium ?? false;
                    
                    return Column(
                      children: [
                        _buildSwitchItem(
                          context,
                          "Hayalet Modu",
                          Icons.visibility_off_outlined,
                          user?.isGhostMode ?? false,
                          (value) async {
                            if (!isPremium) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
                              return;
                            }
                            await ProfileService().updateProfile(isGhostMode: value);
                          },
                        ),
                        _buildSwitchItem(
                          context,
                          "Gizli Mod",
                          Icons.security_outlined,
                          user?.isIncognitoMode ?? false,
                          (value) async {
                            if (!isPremium) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
                              return;
                            }
                            await ProfileService().updateProfile(isIncognitoMode: value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            "Hayalet Modu: Çevrimiçi durumunuzu gizler. Gizli Mod: Sadece beğendiğiniz kişiler sizi görebilir.",
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader("UYGULAMA"),
                _buildSwitchItem(
                  context,
                  "Bildirimler",
                  Icons.notifications_none,
                  _notificationsEnabled,
                  (value) {
                    setState(() => _notificationsEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.black,
                        content: Text(value ? 'BİLDİRİMLER AÇILDI' : 'BİLDİRİMLER KAPATILDI', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildSettingItem(context, "Dil Seçeneği", Icons.language, trailing: "Türkçe"),
                _buildSettingItem(
                  context,
                  "Tema Görünümü",
                  Icons.palette_outlined,
                  trailing: themeLabel,
                  onTap: () => _showThemeSelectionDialog(context, themeProvider),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader("HUKUKİ"),
                _buildSettingItem(
                  context, 
                  "Kullanım Koşulları", 
                  Icons.description_outlined,
                  onTap: () => _launchUrl("https://dengim.app/terms"),
                ),
                _buildSettingItem(
                  context, 
                  "Gizlilik Politikası", 
                  Icons.policy_outlined,
                  onTap: () => _launchUrl("https://dengim.app/privacy"),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader("DESTEK"),
                _buildSettingItem(
                  context,
                  "Yardım ve Destek",
                  Icons.help_outline,
                  onTap: () => _launchUrl("mailto:destek@dengim.app?subject=Destek Talebi"),
                ),
                _buildSettingItem(
                  context,
                  "Bizi Değerlendir",
                  Icons.star_outline,
                  onTap: () => _showInfoDialog("Değerlendirme", "Uygulama mağazada yayınlandıktan sonra değerlendirme yapabileceksiniz."),
                ),
                
                const SizedBox(height: 48),
                
                // Logout Button
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1B1D) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.0),
                      boxShadow: isDark ? null : [AppColors.neoShadowSmall],
                    ),
                    child: Center(
                      child: Text(
                        "ÇIKIŞ YAP",
                        style: GoogleFonts.outfit(
                          color: elementColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Delete Account Button
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(context),
                  child: Center(
                    child: Text(
                      "HESABIMI KALICI OLARAK SİL",
                      style: GoogleFonts.outfit(
                        color: AppColors.red,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                 Center(
                  child: Text(
                    "v1.0.0 (B100)",
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          if (_isDeleting)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 5),
                    const SizedBox(height: 24),
                    Text(
                      'HESAP SİLİNİYOR...',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: elementColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, 
    String title, 
    IconData icon, 
    {String? trailing, VoidCallback? onTap}
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1B1D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isDark ? null : [AppColors.neoShadowSmall],
        ),
        child: Row(
          children: [
            Icon(icon, color: elementColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(color: elementColor, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            if (trailing != null)
              Flexible(
                child: Text(
                  trailing,
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, color: elementColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1B1D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark ? null : [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          Icon(icon, color: elementColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(color: elementColor, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          Theme(
            data: theme.copyWith(
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.all(value ? Colors.white : Colors.grey[300]),
                trackColor: WidgetStateProperty.all(value ? AppColors.primary : (isDark ? Colors.grey[800] : Colors.grey[200])),
              ),
            ),
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        title: Text(title.toUpperCase(), style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w900)),
        content: Text(message, style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            child: Text("TAMAM", style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w900)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        title: Text("ŞİFRE SIFIRLA", style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w900)),
        content: Text(
          "E-POSTA ADRESİNİZE ŞİFRE SIFIRLAMA BAĞLANTISI GÖNDERİLSİN Mİ?\n\n$_userEmail",
          style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            child: Text("İPTAL", style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w900)),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(120, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1.0),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await AuthService().resetPassword(_userEmail);
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.black,
                    content: Text('ŞİFRE SIFIRLAMA E-POSTASI GÖNDERİLDİ!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  ErrorHandler.showError(dialogContext, "Hata: $e");
                }
              }
            },
            child: Text("GÖNDER", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ErrorHandler.showError(context, "Bağlantı açılamıyor. Lütfen daha sonra tekrar deneyin.");
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, "Bağlantı açılamıyor. Lütfen daha sonra tekrar deneyin.");
      }
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        context.read<UserProvider>().clearUser();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (c) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, "Çıkış yapılamadı: $e");
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.colorScheme.surface;
    final elementColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.red, size: 28),
            const SizedBox(width: 12),
            Text("HESABINI SİL?", style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BU İŞLEM GERİ ALINAMAZ!\n",
              style: GoogleFonts.outfit(color: AppColors.red, fontWeight: FontWeight.w900),
            ),
            Text(
              "• PROFİLİN KALICI OLARAK SİLİNECEK\n• TÜM EŞLEŞMELERİN KAYBOLACAK\n• MESAJ GEÇMİŞİN SİLİNECEK",
              style: GoogleFonts.outfit(color: elementColor, fontWeight: FontWeight.w700, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("İPTAL", style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black, fontWeight: FontWeight.w900)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1.0),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: Text("EVET, SİL", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    
    try {
      await AuthService().deleteAccount();
      
      if (mounted) {
        context.read<UserProvider>().clearUser();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (c) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ErrorHandler.showError(context, "Hesap silinemedi: $e");
      }
    }
  }

  void _onPassportTap() {
    final userProvider = context.read<UserProvider>();
    final isPremium = userProvider.currentUser?.isPremium ?? false;

    if (!isPremium) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
       return;
    }

    _showPassportDialog();
  }

  void _showPassportDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.scaffoldDark : Colors.white;
    final elementColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: borderColor, width: 1.0)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 60, 
              height: 6, 
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12, 
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "DENGİM PASAPORT",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: elementColor),
            ),
            const SizedBox(height: 8),
            Text(
              "İSTEDİĞİN ŞEHRE IŞINLAN VE EŞLEŞ!",
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                   _buildCityItem("Mevcut Konumum", Icons.my_location, isSelected: true),
                   _buildCityItem("İstanbul", Icons.location_city),
                   _buildCityItem("Ankara", Icons.location_city),
                   _buildCityItem("İzmir", Icons.location_city),
                   _buildCityItem("Antalya", Icons.location_city),
                   _buildCityItem("Londra", Icons.public),
                   _buildCityItem("New York", Icons.public),
                   _buildCityItem("Paris", Icons.public),
                   _buildCityItem("Tokyo", Icons.public),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCityItem(String name, IconData icon, {bool isSelected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemBgColor = isSelected 
        ? AppColors.primary 
        : (isDark ? AppColors.cardDark : Colors.white);
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final textColor = isSelected ? Colors.white : (isDark ? Colors.white : Colors.black);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? Colors.transparent : borderColor, width: 1.0),
        boxShadow: isSelected || isDark ? null : [AppColors.neoShadowSmall],
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black), size: 28),
        title: Text(name.toUpperCase(), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w900, fontSize: 16)),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.white) : null,
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.black,
              content: Text('$name BÖLGESİNE IŞINLANILIYOR...', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
            )
          );
        },
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        title: Text(
          "TEMA SEÇİNİZ",
          style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOptionTile(
              context,
              title: "AÇIK TEMA",
              icon: Icons.light_mode_outlined,
              isSelected: themeProvider.themeMode == ThemeMode.light,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOptionTile(
              context,
              title: "KOYU TEMA",
              icon: Icons.dark_mode_outlined,
              isSelected: themeProvider.themeMode == ThemeMode.dark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOptionTile(
              context,
              title: "CİHAZ TEMASI",
              icon: Icons.brightness_auto_outlined,
              isSelected: themeProvider.themeMode == ThemeMode.system,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1B1B1D) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : borderColor, width: 1.0),
          boxShadow: isSelected || isDark ? null : [AppColors.neoShadowSmall],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
