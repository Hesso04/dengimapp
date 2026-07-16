import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../discover/discover_screen.dart';
import '../map/map_screen.dart';
import '../chats/chats_screen.dart';
import '../profile/profile_screen.dart';
import '../likes/likes_screen.dart';
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

  @override
  void initState() {
    super.initState();
    NotificationService.updateToken();
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
