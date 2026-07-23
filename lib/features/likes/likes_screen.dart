import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import '../payment/premium_offer_screen.dart';

import 'package:provider/provider.dart';
import '../../core/providers/likes_provider.dart';
import '../../core/providers/badge_provider.dart';
import '../../core/providers/user_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';


class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  int _activeTab = 0; // 0: Seni Beğenenler, 1: Eşleşmeler
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _onlyOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LikesProvider>();
      provider.initStreams(); // Gerçek zamanlı dinleme
      provider.loadMatches();
      provider.loadLikedMeUsers();
      
      // Bildirimleri temizle
      if (mounted) {
        context.read<BadgeProvider>().markLikesAsViewed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<LikesProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildTabs(),

                Expanded(
                  child: provider.isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (_activeTab == 1) ...[
                        // Eşleşmeler Listesi (Grid)
                        if (provider.matches.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyMatches(),
                          )
                        else
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _UnlockedLikeCard(
                                user: provider.matches[index],
                                showActions: false, // Eşleşmelerde aksiyon yok
                              ),
                              childCount: provider.matches.length,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Seni Beğenenler Section
                        SliverToBoxAdapter(
                          child: _buildNewMatchesSection(provider.matches),
                        ),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final isPremium = userProvider.currentUser?.isPremium ?? false;
                            
                            if (!isPremium) {
                              return SliverMainAxisGroup(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "SENİ BEĞENENLER",
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                   SliverToBoxAdapter(
                                    child: _buildSearchAndFilter(false),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.75,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => const _LockedLikeCard(),
                                        childCount: provider.likedMeUsers.length,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return SliverMainAxisGroup(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: _buildSearchAndFilter(isPremium),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.all(20),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final allLikedUsers = provider.likedMeUsers;
                                        final filteredUsers = allLikedUsers.where((user) {
                                          final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
                                          final matchesOnline = !_onlyOnline || user.isOnline;
                                          return matchesSearch && matchesOnline;
                                        }).toList();
                                        
                                        if (index >= filteredUsers.length) return null;
                                        return _UnlockedLikeCard(user: filteredUsers[index]);
                                      },
                                      childCount: provider.likedMeUsers.where((user) {
                                        final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
                                        final matchesOnline = !_onlyOnline || user.isOnline;
                                        return matchesSearch && matchesOnline;
                                      }).length,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (provider.likedMeUsers.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                              child: Column(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.favorite_rounded, size: 60, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    "PROFİLİNİ GÜÇLENDİR 💪",
                                    style: GoogleFonts.outfit(
                                      color: theme.colorScheme.onSurface, 
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Daha fazla fotoğraf ekle ve\nilgi çekici bir biyografi yaz.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: isDark ? Colors.white70 : AppColors.textSecondary, 
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isPremium) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(AppColors.neoRadius),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    enabled: isPremium,
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                      hintText: 'Beğenilerde ara...',
                      hintStyle: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (!isPremium) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
                  } else {
                    setState(() => _onlyOnline = !_onlyOnline);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _onlyOnline ? AppColors.green : fillColor,
                    borderRadius: BorderRadius.circular(AppColors.neoRadius),
                    boxShadow: _onlyOnline ? [AppColors.neoShadowSmall] : [],
                  ),
                  child: Center(
                    child: Text(
                      'Online',
                      style: GoogleFonts.outfit(
                        color: _onlyOnline ? Colors.white : subColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Beğenileri filtrelemek için Platinum\'a yükselt',
                    style: GoogleFonts.outfit(
                      color: subColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewMatchesSection(List<UserProfile> matches) {
    if (matches.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            "YENİ EŞLEŞMELER",
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final user = matches[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: [AppColors.neoShadowSmall],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: CachedNetworkImage(
                          imageUrl: user.imageUrl,
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: isDark ? Colors.black26 : Colors.black12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final bg = isDark ? AppColors.scaffoldDark : AppColors.scaffold;
    final iconBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final canPop = Navigator.canPop(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canPop)
            GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppColors.neoRadius),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
              ),
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppColors.neoRadius),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            ),
          Text(
            'Beğeniler',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showSortFilterModal();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppColors.neoRadius),
              ),
              child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sıralama & Filtreleme',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.circle, color: AppColors.green, size: 16),
              title: Text('Sadece Çevrimiçiler', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              trailing: Switch(
                value: _onlyOnline,
                onChanged: (val) {
                  setState(() => _onlyOnline = val);
                  Navigator.pop(ctx);
                },
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.scaffoldDark : AppColors.scaffold;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(child: _buildTabItem('Seni Beğenenler', 0)),
          const SizedBox(width: 10),
          Expanded(child: _buildTabItem('Eşleşmeler', 1)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isActive = _activeTab == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final inactiveText = isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : inactiveBg,
          borderRadius: BorderRadius.circular(AppColors.neoRadius),
          boxShadow: isActive ? [AppColors.primaryShadow] : [],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : inactiveText,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMatches() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              shape: BoxShape.circle,
              boxShadow: [AppColors.neoShadow],
            ),
            child: const Icon(Icons.favorite_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz eşleşme yok',
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keşfet\'e gidip insanları beğenmeye başla.\nKarşılıklı beğeniler eşleşme oluşturur!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: subColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedLikeCard extends StatelessWidget {
  const _LockedLikeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen())),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Abstract gradient background instead of a misleading photo
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD166),
                      Color(0xFFFF6B6B),
                      Color(0xFFC084FC),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              // Blur overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
              // Lock icon and text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.0),
                      boxShadow: [AppColors.neoShadowSmall],
                    ),
                    child: Icon(Icons.lock_outline_rounded, color: isDark ? Colors.white : Colors.black, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "GÖRMEK İÇİN\nPREMIUM'A GEÇ",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Beğeni kartı - Kabul/Ret butonlarıyla etkileşimli
class _UnlockedLikeCard extends StatelessWidget {
  final UserProfile user;
  final bool showActions; // Beğeniler için kabul/ret, eşleşmeler için false
  
  const _UnlockedLikeCard({
    required this.user, 
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.5);
    final isSuperLike = context.watch<LikesProvider>().superLikerIds.contains(user.uid);

    return GestureDetector(
      onTap: () => _showProfileDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSuperLike ? Colors.amber : borderColor, width: isSuperLike ? 1.5 : 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              CachedNetworkImage(
                imageUrl: user.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: isDark ? Colors.black26 : Colors.white),
              ),

              if (isSuperLike)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.0),
                      boxShadow: const [
                        BoxShadow(color: Colors.amberAccent, blurRadius: 6, spreadRadius: 1)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          "SÜPER",
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Info Area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(top: BorderSide(color: borderColor, width: 1.0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${user.name}, ${user.age}".toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: textColor, size: 10),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.location.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: subColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (showActions) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _rejectLike(context),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor, width: 1.0),
                                    boxShadow: [AppColors.neoShadowSmall],
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _acceptLike(context),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor, width: 1.0),
                                    boxShadow: [AppColors.neoShadowSmall],
                                  ),
                                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Like Icon (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _acceptLike(BuildContext context) async {
    final provider = context.read<LikesProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    
    final matched = await provider.likeBack(user.uid);
    navigator.pop(); // Loading kapat
    
    if (matched) {
      // Eşleşme animasyonu/bildirimi
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${user.name} İLE EŞLEŞTİNİZ! 🎉',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _rejectLike(BuildContext context) async {
    final provider = context.read<LikesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.rejectLike(user.uid);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${user.name} REDDEDİLDİ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showProfileDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
              left: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
              right: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Profil fotoğrafı
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    boxShadow: [AppColors.neoShadowSmall],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: CachedNetworkImage(
                      imageUrl: user.imageUrl,
                      width: double.infinity,
                      height: 400,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.black)),
                      errorWidget: (context, url, error) => Container(
                        height: 400,
                        color: Colors.white,
                        child: const Icon(Icons.person, size: 100, color: Colors.black26),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user.name}, ${user.age}".toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      
                      ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            user.location.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                      
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          "HAKKINDA",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.bio!,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      if (showActions)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _rejectLike(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                                    boxShadow: [AppColors.neoShadowSmall],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.close, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text("GEÇ", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _acceptLike(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                                    boxShadow: [AppColors.neoShadowSmall],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text("EŞLEŞ", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



