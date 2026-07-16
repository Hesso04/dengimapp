import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final configProvider = context.watch<SystemConfigProvider>();
    final isMapEnabled = configProvider.isMapEnabled;
    
    final screens = _getScreens(isMapEnabled);
    final navItems = _getNavItems(isMapEnabled);

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
      bottomNavigationBar: _buildBottomNav(navItems),
    );
  }

  Widget _buildBottomNav(List<_NavItem> navItems) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.colorScheme.surface,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      padding: EdgeInsets.only(
        left: 12, 
        right: 12, 
        top: 12, 
        bottom: MediaQuery.of(context).padding.bottom + 12
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          navItems.length,
          (index) => _buildNavItem(index, navItems),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, List<_NavItem> navItems) {
    final isSelected = _currentIndex == index;
    final item = navItems[index];
    final badgeProvider = context.watch<BadgeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final unselectedColor = theme.bottomNavigationBarTheme.unselectedItemColor ?? AppColors.textSecondary;
    
    int badgeCount = 0;
    if (item.label == 'Mesajlar') { 
      badgeCount = badgeProvider.chatBadge;
    } else if (item.label == 'Beğeniler') {
      badgeCount = badgeProvider.likesBadge;
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: borderColor, width: 1.0) 
              : Border.all(color: Colors.transparent, width: AppColors.neoBorderWidth),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 26,
                  color: isSelected ? Colors.white : unselectedColor,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1B1B1D) : Colors.white, width: 1.0),
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
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ]
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
