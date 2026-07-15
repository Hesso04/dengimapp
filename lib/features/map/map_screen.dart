import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import 'models/nearby_user.dart';
import 'widgets/nearby_users_list.dart';

import 'package:provider/provider.dart';
import '../../core/providers/map_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/discover/user_profile_detail_screen.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final double _initialZoom = 13.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initializeMap().then((_) {
        // Move camera to current location once initialized
        if (!mounted) return;
        final loc = context.read<MapProvider>().currentLocation;
        _mapController.move(loc, _initialZoom);
      });
    });
  }

  void _onUserTap(NearbyUser user) {
    _animatedMapMove(LatLng(user.latitude, user.longitude), 16);
    HapticFeedback.mediumImpact();
    _showUserProfile(user);
  }


  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });

    controller.forward();
  }

  void _centerOnLocation() {
    HapticFeedback.mediumImpact();
    final loc = context.read<MapProvider>().currentLocation;
    _animatedMapMove(loc, 15);
  }

  void _showUserProfile(NearbyUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(width: 24),
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    boxShadow: [AppColors.neoShadowSmall],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.black12),
                      errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.black, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name}, ${user.age}'.toUpperCase(), 
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 10, height: 10, 
                            decoration: BoxDecoration(
                              color: user.isOnline ? AppColors.green : AppColors.red, 
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1.5),
                            )
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${user.distance.toStringAsFixed(1)} KM UZAKTA'.toUpperCase(), 
                            style: GoogleFonts.outfit(
                              fontSize: 12, 
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withValues(alpha: 0.5),
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 32),
            
            // Butonlar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserProfileDetailScreen(userId: user.id)),
                        );
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                          boxShadow: [AppColors.neoShadowSmall],
                        ),
                        child: Center(
                          child: Text(
                            'PROFİLE GİT', 
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                        boxShadow: [AppColors.neoShadowSmall],
                      ),
                      child: const Icon(Icons.close, color: Colors.black, size: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Koyu Harita Katmanı
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: provider.currentLocation,
                  initialZoom: _initialZoom,
                  minZoom: 3,
                  maxZoom: 18,
                  backgroundColor: AppColors.scaffold,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dengim.app',
                    tileBuilder: (context, tileWidget, tile) {
                      if (!provider.isDarkMode) return tileWidget;
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          -1.0, 0.0, 0.0, 0.0, 255.0,
                          0.0, -1.0, 0.0, 0.0, 255.0,
                          0.0, 0.0, -1.0, 0.0, 255.0,
                          0.0, 0.0, 0.0, 1.0, 0.0,
                        ]),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(const Color(0xFF0F172A).withValues(alpha: 0.6), BlendMode.multiply),
                          child: tileWidget,
                        ),
                      );
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      // Benim Konumum
                      Marker(
                        point: provider.currentLocation,
                        width: 80, height: 80,
                        child: _buildMyLocationMarker(),
                      ),
                      ...provider.nearbyUsers.map((user) => Marker(
                        point: LatLng(user.latitude, user.longitude),
                        width: 60, height: 75,
                        child: GestureDetector(
                          onTap: () => _onUserTap(user),
                          child: _buildUserMarker(user),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
              
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(provider.nearbyUsers.length)),
              Positioned(right: 20, bottom: 350, child: _buildZoomControls()),
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.12,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                            
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('YAKININDAKİLER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.0)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary, 
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                                    boxShadow: [AppColors.neoShadowSmall],
                                  ),
                                  child: Text('${provider.nearbyUsers.length} KİŞİ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Slider
                            Row(
                              children: [
                                Text('MESAFE: ${provider.searchRadius.toInt()} KM'.toUpperCase(), style: GoogleFonts.outfit(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.black,
                                      inactiveTrackColor: Colors.black12,
                                      thumbColor: AppColors.primary,
                                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
                                    ),
                                    child: Slider(
                                      value: provider.searchRadius,
                                      min: 10,
                                      max: 1000,
                                      onChanged: (val) {
                                        provider.setSearchRadius(val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Users List
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: provider.nearbyUsers.length,
                                itemBuilder: (context, index) {
                                   return NearbyUserAvatar(
                                     user: provider.nearbyUsers[index], 
                                     onTap: () => _onUserTap(provider.nearbyUsers[index])
                                   );
                                },
                              ),
                            ),
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildMyLocationMarker() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
      ),
    );
  }

  Widget _buildUserMarker(NearbyUser user) {
     return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [AppColors.neoShadowSmall],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.avatarUrl, 
              fit: BoxFit.cover, 
              placeholder: (_, __) => Container(color: Colors.black12),
              errorWidget: (_,__,___) => const Icon(Icons.person, color: Colors.black45)
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [AppColors.neoShadowSmall],
          ),
          child: Text(
            user.name.toUpperCase(), 
            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(int activeCount) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HARİTA',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activeCount > 0 
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black,
                  width: AppColors.neoBorderWidthSmall,
                ),
                boxShadow: activeCount > 0 ? [AppColors.neoShadowSmall] : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, 
                    height: 8, 
                    decoration: BoxDecoration(
                      color: activeCount > 0 ? AppColors.green : AppColors.red, 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    )
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeCount > 0 
                        ? '$activeCount AKTİF'
                        : 'KEŞFET',
                    style: GoogleFonts.outfit(
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      color: activeCount > 0 ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        Consumer<MapProvider>(
          builder: (context, provider, _) => _buildControlButton(
            icon: provider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, 
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleMapTheme();
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildControlButton(icon: Icons.gps_fixed_rounded, onTap: _centerOnLocation),
        const SizedBox(height: 12),
        _buildControlButton(icon: Icons.add_rounded, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
        const SizedBox(height: 12),
        _buildControlButton(icon: Icons.remove_rounded, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
      ],
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }
}

