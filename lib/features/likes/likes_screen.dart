import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                                              color: Colors.black,
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
                                      color: Colors.black, 
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Daha fazla fotoğraf ekle ve\nilgi çekici bir biyografi yaz.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary, 
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    boxShadow: [AppColors.neoShadowSmall],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    enabled: isPremium,
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.outfit(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      hintText: "BEĞENİLERDE ARA...",
                      hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (!isPremium) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
                  } else {
                    setState(() => _onlyOnline = !_onlyOnline);
                  }
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _onlyOnline ? AppColors.green : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    boxShadow: [AppColors.neoShadowSmall],
                  ),
                  child: Center(
                    child: Text(
                      "ONLINE",
                      style: GoogleFonts.outfit(
                        color: _onlyOnline ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
                  const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    "BEĞENİLERİ FİLTRELEMEK İÇİN PLATINUM'A YÜKSEL",
                    style: GoogleFonts.outfit(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
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
              color: Colors.black,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                        boxShadow: [AppColors.neoShadowSmall],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: CachedNetworkImage(
                          imageUrl: user.imageUrl,
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.black12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIcon(Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
          Text(
            "BEĞENİLER",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          _buildCircleIcon(Icons.filter_list_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildTabItem("SENİ BEĞENENLER", 0)),
          const SizedBox(width: 12),
          Expanded(child: _buildTabItem("EŞLEŞMELER", 1)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.white : Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMatches() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            "HENÜZ EŞLEŞME YOK",
            style: GoogleFonts.outfit(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Keşfet'e gidip insanları beğenmeye başla.\nKarşılıklı beğeniler eşleşme oluşturur!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.5,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
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
                      border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                      boxShadow: [AppColors.neoShadowSmall],
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Colors.black, size: 28),
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
    return GestureDetector(
      onTap: () => _showProfileDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
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
                placeholder: (context, url) => Container(color: Colors.white),
              ),
              
              // Info Area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
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
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.black, size: 10),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.location.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
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
                                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
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
              
               // Action Buttons (Removed from separate Stack position, integrated into Info Area)

              // Like Icon (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
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



