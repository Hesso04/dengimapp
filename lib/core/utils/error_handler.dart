import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'log_service.dart';

/// Global Error Handler
/// Uygulamadaki yakalanmamış hataları yönetir
class ErrorHandler {
  static bool _initialized = false;

  /// Uygulamayı error handling ile wrap eder
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Flutter framework hataları
    FlutterError.onError = (FlutterErrorDetails details) {
      LogService.e('Flutter Error', details.exception, details.stack);
      
      // Debug modda console'a yaz
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Platform hataları (async hatalar dahil)
    PlatformDispatcher.instance.onError = (error, stack) {
      LogService.e('Platform Error', error, stack);
      return true; // Hatayı yutma, crash etme
    };
  }

  /// Hata gösterme (Snackbar)
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Hata nesnesini Türkçe ve kullanıcı dostu bir açıklamaya dönüştürür
  static String getErrorMessage(Object error) {
    // Firebase Auth Hataları
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
          return 'E-posta adresi veya şifre hatalı.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi başka bir hesap tarafından kullanılıyor.';
        case 'invalid-email':
          return 'Lütfen geçerli bir e-posta adresi giriniz.';
        case 'weak-password':
          return 'Şifre çok zayıf. Lütfen en az 6 karakterli güçlü bir şifre girin.';
        case 'user-disabled':
          return 'Hesabınız askıya alınmıştır. Destek ekibiyle iletişime geçin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı kurulamadı. Lütfen ağınızı kontrol edin.';
        case 'too-many-requests':
          return 'Çok fazla başarısız giriş denemesi yaptınız. Lütfen daha sonra tekrar deneyin.';
        default:
          return error.message ?? 'Kimlik doğrulama işlemi sırasında bir hata oluştu.';
      }
    }
    
    // Firestore / Genel Firebase Hataları
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Bu işlem için yetkiniz bulunmamaktadır (Erişim reddedildi).';
        case 'unavailable':
          return 'Sunucuyla bağlantı kurulamadı. Lütfen daha sonra tekrar deneyin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı hatası. Lütfen ağınızı kontrol edin.';
        default:
          return error.message ?? 'Veritabanı işlemi sırasında bir hata oluştu.';
      }
    }

    // Network / Socket / Timeout Hataları
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') || 
        errorStr.contains('TimeoutException') || 
        errorStr.contains('ClientException')) {
      return 'İnternet bağlantısı bulunamadı veya sunucu yanıt vermiyor. Lütfen ağ bağlantınızı kontrol edin.';
    }

    // Özel İş Mantığı Hataları
    if (errorStr.contains('already-reported')) {
      return 'Bu kullanıcıyı zaten şikayet ettiniz.';
    }

    return 'İşlem gerçekleştirilirken beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Exception nesnesini kullanıcı dostu bir Snackbar olarak gösterir
  static void showException(BuildContext context, Object error) {
    showError(context, getErrorMessage(error));
  }

  /// Başarı mesajı gösterme
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Loading dialog gösterme
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Loading dialog kapatma
  static void hideLoading(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

/// Error Boundary Widget
/// Alt widget'larda oluşan hataları yakalar ve fallback gösterir
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final void Function(Object error, StackTrace? stack)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
  }

  void _retry() {
    setState(() {
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultFallback();
    }

    return widget.child;
  }

  Widget _buildDefaultFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Bir şeyler yanlış gitti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lütfen tekrar deneyin.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
