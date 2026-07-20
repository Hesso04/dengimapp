import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../discover/discover_screen.dart';
import '../map/map_screen.dart';
import '../chats/chats_screen.dart';
import '../profile/profile_screen.dart';
import '../likes/likes_screen.dart';
import '../chats/screens/call_screen.dart';
import 'package:provider/provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/badge_provider.dart';
import '../../core/providers/system_config_provider.dart';
import '../../core/widgets/offline_banner.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  StreamSubscription? _callSubscription;
  bool _showingIncomingCall = false;

  @override
  void initState() {
    super.initState();
    NotificationService.updateToken();
    _listenForIncomingCalls();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _listenForIncomingCalls() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        final callDoc = snapshot.docs.first;
        final data = callDoc.data();
        final channelId = callDoc.id;
        final callerName = data['callerName'] ?? 'Bilinmeyen Kullanıcı';
        final callerAvatar = data['callerAvatar'] ?? '';

        if (!_showingIncomingCall) {
          _showingIncomingCall = true;
          _showIncomingCallDialog(
            context,
            channelId: channelId,
            callerName: callerName,
            callerAvatar: callerAvatar,
          );
        }
      }
    });
  }

  void _showIncomingCallDialog(
    BuildContext context, {
    required String channelId,
    required String callerName,
    required String callerAvatar,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Incoming Call',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _IncomingCallScreen(
          channelId: channelId,
          callerName: callerName,
          callerAvatar: callerAvatar,
          onAccept: () {
            setState(() {
              _showingIncomingCall = false;
            });
            FirebaseFirestore.instance.collection('calls').doc(channelId).update({
              'status': 'accepted',
            });
            Navigator.pop(context); // Close dialog

            // Navigate to CallScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  channelId: channelId,
                  userName: callerName,
                  userAvatar: callerAvatar,
                  isIncoming: true,
                ),
              ),
            );
          },
          onReject: () {
            setState(() {
              _showingIncomingCall = false;
            });
            FirebaseFirestore.instance.collection('calls').doc(channelId).update({
              'status': 'rejected',
            });
            Navigator.pop(context); // Close dialog
          },
        );
      },
    );
  }

  List<Widget> _getScreens(bool isMapEnabled) {
    return [
      const DiscoverScreen(),
      if (isMapEnabled) const MapScreen(),
      const LikesScreen(),
      const ChatsScreen(),
      const ProfileScreen(),
    ];
  }

  List<_NavItem> _getNavItems(bool isMapEnabled) {
    return [
      const _NavItem(
        icon: CupertinoIcons.compass,
        activeIcon: CupertinoIcons.compass_fill,
        label: 'Keşfet',
      ),
      if (isMapEnabled)
        const _NavItem(
          icon: CupertinoIcons.map,
          activeIcon: CupertinoIcons.map_fill,
          label: 'Harita',
        ),
      const _NavItem(
        icon: CupertinoIcons.heart,
        activeIcon: CupertinoIcons.heart_fill,
        label: 'Beğeniler',
      ),
      const _NavItem(
        icon: CupertinoIcons.chat_bubble_2,
        activeIcon: CupertinoIcons.chat_bubble_2_fill,
        label: 'Mesajlar',
      ),
      const _NavItem(
        icon: CupertinoIcons.person,
        activeIcon: CupertinoIcons.person_solid,
        label: 'Profil',
      ),
    ];
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });

    final configProvider = context.read<SystemConfigProvider>();
    final navItems = _getNavItems(configProvider.isMapEnabled);
    if (index < navItems.length) {
      final label = navItems[index].label;
      if (label == 'Beğeniler') {
        context.read<BadgeProvider>().markLikesAsViewed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final configProvider = context.watch<SystemConfigProvider>();
    final isMapEnabled = configProvider.isMapEnabled;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = _getScreens(isMapEnabled);
    final navItems = _getNavItems(isMapEnabled);

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true, // body'nin tab bar altına uzanmasını sağla
        body: Column(
          children: [
            if (!connectivityProvider.isConnected)
              const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(navItems, isDark),
      ),
    );
  }

  Widget _buildBottomNav(List<_NavItem> navItems, bool isDark) {
    final bgColor = isDark
        ? AppColors.scaffoldDark.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.90);
    final borderColor = isDark
        ? const Color(0xFF2A2A2E)
        : const Color(0xFFF0F0F0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => _buildNavItem(index, navItems, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, List<_NavItem> navItems, bool isDark) {
    final isSelected = _currentIndex == index;
    final item = navItems[index];
    final badgeProvider = context.watch<BadgeProvider>();

    int badgeCount = 0;
    if (item.label == 'Mesajlar') {
      badgeCount = badgeProvider.chatBadge;
    } else if (item.label == 'Beğeniler') {
      badgeCount = badgeProvider.likesBadge;
    }

    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon + Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey('${item.label}_$isSelected'),
                    size: 26,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.scaffoldDark : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            // Seçim Göstergesi — küçük nokta
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSelected ? 16 : 0,
              height: isSelected ? 3 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _IncomingCallScreen extends StatefulWidget {
  final String channelId;
  final String callerName;
  final String callerAvatar;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingCallScreen({
    required this.channelId,
    required this.callerName,
    required this.callerAvatar,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<_IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  StreamSubscription? _docSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Listen if caller cancels the call
    _docSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final data = snapshot.data();
      if (data != null && (data['status'] == 'ended' || data['status'] == 'rejected')) {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _docSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background image
          Positioned.fill(
            child: widget.callerAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.callerAvatar,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.black),
                    errorWidget: (context, url, error) => Container(color: Colors.black),
                  )
                : Container(color: Colors.black),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),

          // Ringing Interface
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 48),

                // Caller Info & Pulsing Avatar
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final progress = (_pulseController.value + index / 3) % 1.0;
                              return Container(
                                width: 120 + (100 * progress),
                                height: 120 + (100 * progress),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.15 * (1.0 - progress)),
                                ),
                              );
                            },
                          );
                        }),
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.surfaceDark,
                            backgroundImage: widget.callerAvatar.isNotEmpty
                                ? CachedNetworkImageProvider(widget.callerAvatar)
                                : null,
                            child: widget.callerAvatar.isEmpty
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.callerName,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dengim Sesli Arama...',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Actions (Decline / Accept)
                Padding(
                  padding: const EdgeInsets.only(bottom: 64, left: 48, right: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline Button
                      GestureDetector(
                        onTap: widget.onReject,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent,
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Reddet',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 48),

                      // Accept Button
                      GestureDetector(
                        onTap: widget.onAccept,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green,
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.call_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Cevapla',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
