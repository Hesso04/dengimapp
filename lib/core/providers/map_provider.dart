import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/auth/services/discovery_service.dart';
import '../../features/auth/services/profile_service.dart';
import '../../features/map/models/nearby_user.dart';
import '../utils/log_service.dart';
import '../widgets/location_disclosure_dialog.dart';

class MapProvider extends ChangeNotifier {
  final DiscoveryService _discoveryService = DiscoveryService();
  final ProfileService _profileService = ProfileService();
  
  List<NearbyUser> _nearbyUsers = [];
  List<NearbyUser> _allUsers = [];
  double _searchRadius = 1000.0; // Default max range
  LatLng _currentLocation = const LatLng(41.0082, 28.9784); // Default Istanbul
  bool _isLoading = false;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleMapTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  List<NearbyUser> get nearbyUsers => _nearbyUsers;
  LatLng get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  double get searchRadius => _searchRadius;

  void setSearchRadius(double radius) {
    _searchRadius = radius;
    _applyFilter();
  }

  void _applyFilter() {
    _nearbyUsers = _allUsers.where((u) => u.distance <= _searchRadius).toList();
    notifyListeners();
  }

  Future<void> initializeMap() async {
    _isLoading = true;
    notifyListeners();

    await determinePosition();
    await fetchNearbyUsers();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> determinePosition([BuildContext? context]) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (context != null && context.mounted) {
          final accepted = await LocationDisclosureDialog.show(context);
          if (!accepted) return;
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      
      // Update location in Firestore
      await _profileService.updateLocation(position.latitude, position.longitude);
      LogService.i("Location updated: ${_currentLocation.latitude}, ${_currentLocation.longitude}");
    } catch (e) {
      LogService.e("Error determining position", e);
    }
  }

  Future<void> fetchNearbyUsers() async {
    try {
      // Map should see more people than discovery cards
      final potentialMatches = await _discoveryService.getUsersToMatch(limit: 250);
      
      final List<NearbyUser> loadedUsers = [];
      final Distance distanceCalc = const Distance();

      for (var user in potentialMatches) {
        if (user.latitude == null || user.longitude == null) {
          LogService.w("User ${user.name} (${user.uid}) has no location data.");
          continue;
        }

        double distKm = distanceCalc.as(LengthUnit.Kilometer, _currentLocation, LatLng(user.latitude!, user.longitude!));

        loadedUsers.add(NearbyUser(
          id: user.uid,
          name: user.name,
          age: user.age,
          avatarUrl: user.imageUrl,
          latitude: user.latitude!,
          longitude: user.longitude!,
          distance: distKm,
          isOnline: user.isOnline,
        ));
      }



      _allUsers = loadedUsers;
      _applyFilter();
      LogService.i("Found ${_allUsers.length} total users, displaying ${_nearbyUsers.length} within ${_searchRadius.toInt()}km");
    } catch (e) {
      LogService.e("Error fetching nearby users for map", e);
      

    }
  }

}

