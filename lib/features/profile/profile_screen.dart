import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/string_extensions.dart';
import '../auth/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'visitors_screen.dart';

import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/video_player_modal.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../payment/premium_offer_screen.dart';
import '../ads/screens/watch_and_earn_screen.dart';
import 'widgets/voice_profile_player.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında veri yoksa yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) {
        userProvider.loadCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final profile = userProvider.currentUser;

        if (userProvider.isLoading && profile == null) {
          return const Scaffold(
            backgroundColor: AppColors.scaffold,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final name = profile?.name ?? 'Kullanıcı';
        final age = profile?.age ?? 18;
        final photoUrl = (profile?.photoUrls != null && profile!.photoUrls!.isNotEmpty)
            ? profile.photoUrls!.first
            : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=500';
        final location = profile?.country ?? 'Konum Belirtilmedi';
        final bio = profile?.bio ?? 'Henüz bir biyografi eklenmemiş.';
        final job = profile?.job ?? 'Belirtilmedi';
        final education = profile?.education ?? 'Belirtilmedi';
        final interests = profile?.interests.join(', ') ?? 'Belirtilmedi';
        final zodiac = profile?.zodiacSign ?? '';
        final relGoalId = profile?.relationshipGoal ?? '';
        final String relGoal;
        if (relGoalId == 'serious') {
          relGoal = 'Ciddi İlişki 💍';
        } else if (relGoalId == 'casual') {
          relGoal = 'Eğlence 🥂';
        } else if (relGoalId == 'chat') {
          relGoal = 'Sohbet ☕';
        } else if (relGoalId == 'unsure') {
          relGoal = 'Belirsiz 🤷‍♂️';
        } else {
          relGoal = 'Belirtilmedi';
        }

        // Format joined date
        final String joinedDate;
        if (profile?.createdAt != null) {
          final months = [
            'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
            'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
          ];
          joinedDate = "${months[profile!.createdAt.month - 1]} ${profile.createdAt.year}";
        } else {
          joinedDate = 'Belirtilmedi';
        }


        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final elementColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Image with Soft Fade
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      height: 560,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: theme.colorScheme.surface),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                    // Soft fade gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 180,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Buttons at Top
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleIcon(
                              Icons.settings,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                            ),
                            _buildCircleIcon(
                              Icons.edit,
                              onTap: () {
                                if (profile != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfileScreen(profile: profile),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Profile Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${name.toTitleCase()}, $age',
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: elementColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (profile?.isVerified == true)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(Icons.verified, color: AppColors.primary, size: 28),
                            ),
                          if (profile?.isPremium == true) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _buildPremiumBadge(profile?.subscriptionTier ?? 'gold'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: elementColor.withValues(alpha: 0.6), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: elementColor.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildProfileCompletionCard(profile),
                      
                      const SizedBox(height: 40),
                      _buildSectionHeader('HAKKINDA'),
                      _buildBioCard(bio),

                      const SizedBox(height: 40),
                      _buildSectionHeader('DETAYLAR'),
                      _buildDetailsCard(job, education, interests, zodiac, relGoal, joinedDate),

                      if (profile?.profileVoiceUrl != null) ...[
                        const SizedBox(height: 40),
                        _buildSectionHeader('SES PROFİLİ'),
                        VoiceProfilePlayer(audioUrl: profile!.profileVoiceUrl!),
                      ],

                      if (profile?.videoUrl != null) ...[
                        const SizedBox(height: 40),
                        _buildSectionHeader('VİDEO PROFİL'),
                        _buildVideoPreview(profile!.videoUrl!),
                      ],

                      const SizedBox(height: 48),

                      _buildCreditAndTierCard(profile),
                      const SizedBox(height: 24),

                      // Premium Comparison Table (from humble-main)
                      _buildPremiumComparisonTable(),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.visibility_outlined,
                              label: 'ZİYARETÇİLER',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const VisitorsScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.share_outlined,
                              label: 'PAYLAŞ',
                              onTap: () {
                                if (profile != null) {
                                  Share.share('DENGİM uygulamasında beni bul! Kullanıcı Adım: ${profile.name} \n\nHemen indir: https://dengim.app');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildActionBtn(
                        icon: Icons.logout,
                        label: 'ÇIKIŞ YAP',
                        color: isDark ? const Color(0xFF1F1F23) : Colors.white,
                        textColor: isDark ? Colors.white70 : AppColors.textSecondary,
                        onTap: () async {
                          await AuthService().signOut();
                          if (context.mounted) {
                            context.read<UserProvider>().clearUser();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (c) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


    Widget _buildCircleIcon(IconData icon, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isDark ? null : [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: elementColor, size: 20),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: elementColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildBioCard(String bio) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppColors.neoRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark ? null : [AppColors.neoShadowSmall],
      ),
      child: Text(
        bio,
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: elementColor,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String job, String education, String interests, String zodiac, String relGoal, String joinedDate) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppColors.neoRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark ? null : [AppColors.neoShadowSmall],
      ),
      child: Column(
        children: [
          _buildDetailRow('MESLEK', job),
          _buildDetailRow('EĞİTİM', education),
          if (zodiac.isNotEmpty) _buildDetailRow('BURÇ', zodiac),
          if (relGoal != 'Belirtilmedi') _buildDetailRow('İLİŞKİ HEDEFİ', relGoal),
          _buildDetailRow('İLGİ ALANLARI', interests),
          _buildDetailRow('ÜYELİK TARİHİ', joinedDate, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: elementColor.withValues(alpha: 0.1), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 14, color: elementColor.withValues(alpha: 0.5), fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(fontSize: 14, color: elementColor, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color ?? cardBg,
          borderRadius: BorderRadius.circular(AppColors.neoRadiusSmall),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isDark ? null : [AppColors.neoShadowSmall],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor ?? elementColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: textColor ?? elementColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(String videoUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    return GestureDetector(
      onTap: () {
        _showVideoPlayer(videoUrl);
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.neoRadius),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'VİDEO PROFİLİNİ İZLE',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(String videoUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => VideoPlayerModal(videoUrl: videoUrl),
    );
  }

  // Profile Completion Calculator
  int _calculateCompletionPercentage(dynamic profile) {
    if (profile == null) return 0;
    
    int completed = 0;
    const int total = 9; // Name, photos, bio, job, education, interests, goal, country, video
    
    if (profile.name?.isNotEmpty ?? false) completed++;
    if ((profile.photoUrls?.length ?? 0) >= 3) completed++; // Has 3+ photos
    if (profile.bio?.isNotEmpty ?? false) completed++;
    if (profile.job?.isNotEmpty ?? false) completed++;
    if (profile.education?.isNotEmpty ?? false) completed++;
    if ((profile.interests?.length ?? 0) >= 3) completed++; // Has 3+ interests
    if (profile.relationshipGoal != null) completed++;
    if (profile.country?.isNotEmpty ?? false) completed++;
    if (profile.videoUrl != null) completed++;

    return ((completed / total) * 100).round();
  }

  String _getCompletionMessage(int percentage) {
    if (percentage == 100) return '🎉 Profilin mükemmel!';
    if (percentage >= 80) return '✨ Neredeyse tamamlandı!';
    if (percentage >= 60) return '👍 İyi gidiyorsun!';
    if (percentage >= 40) return '📝 Devam et!';
    return '🚀 Profilini tamamla!';
  }

  Widget _buildProfileCompletionCard(dynamic profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = _calculateCompletionPercentage(profile);
    final message = _getCompletionMessage(percentage);
    
    // Tam profil ise gösterme
    if (percentage == 100) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
          boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
              ),
              child: Icon(Icons.verified, color: isDark ? Colors.white : Colors.black, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    message.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PROFİLİN TAMAMEN DOLU VE KEŞFEDİLMEYE HAZIR!',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Eksik profil
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
        boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROFİL TAMAMLANMA',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '%$percentage',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white : Colors.black, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 12,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  message.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (profile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(profile: profile),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                  ),
                  child: Text(
                    'TAMAMLA',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge(String tier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlatinum = tier.toLowerCase() == 'platinum';

    final gradientColors = isPlatinum
        ? [const Color(0xFFE5E4E2), const Color(0xFFB4B4B4), const Color(0xFF708090)]
        : [const Color(0xFFFFD700), const Color(0xFFFFA500)];

    final badgeLabel = isPlatinum ? 'PLATINUM' : 'GOLD';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121418) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlatinum ? const Color(0xFFE5E4E2) : const Color(0xFFFFD700),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPlatinum ? const Color(0xFFE5E4E2) : const Color(0xFFFFD700))
                .withValues(alpha: isDark ? 0.25 : 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
            ).createShader(bounds),
            child: Icon(
              isPlatinum ? Icons.workspace_premium_rounded : Icons.star_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
            ).createShader(bounds),
            child: Text(
              badgeLabel,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditAndTierCard(dynamic profile) {
    return Consumer2<CreditProvider, SubscriptionProvider>(
      builder: (context, creditProvider, subProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tier = subProvider.currentTier;
        final isPremium = tier != 'free';
        final watchedCount = creditProvider.todayAdWatches;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14161B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${creditProvider.balance} Krediniz Var',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Ücretsiz kredi kazan veya harca',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (creditProvider.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF5722)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5722), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${creditProvider.streak} GÜN',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniBtn(
                      icon: Icons.play_circle_filled_rounded,
                      label: 'İZLE & KAZAN ($watchedCount/10)',
                      color: AppColors.primary,
                      textColor: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WatchAndEarnScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniBtn(
                      icon: isPremium ? Icons.workspace_premium_rounded : Icons.star_rounded,
                      label: isPremium ? tier.toUpperCase() : 'PAKETLER',
                      color: isDark ? const Color(0xFF262934) : const Color(0xFF14161B),
                      textColor: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumOfferScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium Comparison Table - Merged from humble-main
  Widget _buildPremiumComparisonTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    final plans = [
      PremiumPlanItem(title: 'Özel foto içgörüleri', gold: true, platinum: true),
      PremiumPlanItem(title: 'Beğenileri hızlandır', gold: true, platinum: true),
      PremiumPlanItem(title: 'Her gün öne çık', gold: true, platinum: true),
      PremiumPlanItem(title: 'Sınırsız beğeni', gold: true, platinum: false),
      PremiumPlanItem(title: 'Seni beğenenleri gör', gold: true, platinum: false),
      PremiumPlanItem(title: 'Gelişmiş filtreler', gold: true, platinum: false),
      PremiumPlanItem(title: 'Gizli mod', gold: true, platinum: false),
      PremiumPlanItem(title: 'Haftada 2 iltifat', gold: true, platinum: true),
      PremiumPlanItem(title: 'Konum değiştirme', gold: false, platinum: true),
      PremiumPlanItem(title: 'Süper beğeni + %50', gold: false, platinum: true),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF191B22) : const Color(0xFF090A0C),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PAKET KARŞILAŞTIRMASI',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildTierBadge('GOLD', const Color(0xFFFFD700)),
                const SizedBox(width: 8),
                _buildTierBadge('PLATINUM', AppColors.primary),
              ],
            ),
          ),
          // Table rows
          ...plans.map((plan) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    plan.title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Icon(
                    Icons.check_circle,
                    color: plan.gold ? AppColors.green : subColor,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Icon(
                    Icons.check_circle,
                    color: plan.platinum ? AppColors.green : subColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          )),
          // Upgrade buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          'GOLD\'A GEÇ',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE5E4E2), Color(0xFF708090)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          'PLATINUM\'A GEÇ',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color == const Color(0xFFFFD700) ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

/// Helper class for premium comparison table
class PremiumPlanItem {
  final String title;
  final bool gold;
  final bool platinum;

  PremiumPlanItem({required this.title, required this.gold, required this.platinum});
}
