import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/log_service.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  // Agora App ID
  static const String appId = "0b227b12c2e54a2e9f5f20b30653c198";

  RtcEngine? _engine;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Sadece mikrofon iznini iste (Sesli arama için)
      await Permission.microphone.request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _isInitialized = true;
      LogService.i("Agora SDK initialized successfully.");
    } catch (e) {
      LogService.e("Agora SDK initialization failed", e);
    }
  }

  // Kanala katıl (Sesli arama desteği ile)
  Future<void> joinChannel({
    required String channelId,
    required int uid,
    bool isVideo = false,
    bool isHost = true,
  }) async {
    if (_engine == null) await init();

    // İletişim kanal ayarları
    await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine!.enableAudio();

    // Video devre dışı bırakılıyor (Sesli Arama)
    await _engine!.disableVideo();

    // Cloud Function üzerinden güvenli Agora Token'ı alıyoruz
    String token = "";
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final results = await callable.call(<String, dynamic>{
        'channelName': channelId,
        'uid': uid,
        'role': 'publisher',
      });
      token = results.data['token'] ?? "";
    } catch (e) {
      LogService.e("Failed to generate Agora token via Cloud Function: $e");
      rethrow;
    }

    await _engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        publishCameraTrack: false,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
    
    final displayToken = token.length > 10 ? token.substring(0, 10) : token;
    LogService.i("Joined Agora Channel: $channelId with token: $displayToken...");
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      LogService.i("Left Agora Channel.");
    }
  }

  RtcEngine get engine {
    if (_engine == null) throw Exception("Agora Engine not initialized");
    return _engine!;
  }
}
