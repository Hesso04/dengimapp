import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorLocalizer {
  static String localize(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'invalid-email':
          return 'Geçersiz bir e-posta adresi girdiniz.';
        case 'weak-password':
          return 'Şifreniz çok zayıf. En az 6 karakter olmalıdır.';
        case 'user-disabled':
          return 'Bu kullanıcı hesabı askıya alınmıştır.';
        case 'user-not-found':
          return 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Hatalı şifre girdiniz.';
        case 'network-request-failed':
          return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
        case 'too-many-requests':
          return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
        case 'operation-not-allowed':
          return 'Bu işlem şu anda etkin değil.';
        default:
          return error.message ?? 'Bir kimlik doğrulama hatası oluştu.';
      }
    }
    return error.toString();
  }
}
