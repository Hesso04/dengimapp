import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MessageType { text, image, audio, call }

/// Sohbet Listesi Modeli
@pragma('vm:entry-point')
class ChatConversation {
  final String id;
  final List<String> userIds;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, dynamic> unreadCounts; // { 'uid': count }
  
  // UI için yüklenecek alanlar (Service katmanında doldurulacak)
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final bool otherUserOnline;

  ChatConversation({
    required this.id,
    required this.userIds,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    this.otherUserId = '',
    this.otherUserName = '',
    this.otherUserAvatar = '',
    this.otherUserOnline = false,
  });

  // Firestore'dan veriyi alırken ham veriyi alıyoruz
  factory ChatConversation.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    final List<String> userIds = List<String>.from(data['userIds'] ?? []);

    final String otherId = userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
    
    final userProfiles = data['userProfiles'] as Map<String, dynamic>?;
    String otherName = '';
    String otherAvatar = '';
    
    if (userProfiles != null && userProfiles.containsKey(otherId)) {
      final profile = userProfiles[otherId] as Map<String, dynamic>;
      otherName = profile['name'] ?? '';
      otherAvatar = profile['avatar'] ?? '';
    }
    
    return ChatConversation(
      id: doc.id,
      userIds: userIds,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp? ?? Timestamp.now()).toDate(),
      unreadCounts: Map<String, dynamic>.from(data['unreadCounts'] ?? {}),
      otherUserId: otherId,
      otherUserName: otherName,
      otherUserAvatar: otherAvatar,
    );
  }

  // UI Uyumluluk Getter'ları
  bool get isGroup => false;
  String get userName => otherUserName;
  String get userAvatar => otherUserAvatar;
  bool get isOnline => otherUserOnline;
  bool get isTyping => false;

  int get unreadCount {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;
    return (unreadCounts[currentUser.uid] as int?) ?? 0;
  }

  // UI için bilgileri doldurulmuş yeni bir kopya döndür
  ChatConversation copyWithDetails({
    String? name,
    String? avatar,
    bool? isOnline,
  }) {
    return ChatConversation(
      id: id,
      userIds: userIds,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCounts: unreadCounts,
      otherUserId: otherUserId,
      otherUserName: name ?? otherUserName,
      otherUserAvatar: avatar ?? otherUserAvatar,
      otherUserOnline: isOnline ?? otherUserOnline,
    );
  }
}

/// Mesaj Modeli
@pragma('vm:entry-point')
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final MessageType type;
  final List<String> deletedFor;
  final Map<String, String> reactions; // userId -> emoji
  final String? replyToId;
  final String? replyToContent;
  final Map<String, dynamic>? storyReply;
  final String? senderName;
  final String? senderAvatar;

  // UI Yardımcısı
  bool isMe(String currentUserId) => senderId == currentUserId;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.type = MessageType.text,
    this.deletedFor = const [],
    this.reactions = const {},
    this.replyToId,
    this.replyToContent,
    this.storyReply,
    this.senderName,
    this.senderAvatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'type': type.name,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'storyReply': storyReply,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'],
      senderAvatar: data['senderAvatar'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      isRead: data['isRead'] ?? false,
      isDelivered: data['isDelivered'] ?? false,
      type: MessageType.values.firstWhere((e) => e.name == (data['type'] ?? 'text'), orElse: () => MessageType.text),
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
      reactions: data['reactions'] != null ? Map<String, String>.from(data['reactions']) : {},
      replyToId: data['replyToId'],
      replyToContent: data['replyToContent'],
      storyReply: data['storyReply'] != null ? Map<String, dynamic>.from(data['storyReply']) : null,
    );
  }
}
