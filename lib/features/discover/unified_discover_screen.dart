import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import '../auth/services/profile_service.dart';
import '../../core/utils/log_service.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../core/providers/discovery_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/services/credit_service.dart';
import '../../core/constants/tier_limits.dart';
import '../payment/premium_offer_screen.dart';
import '../../core/widgets/premium_required_modal.dart';
import 'user_profile_detail_screen.dart';
import 'widgets/discover_header.dart';
import 'widgets/discover_empty_state.dart';
import 'widgets/match_overlay.dart';
import 'widgets/discover_user_card.dart';
import 'widgets/feature_action_modal.dart';
import '../../core/widgets/shimmer_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// UNIFIED DISCOVER SCREEN
/// Merged from: dengim (Flutter) + humble-main (React Native) + tinder-clone (Kotlin)
/// Features:
/// - Swipe cards from dengim
/// - Goal matching section from humble-main
/// - Community matching section from humble-main
/// - Similar interests section from humble-main
/// - Recommendations carousel from humble-main
class UnifiedDiscoverScreen extends StatefulWidget {
  const UnifiedDiscoverScreen({super.key});

  @override
  State<UnifiedDiscoverScreen> createState() => _UnifiedDiscoverScreenState();
}

class _UnifiedDiscoverScreenState extends State<UnifiedDiscoverScreen> with TickerProviderStateMixin {
  final Set<String> _dismissedUserIds = {};
  final Set<String> _animatingUserIds = {};
  final List<String> _historyOfSwipedUserIds = [];
  
  FilterSettings _filterSettings = FilterSettings();
  bool _isRefreshing = false;
  bool _showCardView = true; // Toggle between card and section view

