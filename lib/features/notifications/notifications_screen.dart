import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../chats/screens/chat_detail_screen.dart';
import '../likes/likes_screen.dart';
import '../discover/user_profile_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  
  @override
  void initState() {
    super.initState();
    // Yeni kullanıcılar için global duyuruları kontrol et ve ekle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncGlobalAnnouncements();
    });
  }

  /// Yeni kayıt olan kullanıcılar için global announcements koleksiyonundan
  /// henüz almadıkları duyuruları notifications alt koleksiyonuna ekle
  Future<void> _syncGlobalAnnouncements() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      
      // 1. Aktif duyuruları getir
      final announcementsSnapshot = await firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (announcementsSnapshot.docs.isEmpty) return;

      // 2. Kullanıcının mevcut duyuru notification'larını kontrol et
      final existingNotifs = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'announcement')
          .get();

      final existingAnnouncementIds = existingNotifs.docs
          .map((doc) => doc.data()['announcementId'] as String?)
          .where((id) => id != null)
          .toSet();

      // 3. Eksik duyuruları ekle
      final batch = firestore.batch();
      int addedCount = 0;

      for (final announcementDoc in announcementsSnapshot.docs) {
        if (!existingAnnouncementIds.contains(announcementDoc.id)) {
          final data = announcementDoc.data();
          final notifRef = firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('notifications')
              .doc(); // auto-generated ID

          batch.set(notifRef, {
            'type': 'announcement',
            'title': data['title'] ?? 'Duyuru',
            'body': data['body'] ?? '',
            'imageUrl': data['imageUrl'],
            'announcementId': announcementDoc.id,
            'senderId': 'admin',
            'isRead': false,
            'createdAt': data['createdAt'] ?? Timestamp.now(),
            'data': {
              'segment': data['segment'] ?? 'all',
            },
          });
          addedCount++;
        }
      }

      if (addedCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Announcement sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserProvider>().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.5);
    final bgColor = isDark ? AppColors.scaffoldDark : Colors.white;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            "Giriş yapmalısınız",
            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "BİLDİRİMLER",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
              ),
              child: Icon(Icons.arrow_back, color: textColor, size: 18),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            onSelected: (value) {
              if (value == 'mark_all') {
                _markAllAsRead(currentUser.uid);
              } else if (value == 'clear_all') {
                _clearAllNotifications(currentUser.uid);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: textColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'TÜMÜNÜ OKUNDU İŞARETLE',
                      style: GoogleFonts.outfit(color: textColor, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'TÜMÜNÜ SİL',
                      style: GoogleFonts.outfit(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.0),
                      boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
                    ),
                    child: Icon(Icons.notifications_off_outlined, size: 48, color: textColor),
                  ),
                  const SizedBox(height: 24),
                  Text("HENÜZ BİLDİRİM YOK", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    "EŞLEŞMELER, BEĞENİLER VE DUYURULAR\nBURADA GÖRÜNECEK.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w800, height: 1.5),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? data['read'] ?? false;
              final timestamp = (data['createdAt'] ?? data['timestamp']) as Timestamp?;
              final type = data['type'] as String?;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  doc.reference.delete();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black,
                      width: isRead ? AppColors.neoBorderWidthPixels : AppColors.neoBorderWidthSmallPixels,
                    ),
                    boxShadow: (isRead || isDark) ? [] : [AppColors.neoShadowSmall],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        doc.reference.update({'isRead': true});
                      }
                      _handleNotificationTap(context, data);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getIconBgColor(type),
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 1.0),
                          ),
                          child: Center(child: _getIconForType(type, isDark)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['title'] ?? 'BİLDİRİM').toString().toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: textColor,
                                  fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['body'] ?? '',
                                style: GoogleFonts.outfit(
                                  color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (timestamp != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      _formatTime(timestamp.toDate()),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.black.withValues(alpha: 0.4),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (type == 'announcement') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: borderColor, width: 1.0),
                                        ),
                                        child: Text(
                                          '📢 DUYURU',
                                          style: GoogleFonts.outfit(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  Color _getIconBgColor(String? type) {
    switch (type) {
      case 'announcement': return AppColors.primary;
      case 'match': return AppColors.primary;
      case 'like': return const Color(0xFFFF6B8A);
      case 'message': return const Color(0xFF22C55E);
      case 'story_like': return const Color(0xFFEF4444);
      default: return Colors.black.withValues(alpha: 0.08);
    }
  }

  Icon _getIconForType(String? type, bool isDark) {
    double size = 22;
    switch (type) {
      case 'announcement': return Icon(Icons.campaign_rounded, color: isDark ? Colors.white : Colors.black, size: size);
      case 'match': return Icon(Icons.favorite, color: isDark ? Colors.white : Colors.black, size: size);
      case 'like': return Icon(Icons.thumb_up, color: Colors.white, size: size);
      case 'story_like': return Icon(Icons.favorite_border, color: Colors.white, size: size);
      case 'message': return Icon(Icons.message, color: Colors.white, size: size);
      default: return Icon(Icons.notifications, color: isDark ? Colors.white : Colors.black, size: size);
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'];
    final payload = data['data'] as Map<String, dynamic>? ?? {};
    final senderId = data['senderId'] ?? data['fromUid'];

    switch (type) {
      case 'announcement':
        // Duyuru bildirimine tıklandığında özel bir şey yapmaya gerek yok
        // İçerik zaten görünüyor
        break;

      case 'message':
      case 'match':
      case 'story_reply':
        if (payload['chatId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: payload['chatId'],
                otherUserId: senderId ?? '',
                otherUserName: payload['senderName'] ?? 'Kullanıcı',
                otherUserAvatar: payload['senderAvatar'] ?? '',
              ),
            ),
          );
        } else if (senderId != null && senderId != 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileDetailScreen(userId: senderId)),
          );
        }
        break;

      case 'like':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LikesScreen()),
        );
        break;

      case 'story_like':
        if (senderId != null && senderId != 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileDetailScreen(userId: senderId)),
          );
        }
        break;

      default:
        if (senderId != null && senderId != 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileDetailScreen(userId: senderId)),
          );
        }
    }
  }

  void _markAllAsRead(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${snapshot.docs.length} BİLDİRİM OKUNDU OLARAK İŞARETLENDİ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }

  void _clearAllNotifications(String uid) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.scaffoldDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
        ),
        title: Text('TÜM BİLDİRİMLERİ SİL', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w900)),
        content: Text(
          'TÜM BİLDİRİMLER SİLİNECEK. BU İŞLEM GERİ ALINAMAZ.', 
          style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL', style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('SİL', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Clear all notifications error: $e');
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    return '${date.day}/${date.month}/${date.year}';
  }
}
