import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import '../auth/services/profile_service.dart';
import '../discover/user_profile_detail_screen.dart';
import '../../core/providers/user_provider.dart';

class FollowsListScreen extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final String userName;

  const FollowsListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.userName,
  });

  @override
  State<FollowsListScreen> createState() => _FollowsListScreenState();
}

class _FollowsListScreenState extends State<FollowsListScreen> {
  final ProfileService _profileService = ProfileService();
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get the target user's document
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (!userDoc.exists) {
        setState(() {
          _allUsers = [];
          _filteredUsers = [];
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data();
      final List<dynamic> listIds = (widget.type == 'followers')
          ? (data?['followers'] ?? [])
          : (data?['following'] ?? []);

      if (listIds.isEmpty) {
        setState(() {
          _allUsers = [];
          _filteredUsers = [];
          _isLoading = false;
        });
        return;
      }

      // Convert dynamic list to String list
      final uids = listIds.map((id) => id.toString()).toList();

      // 2. Fetch profiles in chunks of 10 (Firestore whereIn limit is 30/10 depending on use case, let's do 10 to be safe)
      final List<UserProfile> users = [];
      for (var i = 0; i < uids.length; i += 10) {
        final chunk = uids.skip(i).take(10).toList();
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        users.addAll(usersSnapshot.docs.map((doc) => UserProfile.fromMap(doc.data())));
      }

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _unfollowUser(UserProfile targetUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
        title: Text(
          'TAKİPTEN ÇIK?',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${targetUser.name.toUpperCase()} KİŞİSİNİ TAKİPTEN ÇIKMAK İSTEDİĞİNİZE EMİN MİSİNİZ?',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İPTAL',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w900),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('EVET, ÇIK', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _profileService.unfollowUser(targetUser.uid);
        if (mounted) {
          setState(() {
            _allUsers.removeWhere((u) => u.uid == targetUser.uid);
            _onSearchChanged(_searchQuery);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.black,
              content: Text('${targetUser.name.toUpperCase()} TAKİPTEN ÇIKILDI', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Takipten çıkılamadı.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.type == 'followers' ? 'TAKİPÇİLER' : 'TAKİP EDİLENLER';
    final isOwnProfile = widget.userId == context.watch<UserProvider>().currentUser?.uid;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          if (_allUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "İSME GÖRE ARA...",
                    hintStyle: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.black54),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: _buildBody(isOwnProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isOwnProfile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black));
    }

    if (_allUsers.isEmpty) {
      return _buildEmptyState(isFollowers: widget.type == 'followers');
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Text(
          "KULLANICI BULUNAMADI",
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadList,
      color: isDark ? Colors.white : Colors.black,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserTile(user, isOwnProfile);
        },
      ),
    );
  }

  Widget _buildUserTile(UserProfile user, bool isOwnProfile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoUrl = (user.photoUrls?.isNotEmpty == true)
        ? user.photoUrls!.first
        : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=500';
        
    final locationText = (user.city != null && user.city!.isNotEmpty)
        ? "${user.city}, ${user.district ?? ''}"
        : user.country;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
        boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _navigateToProfile(user),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.scaffold),
                  errorWidget: (_, __, ___) => Icon(Icons.person, color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(user),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name}, ${user.age}'.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action Button
          if (isOwnProfile && widget.type == 'following')
            GestureDetector(
              onTap: () => _unfollowUser(user),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
                ),
                child: Text(
                  'ÇIK',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white38 : Colors.black45, size: 16),
              onPressed: () => _navigateToProfile(user),
            ),
        ],
      ),
    );
  }

  void _navigateToProfile(UserProfile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileDetailScreen(user: user),
      ),
    ).then((_) => _loadList()); // Refresh on back
  }

  Widget _buildEmptyState({required bool isFollowers}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = isFollowers ? "HENÜZ TAKİPÇİN YOK" : "KİMSEYİ TAKİP ETMİYORSUN";
    final desc = isFollowers
        ? "Profilini doldurarak ve insanlarla etkileşime girerek takipçi kazanabilirsin!"
        : "Keşfet sayfasındaki insanları inceleyip takip etmeye başlayabilirsin!";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
              ),
              child: Icon(
                isFollowers ? Icons.people_outline : Icons.person_add_alt_1_outlined,
                size: 48,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
