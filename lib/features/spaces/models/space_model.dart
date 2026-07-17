import 'package:cloud_firestore/cloud_firestore.dart';

/// Katılımcı Rolü
enum SpaceRole {
  host,      // Oda sahibi
  speaker,   // Konuşmacı
  listener,  // Dinleyici
}

/// Oda Durumu
enum SpaceStatus {
  live,      // Canlı yayında
  scheduled, // Planlanmış
  ended,     // Sona erdi
}

/// Oda Kategorisi
enum SpaceCategory {
  chat,      // Genel sohbet
  music,     // Müzik odası
  dating,    // Tanışma odası
  advice,    // Tavsiye odası
  fun,       // Eğlence
}

/// Sesli Sohbet Odası Modeli
class SpaceRoom {
  final String id;
  final String title;
  final String? description;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final SpaceStatus status;
  final SpaceCategory category;
  final List<SpaceParticipant> speakers;
  final List<String> listenerIds;
  final List<String> raisedHands; // El kaldıranlar
  final int listenerCount;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt; // YENİ: Oda heartbeat takibi için
  final DateTime? scheduledAt;
  final String? agoraToken; // Agora RTC token

  const SpaceRoom({
    required this.id,
    required this.title,
    this.description,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    this.status = SpaceStatus.live,
    this.category = SpaceCategory.chat,
    this.speakers = const [],
    this.listenerIds = const [],
    this.raisedHands = const [],
    this.listenerCount = 0,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt, // YENİ
    this.scheduledAt,
    this.agoraToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'status': status.name,
      'category': category.name,
      'speakers': speakers.map((s) => s.toMap()).toList(),
      'listenerIds': listenerIds,
      'raisedHands': raisedHands,
      'listenerCount': listenerCount,
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt), // YENİ
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'agoraToken': agoraToken,
    };
  }

  factory SpaceRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpaceRoom(
      id: doc.id,
      title: data['title'] ?? 'İsimsiz Oda',
      description: data['description'],
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? 'Anonim',
      hostAvatar: data['hostAvatar'] ?? '',
      status: SpaceStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'live'),
        orElse: () => SpaceStatus.live,
      ),
      category: SpaceCategory.values.firstWhere(
        (e) => e.name == (data['category'] ?? 'chat'),
        orElse: () => SpaceCategory.chat,
      ),
      speakers: (data['speakers'] as List<dynamic>?)
              ?.map((s) => SpaceParticipant.fromMap(s))
              .toList() ??
          [],
      listenerIds: List<String>.from(data['listenerIds'] ?? []),
      raisedHands: List<String>.from(data['raisedHands'] ?? []),
      listenerCount: data['listenerCount'] ?? 0,
      isPrivate: data['isPrivate'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(), // YENİ
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      agoraToken: data['agoraToken'],
    );
  }

  SpaceRoom copyWith({
    String? title,
    String? description,
    SpaceStatus? status,
    List<SpaceParticipant>? speakers,
    List<String>? listenerIds,
    List<String>? raisedHands,
    int? listenerCount,
  }) {
    return SpaceRoom(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId,
      hostName: hostName,
      hostAvatar: hostAvatar,
      status: status ?? this.status,
      category: category,
      speakers: speakers ?? this.speakers,
      listenerIds: listenerIds ?? this.listenerIds,
      raisedHands: raisedHands ?? this.raisedHands,
      listenerCount: listenerCount ?? this.listenerCount,
      isPrivate: isPrivate,
      createdAt: createdAt,
      updatedAt: DateTime.now(), // Heartbeat anında güncellenir
      scheduledAt: scheduledAt,
      agoraToken: agoraToken,
    );
  }

  /// Toplam katılımcı sayısı
  int get totalParticipants => speakers.length + listenerCount;
}

/// Oda Katılımcısı
class SpaceParticipant {
  final int agoraUid;
  final String userId;
  final String name;
  final String? avatarUrl;
  final SpaceRole role;
  final bool isMuted;
  final bool isSpeaking; // Şu an konuşuyor mu

  const SpaceParticipant({
    required this.agoraUid,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.isMuted = true,
    this.isSpeaking = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'agoraUid': agoraUid,
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'isMuted': isMuted,
      'isSpeaking': isSpeaking,
    };
  }

  factory SpaceParticipant.fromMap(Map<String, dynamic> data) {
    return SpaceParticipant(
      agoraUid: data['agoraUid']?.toInt() ?? 0,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Anonim',
      avatarUrl: data['avatarUrl'],
      role: SpaceRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'listener'),
        orElse: () => SpaceRole.listener,
      ),
      isMuted: data['isMuted'] ?? true,
      isSpeaking: data['isSpeaking'] ?? false,
    );
  }
}
