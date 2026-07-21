import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/log_service.dart';
import '../../features/auth/services/profile_service.dart';
import '../../features/chats/screens/chat_detail_screen.dart';
import '../../main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription? _firestoreSubscription;

  Future<void> initialize() async {
    // 1. Android/iOS Local Notification Setup
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_stat_name');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationClick(response.payload);
        },
      );

      // Create Android Notification Channel for High Priority Messages
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'dengim_messages_channel',
        'Mesaj ve Sohbet Bildirimleri',
        description: 'Anlık mesajlaşma ve bildirim ulaşımları için yüksek öncelikli kanal',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final FlutterLocalNotificationsPlugin localPlugin = _localNotifications;
      await localPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 2. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      LogService.i('User granted FCM permission');
      
      // 3. Get and Save FCM Token
      try {
        String? token = await _fcm.getToken();
        if (token != null) {
          await ProfileService().updateFcmToken(token);
        }
      } catch (e) {
        LogService.w("FCM Token fetch warning: $e");
      }
      
      _fcm.onTokenRefresh.listen((token) {
        ProfileService().updateFcmToken(token);
      });

      // 4. Foreground FCM Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        LogService.i('FCM Received: ${message.notification?.title}');
        
        final data = message.data;
        final chatId = data['chatId'];
        final messageId = data['messageId'];
        
        if (chatId != null && messageId != null) {
          _firestore
              .collection('conversations')
              .doc(chatId)
              .collection('messages')
              .doc(messageId)
              .update({'isDelivered': true}).catchError((e) {
            LogService.e("Failed to update message delivered status from FCM: $e");
          });
        }

        if (!kIsWeb) {
          _showLocalNotification(
            id: message.hashCode,
            title: message.notification?.title ?? "Yeni Bildirim",
            body: message.notification?.body ?? "",
            payload: jsonEncode(message.data),
          );
        }
      });

      // Handle when app is opened via FCM tap from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(jsonEncode(message.data));
      });

      // 5. Firestore Push-like Listener (DEMO MODE)
      _startFirestoreListener();
      
    } else {
      LogService.w('User declined permission');
    }
  }

  void _startFirestoreListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['isRead'] == false && data['isNotified'] != true) {
            _showLocalNotification(
              id: change.doc.id.hashCode,
              title: data['title'] ?? 'Yeni Bildirim',
              body: data['body'] ?? '',
            );
            
            // Mark the corresponding message as delivered
            if (data['type'] == 'message' && data['chatId'] != null && data['messageId'] != null) {
              _firestore
                  .collection('conversations')
                  .doc(data['chatId'])
                  .collection('messages')
                  .doc(data['messageId'])
                  .update({'isDelivered': true}).catchError((e) {
                LogService.e("Failed to update message delivered status: $e");
              });
            }

            // Mark as notified (NOT as read) to avoid duplicate popups
            change.doc.reference.update({'isNotified': true});
          }
        }
      }
    });
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dengim_messages_channel',
      'Mesaj ve Sohbet Bildirimleri',
      channelDescription: 'Anlık mesajlaşma ve bildirim ulaşımları için yüksek öncelikli kanal',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_stat_name',
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? chatId = data['chatId'];
      final String? otherUserId = data['otherUserId'];
      final String? otherUserName = data['otherUserName'];
      final String? otherUserAvatar = data['otherUserAvatar'];

      if (chatId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chatId,
              otherUserId: otherUserId ?? '',
              otherUserName: otherUserName ?? 'Kullanıcı',
              otherUserAvatar: otherUserAvatar ?? '',
            ),
          ),
        );
      }
    } catch(e) {
      LogService.e('Navigation from notification failed', e);
    }
  }

  static Future<void> updateToken() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await NotificationService().initialize();
    }
  }

  /// Harici Vercel / Next.js API'mize bildirim gönderme isteği atar
  Future<void> sendPushNotification({
    required String targetUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Not: Push bildirimleri artık Firebase Cloud Functions Firestore Trigger tetikleyicisi
    // (onNotificationCreated) tarafından otomatik olarak gönderilmektedir. 
    // Veritabanına bildirim belgesi eklendiği anda tetiklenir, bu yüzden artık 
    // istemci tarafında statik /api/send-push endpoint'ine HTTP isteği atmaya gerek yoktur.
    LogService.d("Push notification handled via Firebase Cloud Functions Firestore trigger.");
  }

  void dispose() {
    _firestoreSubscription?.cancel();
  }
}
