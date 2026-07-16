import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/log_service.dart';
import '../../../core/services/base_service.dart';

/// Rapor nedenleri
enum ReportReason {
  spam('Spam veya Reklam'),
  fakeProfile('Sahte Profil'),
  inappropriateContent('Uygunsuz İçerik'),
  harassment('Taciz veya Zorbalık'),
  underAge('Yaş Sınırı İhlali'),
  scam('Dolandırıcılık'),
  other('Diğer');

  final String displayName;
  const ReportReason(this.displayName);
}

/// Rapor modeli
class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String? additionalInfo;
  final DateTime createdAt;
  final String status; // pending, reviewed, dismissed, action_taken

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.additionalInfo,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.name,
      'reasonDisplayName': reason.displayName,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}

/// Kullanıcı raporlama servisi
class ReportService extends BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  User? get _currentUser => _auth.currentUser;

  /// Kullanıcıyı raporla
  Future<bool> reportUser({
    required String reportedUserId,
    required ReportReason reason,
    String? additionalInfo,
  }) async {
    final user = _currentUser;
    if (user == null) return false;

    // Kendini raporlayamaz
    if (user.uid == reportedUserId) return false;

    return await safeAsync(() async {
      // Aynı kullanıcıyı daha önce raporlamış mı kontrol et
      final existingReport = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: user.uid)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingReport.docs.isNotEmpty) {
        LogService.w('User already reported this user');
        throw Exception("already-reported");
      }

      // Yeni rapor oluştur
      final report = ReportModel(
        id: '',
        reporterId: user.uid,
        reportedUserId: reportedUserId,
        reason: reason,
        additionalInfo: additionalInfo,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('reports').add(report.toMap());

      // Raporlanan kullanıcının rapor sayısını artır (Hata alsa bile rapor kaydedilsin)
      try {
        await _firestore.collection('users').doc(reportedUserId).update({
          'reportCount': FieldValue.increment(1),
        });
      } catch (e) {
        LogService.w('Could not increment report count for user $reportedUserId: $e');
      }

      LogService.i('User $reportedUserId reported for ${reason.name}');
      return true;
    }, operationName: 'reportUser', defaultValue: false, rethrowError: true) ?? false;
  }

  /// Gönderdiğim raporları getir
  Future<List<ReportModel>> getMyReports() async {
    final user = _currentUser;
    if (user == null) return [];

    return await safeAsync(() async {
      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
          .toList();
    }, operationName: 'getMyReports', defaultValue: <ReportModel>[]) ?? [];
  }

  /// Mesajı raporla
  Future<bool> reportMessage({
    required String messageId,
    required String conversationId,
    required String reportedUserId,
    required ReportReason reason,
    String? messageContent,
  }) async {
    final user = _currentUser;
    if (user == null) return false;

    return await safeAsync(() async {
      await _firestore.collection('message_reports').add({
        'reporterId': user.uid,
        'reportedUserId': reportedUserId,
        'messageId': messageId,
        'conversationId': conversationId,
        'messageContent': messageContent,
        'reason': reason.name,
        'reasonDisplayName': reason.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      LogService.i('Message $messageId reported');
      return true;
    }, operationName: 'reportMessage', defaultValue: false) ?? false;
  }

  /// Hikayeyi raporla
  Future<bool> reportStory({
    required String storyId,
    required String reportedUserId,
    required ReportReason reason,
  }) async {
    final user = _currentUser;
    if (user == null) return false;

    return await safeAsync(() async {
      await _firestore.collection('story_reports').add({
        'reporterId': user.uid,
        'reportedUserId': reportedUserId,
        'storyId': storyId,
        'reason': reason.name,
        'reasonDisplayName': reason.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      LogService.i('Story $storyId reported');
      return true;
    }, operationName: 'reportStory', defaultValue: false) ?? false;
  }
}