  // Mock data for sections (in real app, these would come from API)
  final List<MockMatchUser> _goalMatches = [];
  final List<MockMatchUser> _communityMatches = [];
  final List<MockMatchUser> _interestMatches = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadMockData() {
    // Sample data matching humble-main structure
    _goalMatches.addAll([
      MockMatchUser(id: '1', name: 'Ayla', age: 25, imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400', bio: 'Serious relationship'),
      MockMatchUser(id: '2', name: 'Selin', age: 23, imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400', bio: 'Looking for long-term'),
      MockMatchUser(id: '3', name: 'Zeynep', age: 24, imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400', bio: 'Meaningful connection'),
    ]);
    
    _communityMatches.addAll([
      MockMatchUser(id: '4', name: 'Mert', age: 27, imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', bio: 'Travel lover'),
      MockMatchUser(id: '5', name: 'Can', age: 26, imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', bio: 'Music enthusiast'),
    ]);
    
    _interestMatches.addAll([
      MockMatchUser(id: '6', name: 'Ece', age: 22, imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400', bio: 'Coffee addict'),
      MockMatchUser(id: '7', name: 'Deniz', age: 28, imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400', bio: 'Fitness freak'),
    ]);
  }

  void _loadInitialData() {
    try {
      context.read<DiscoveryProvider>().loadDiscoveryUsers(
        gender: _filterSettings.gender,
        minAge: _filterSettings.ageRange.start.toInt(),
        maxAge: _filterSettings.ageRange.end.toInt(),
        interests: _filterSettings.interests.isNotEmpty ? _filterSettings.interests : null,
        maxDistance: _filterSettings.distance.toInt(),
        verifiedOnly: _filterSettings.verifiedOnly,
        hasPhotoOnly: _filterSettings.hasPhotoOnly,
        onlineOnly: _filterSettings.onlineOnly,
        relationshipGoal: _filterSettings.relationshipGoal,
      );
    } catch (e) {
      LogService.e("Failed to load initial discovery data", e);
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      HapticFeedback.mediumImpact();
      await context.read<DiscoveryProvider>().loadDiscoveryUsers(
        gender: _filterSettings.gender,
        minAge: _filterSettings.ageRange.start.toInt(),
        maxAge: _filterSettings.ageRange.end.toInt(),
        interests: _filterSettings.interests.isNotEmpty ? _filterSettings.interests : null,
        maxDistance: _filterSettings.distance.toInt(),
        verifiedOnly: _filterSettings.verifiedOnly,
        hasPhotoOnly: _filterSettings.hasPhotoOnly,
        onlineOnly: _filterSettings.onlineOnly,
        relationshipGoal: _filterSettings.relationshipGoal,
        forceRefresh: true,
      );
    } catch (e) {
      LogService.e("Refresh error", e);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _onLikeUser(UserProfile user) async => _performSwipeAction(user, 'like');
  Future<void> _onDislikeUser(UserProfile user) async => _performSwipeAction(user, 'dislike');

  Future<void> _onSuperLikeUser(UserProfile user) async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final userTier = currentUser?.subscriptionTier ?? 'free';

    if (TierLimits.canSuperLike(userTier)) {
      await _performSuperLike(user);
    } else {
      FeatureActionModal.show(
        context: context,
        featureType: DiscoverFeatureType.superLike,
        onActivated: () => _performSuperLike(user),
      );
    }
  }

  void _performUndo() {
    final userProvider = context.read<UserProvider>();
    final isPremium = userProvider.currentUser?.isPremium ?? false;

    if (isPremium) {
      _executeUndo();
    } else {
      FeatureActionModal.show(
        context: context,
        featureType: DiscoverFeatureType.rewind,
        onActivated: _executeUndo,
      );
    }
  }

  void _executeUndo() {
    if (_historyOfSwipedUserIds.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      final lastUid = _historyOfSwipedUserIds.removeLast();
      _dismissedUserIds.remove(lastUid);
      _animatingUserIds.remove(lastUid);
    });
  }

  void _onBoost() {
    final userProvider = context.read<UserProvider>();
    final isPremium = userProvider.currentUser?.isPremium ?? false;

    if (isPremium) {
      _executeBoost();
    } else {
      FeatureActionModal.show(
        context: context,
        featureType: DiscoverFeatureType.boost,
        onActivated: _executeBoost,
      );
    }
  }

  void _executeBoost() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 PROFİLİNİZ 30 DAKİKA BOYUNCA ZİRVEYE TAŞINDI!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _performSuperLike(UserProfile user) async => _performSwipeAction(user, 'super_like');

  Future<void> _performSwipeAction(UserProfile user, String action) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _animatingUserIds.add(user.uid);
      _historyOfSwipedUserIds.add(user.uid);
    });

    final discoveryProvider = context.read<DiscoveryProvider>();
    final userProvider = context.read<UserProvider>();
    final userTier = userProvider.currentUser?.subscriptionTier ?? 'free';

    try {
      final result = await discoveryProvider.swipeUser(user.uid, action, userTier: userTier);
      if (!result.success && action != 'dislike') {
        setState(() {
          _animatingUserIds.remove(user.uid);
          _historyOfSwipedUserIds.remove(user.uid);
        });
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
        return;
      }
      final isMatch = result.isMatch;
      if (isMatch) _showMatchAnimation(user);
    } catch (e) {
      LogService.e("Swipe action failed", e);
      setState(() {
        _animatingUserIds.remove(user.uid);
        _historyOfSwipedUserIds.remove(user.uid);
      });
    }
  }

  void _showMatchAnimation(UserProfile user) {
    HapticFeedback.heavyImpact();
    setState(() {
      _matchedUser = user;
      _showMatch = true;
    });
  }

  UserProfile? _matchedUser;
  bool _showMatch = false;

  void _onCardTap(UserProfile user) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileDetailScreen(user: user)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, child) {
          final visibleUsers = provider.users.where((u) => !_dismissedUserIds.contains(u.uid)).toList();
          final visibleUsersCount = visibleUsers.where((u) => !_animatingUserIds.contains(u.uid)).length;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshData,
                color: elementColor,
                backgroundColor: theme.colorScheme.surface,
                displacement: 40,
                strokeWidth: 3,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(provider, isDark)),
                    if (!(context.watch<UserProvider>().currentUser?.isPremium ?? false))
                      SliverToBoxAdapter(child: _buildNonPremiumBanner(context, isDark)),
                    
                    // VIEW TOGGLE
                    SliverToBoxAdapter(child: _buildViewToggle(isDark)),
                    
                    if (_showCardView) ...[
                      // CARD VIEW - Original dengim style
                      if (provider.isLoading && !_isRefreshing)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: ShimmerCard(height: 350),
                              ),
                              childCount: 2,
                            ),
                          ),
                        )
                      else if (visibleUsersCount == 0)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: DiscoverEmptyState(onShowFilters: _showFilters),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final user = visibleUsers[index];
                                final isAnimating = _animatingUserIds.contains(user.uid);
                                return AnimatedDismissibleCard(
                                  key: ValueKey('dismiss_${user.uid}'),
                                  isDismissed: isAnimating,
                                  onDismissFinished: () {
                                    setState(() {
                                      _animatingUserIds.remove(user.uid);
                                      _dismissedUserIds.add(user.uid);
                                    });
                                  },
                                  child: DiscoverUserCard(
                                    user: user,
                                    onTap: () => _onCardTap(user),
                                    onLike: () => _onLikeUser(user),
                                    onDislike: () => _onDislikeUser(user),
                                    onSuperLike: () => _onSuperLikeUser(user),
                                  ),
                                );
                              },
                              childCount: visibleUsers.length,
                            ),
                          ),
                        ),
                    ] else ...[
                      // SECTION VIEW - Merged from humble-main
                      SliverToBoxAdapter(child: _buildRecommendationsSection(isDark)),
                      SliverToBoxAdapter(child: _buildGoalMatchingSection(isDark)),
                      SliverToBoxAdapter(child: _buildCommunitySection(isDark)),
                      SliverToBoxAdapter(child: _buildSimilarInterestsSection(isDark)),
                    ],
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),

              if (_isRefreshing)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: isDark ? null : [AppColors.neoShadowSmall],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: elementColor)),
                          const SizedBox(width: 8),
                          Text('YENİLENİYOR...', style: GoogleFonts.outfit(color: elementColor, fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Action Buttons
              Positioned(
                bottom: 30,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_historyOfSwipedUserIds.isNotEmpty)
                      GestureDetector(
                        onTap: _performUndo,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08), width: 1.2),
                            boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.undo_rounded, color: AppColors.vibrantGold, size: 22),
                        ),
                      ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _onBoost,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showMatch && _matchedUser != null)
                MatchOverlay(matchedUser: _matchedUser!, onDismiss: _dismissMatch, onMessage: _dismissMatch),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(DiscoveryProvider provider, bool isDark) {
    return DiscoverHeader(
      filterSettings: _filterSettings,
      onFiltersApplied: (settings) => setState(() => _filterSettings = settings),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final activeBg = AppColors.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showCardView = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showCardView ? activeBg : bg,
                  borderRadius: BorderRadius.circular(AppColors.neoRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style_rounded, color: _showCardView ? Colors.white : AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text('Kartlar', style: GoogleFonts.outfit(color: _showCardView ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showCardView = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showCardView ? activeBg : bg,
                  borderRadius: BorderRadius.circular(AppColors.neoRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, color: !_showCardView ? Colors.white : AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text('Bölümler', style: GoogleFonts.outfit(color: !_showCardView ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(bool isDark) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF4B55), Color(0xFFFF8A8F)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.recommend_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('ÖNERİLER', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 1.0)),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _goalMatches.length,
            itemBuilder: (context, index) {
              final user = _goalMatches[index];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _buildHorizontalCard(user, isDark, cardBg, borderColor, textColor, size: 'large'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalMatchingSection(bool isDark) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;
    final sectionBg = isDark ? Colors.transparent : const Color(0xFFF8F8F8);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(AppColors.neoRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text('AYNI HEDEF', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 1.0)),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _goalMatches.length,
              itemBuilder: (context, index) {
                final user = _goalMatches[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _buildHorizontalCard(user, isDark, cardBg, borderColor, textColor, size: 'small', showBio: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection(bool isDark) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('ORTAK TOPLULUK', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 1.0)),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _communityMatches.length,
            itemBuilder: (context, index) {
              final user = _communityMatches[index];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _buildHorizontalCard(user, isDark, cardBg, borderColor, textColor, size: 'small', showBio: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarInterestsSection(bool isDark) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('BENZER İLGİ ALANLARI', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 1.0)),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _interestMatches.length,
            itemBuilder: (context, index) {
              final user = _interestMatches[index];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _buildHorizontalCard(user, isDark, cardBg, borderColor, textColor, size: 'small', showBio: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCard(MockMatchUser user, bool isDark, Color cardBg, Color borderColor, Color textColor, {String size = 'small', bool showBio = false}) {
    final isLarge = size == 'large';
    final width = isLarge ? 200.0 : 160.0;
    final height = isLarge ? 260.0 : 180.0;
    
    return GestureDetector(
      onTap: () {
        // Navigate to user profile
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: user.imageUrl,
                width: width,
                height: isLarge ? 180 : 130,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: isDark ? Colors.black26 : Colors.grey[200]),
                errorWidget: (context, url, error) => Container(color: isDark ? Colors.black26 : Colors.grey[200], child: const Icon(Icons.person, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user.name}, ${user.age}',
                          style: GoogleFonts.outfit(fontSize: isLarge ? 16 : 13, fontWeight: FontWeight.w800, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.favorite, color: AppColors.primary, size: 14),
                    ],
                  ),
                  if (showBio && user.bio != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonPremiumBanner(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A2BE2).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Gold & Platinum Üyelik",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Sınırsız beğeni ve Seni Beğenenleri gör!",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Yükselt", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showFilterBottomSheet(context, currentSettings: _filterSettings, onApply: (settings) {
      setState(() => _filterSettings = settings);
      context.read<DiscoveryProvider>().loadDiscoveryUsers(
        gender: settings.gender,
        minAge: settings.ageRange.start.toInt(),
        maxAge: settings.ageRange.end.toInt(),
        interests: settings.interests.isNotEmpty ? settings.interests : null,
        maxDistance: settings.distance.toInt(),
        verifiedOnly: settings.verifiedOnly,
        hasPhotoOnly: settings.hasPhotoOnly,
        onlineOnly: settings.onlineOnly,
        relationshipGoal: settings.relationshipGoal,
      );
    });
  }

  void _dismissMatch() => setState(() { _showMatch = false; _matchedUser = null; });

  Future<void> _performUndo() async {
    if (_historyOfSwipedUserIds.isEmpty) return;
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final tier = currentUser?.subscriptionTier ?? 'free';

    if (TierLimits.canUndo(tier)) {
      await _executeUndo();
    } else {
      final creditProvider = context.read<CreditProvider>();
      if (creditProvider.balance >= CreditService.costUndoSwipe) {
        final success = await creditProvider.spendUndo();
        if (success) await _executeUndo();
      } else {
        if (mounted) PremiumRequiredModal.show(context, featureName: 'Geri Alma', requiredTier: 'gold', creditCost: CreditService.costUndoSwipe);
      }
    }
  }

  Future<void> _executeUndo() async {
    final targetUid = _historyOfSwipedUserIds.removeLast();
    setState(() { _dismissedUserIds.remove(targetUid); _animatingUserIds.remove(targetUid); });
    try {
      await FirebaseFirestore.instance.collection('users').doc(context.read<UserProvider>().currentUser?.uid).collection('swipes').doc(targetUid).delete();
    } catch (e) { LogService.e("Undo failed", e); }
  }

  void _onBoost() {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    if (currentUser?.isBoosted ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profiliniz zaten öne çıkarılmış durumda.')));
      return;
    }
    if (TierLimits.canBoost(currentUser?.subscriptionTier ?? 'free')) {
      _showBoostActivationDialog();
    } else {
      final creditProvider = context.read<CreditProvider>();
      if (creditProvider.balance >= CreditService.costBoost) {
        creditProvider.spendBoost().then((success) {
          if (success && mounted) _showBoostActivationDialog();
        });
      } else {
        if (mounted) PremiumRequiredModal.show(context, featureName: 'Boost', requiredTier: 'gold', creditCost: CreditService.costBoost);
      }
    }
  }

  void _showBoostActivationDialog() {
    context.read<DiscoveryProvider>().activateBoost();
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚀 Profiliniz öne çıkarıldı!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }
}

/// Mock user class for section views
class MockMatchUser {
  final String id;
  final String name;
  final int age;
  final String imageUrl;
  final String? bio;

  MockMatchUser({required this.id, required this.name, required this.age, required this.imageUrl, this.bio});
}

/// Animated card widget from original discover screen
class AnimatedDismissibleCard extends StatefulWidget {
  final Widget child;
  final bool isDismissed;
  final VoidCallback onDismissFinished;

  const AnimatedDismissibleCard({super.key, required this.child, required this.isDismissed, required this.onDismissFinished});

  @override
  State<AnimatedDismissibleCard> createState() => _AnimatedDismissibleCardState();
}

class _AnimatedDismissibleCardState extends State<AnimatedDismissibleCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _heightFactor = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedDismissibleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDismissed && !oldWidget.isDismissed) {
      _controller.forward().then((_) => widget.onDismissFinished());
    } else if (!widget.isDismissed && oldWidget.isDismissed) {
      _controller.reverse();
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_heightFactor.value == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: _opacity.value,
          child: SizeTransition(sizeFactor: _heightFactor, axis: Axis.vertical, child: child),
        );
      },
      child: widget.child,
    );
  }
}
