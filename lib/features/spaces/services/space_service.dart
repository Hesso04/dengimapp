import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/space_model.dart';
import '../../auth/models/user_profile.dart';
import '../../../core/utils/log_service.dart';

class SpaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  /// Aktif odaları getir (Realtime)
  Stream<List<SpaceRoom>> getLiveSpaces() {
    return _firestore
        .collection('spaces')
        .where('status', isEqualTo: SpaceStatus.live.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpaceRoom.fromFirestore(doc)).toList();
    });
  }

  /// Oda oluşturma yetkisi kontrolü
  /// Sadece VIP Premium, Admin veya Moderatörler oda açabilir.
  bool canCreateSpace(UserProfile? profile) {
    if (profile == null) return false;
    
    return profile.isPremium || 
           profile.role == UserRole.admin.name || 
           profile.role == UserRole.moderator.name;
  }

  /// Yeni bir sesli oda oluştur
  Future<String> createSpace({
    required String title,
    String? description,
    SpaceCategory category = SpaceCategory.chat,
    required UserProfile hostProfile,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception("Oturum açılmamış");

    if (!canCreateSpace(hostProfile)) {
      throw Exception("Sadece VIP Premium üyeler oda oluşturabilir.");
    }

    try {
      final docRef = _firestore.collection('spaces').doc();
      
      final hostAsSpeaker = SpaceParticipant(
        agoraUid: hostProfile.uid.hashCode.abs(), 
        userId: hostProfile.uid,
        name: hostProfile.name,
        avatarUrl: hostProfile.imageUrl,
        role: SpaceRole.host,
        isMuted: false,
        isSpeaking: false,
      );

      final space = SpaceRoom(
        id: docRef.id,
        title: title,
        description: description,
        hostId: hostProfile.uid,
        hostName: hostProfile.name,
        hostAvatar: hostProfile.imageUrl,
        status: SpaceStatus.live,
        category: category,
        speakers: [hostAsSpeaker],
        listenerIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), // YENİ: Heartbeat
      );

      await docRef.set(space.toMap());
      LogService.i("Space created: ${docRef.id} by ${hostProfile.name}");
      return docRef.id;
    } catch (e) {
      LogService.e("Error creating space", e);
      rethrow;
    }
  }

  /// Odaya katıl
  Future<void> joinSpace(String spaceId, UserProfile userProfile) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'listenerIds': FieldValue.arrayUnion([userProfile.uid]),
        'listenerCount': FieldValue.increment(1),
      });
    } catch (e) {
      LogService.e("Error joining space", e);
    }
  }

  /// Odadan ayrıl
  Future<void> leaveSpace(String spaceId, String userId) async {
    try {
      final doc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final speakers = (data['speakers'] as List<dynamic>?) ?? [];
      final isSpeaker = speakers.any((s) => s['userId'] == userId);

      if (isSpeaker) {
        // Eğer konuşmacı ise speakers listesinden çıkar
        final updatedSpeakers = speakers.where((s) => s['userId'] != userId).toList();
        
        // Eğer ayrılan host ise odayı sonlandır
        if (data['hostId'] == userId) {
          await endSpace(spaceId);
        } else {
          await _firestore.collection('spaces').doc(spaceId).update({
            'speakers': updatedSpeakers,
          });
        }
      } else {
        // Sadece dinleyici ise listenerIds'den çıkar
        await _firestore.collection('spaces').doc(spaceId).update({
          'listenerIds': FieldValue.arrayRemove([userId]),
          'listenerCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      LogService.e("Error leaving space", e);
    }
  }

  /// Odayı sonlandır
  Future<void> endSpace(String spaceId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'status': SpaceStatus.ended.name,
        'endedAt': FieldValue.serverTimestamp(),
      });
      LogService.i("Space ended: $spaceId");
    } catch (e) {
      LogService.e("Error ending space", e);
    }
  }

  /// El kaldır (Konuşma isteği)
  Future<void> raiseHand(String spaceId, String userId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'raisedHands': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      LogService.e("Error raising hand", e);
    }
  }

  /// Eli indir
  Future<void> lowerHand(String spaceId, String userId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'raisedHands': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      LogService.e("Error lowering hand", e);
    }
  }

  /// Konuşmacı yap (Host tarafından onay)
  Future<void> inviteToSpeak(String spaceId, SpaceParticipant participant) async {
    try {
      // Önce raisedHands listesinden çıkar
      await _firestore.collection('spaces').doc(spaceId).update({
        'raisedHands': FieldValue.arrayRemove([participant.userId]),
        'listenerIds': FieldValue.arrayRemove([participant.userId]),
        'listenerCount': FieldValue.increment(-1),
        'speakers': FieldValue.arrayUnion([participant.toMap()]),
      });
    } catch (e) {
      LogService.e("Error inviting to speak", e);
    }
  }

  /// Dinleyiciye geri al
  Future<void> moveToListener(String spaceId, String userId) async {
    try {
      final doc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final speakers = (data['speakers'] as List<dynamic>?) ?? [];
      final speakerData = speakers.firstWhere((s) => s['userId'] == userId, orElse: () => null);

      if (speakerData != null) {
        await _firestore.collection('spaces').doc(spaceId).update({
          'speakers': FieldValue.arrayRemove([speakerData]),
          'listenerIds': FieldValue.arrayUnion([userId]),
          'listenerCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      LogService.e("Error moving to listener", e);
    }
  }

  /// Odanın heartbeat durumunu (updatedAt) güncelle
  Future<void> updateSpaceHeartbeat(String spaceId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LogService.e("Failed to update space heartbeat: $e");
    }
  }
}
