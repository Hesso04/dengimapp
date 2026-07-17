import 'package:flutter/material.dart';
import 'dart:async'; // YENİ: Heartbeat Timer için
import '../models/space_model.dart';
import '../services/space_service.dart';
import '../../auth/models/user_profile.dart';
import '../../../core/services/agora_service.dart';
import '../../../core/utils/log_service.dart';

class SpaceProvider extends ChangeNotifier {
  final SpaceService _spaceService = SpaceService();
  final AgoraService _agoraService = AgoraService();
  
  List<SpaceRoom> _spaces = [];
  bool _isLoading = false;
  SpaceRoom? _currentSpace;
  Timer? _heartbeatTimer; // YENİ: Heartbeat Timer

  List<SpaceRoom> get spaces => _spaces;
  bool get isLoading => _isLoading;
  SpaceRoom? get currentSpace => _currentSpace;

  SpaceProvider() {
    _init();
  }

  void _init() {
    _spaceService.getLiveSpaces().listen((updatedSpaces) {
      _spaces = updatedSpaces;
      notifyListeners();
    });
  }

  Future<String?> createSpace(String title, String? description, UserProfile hostProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final roomId = await _spaceService.createSpace(
        title: title,
        description: description,
        hostProfile: hostProfile,
      );
      
      // Agora Kanalına Katıl (Host olarak)
      await _agoraService.joinChannel(
        channelId: roomId,
        uid: hostProfile.uid.hashCode.abs(),
        isHost: true,
      );

      _startHeartbeat(roomId); // YENİ: Heartbeat başlat

      _isLoading = false;
      notifyListeners();
      return roomId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinSpace(String spaceId, UserProfile userProfile) async {
    try {
      await _spaceService.joinSpace(spaceId, userProfile);
      
      // Agora Kanalına Katıl (Dinleyici olarak)
      await _agoraService.joinChannel(
        channelId: spaceId,
        uid: userProfile.uid.hashCode.abs(),
        isHost: false,
      );
    } catch (e) {
      LogService.e("Error joining space via provider", e);
    }
  }

  Future<void> leaveSpace(String spaceId, String userId) async {
    _stopHeartbeat(); // YENİ: Heartbeat durdur
    await _spaceService.leaveSpace(spaceId, userId);
    
    // Agora Kanalından Ayrıl
    await _agoraService.leaveChannel();
    if (_currentSpace?.id == spaceId) {
      _currentSpace = null;
    }
    notifyListeners();
  }

  Future<void> raiseHand(String spaceId, String userId) async {
    await _spaceService.raiseHand(spaceId, userId);
  }

  Future<void> lowerHand(String spaceId, String userId) async {
    await _spaceService.lowerHand(spaceId, userId);
  }

  // More methods as needed...
  
  void _startHeartbeat(String roomId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _spaceService.updateSpaceHeartbeat(roomId);
    });
    LogService.i("Space heartbeat started for room: $roomId");
  }

  void _stopHeartbeat() {
    if (_heartbeatTimer != null) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
      LogService.i("Space heartbeat stopped.");
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }
}
