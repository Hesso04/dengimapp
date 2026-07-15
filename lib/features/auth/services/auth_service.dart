import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/log_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '12239103870-nmqifbprc2t9pgtj68ar6efpl5mnrc0e.apps.googleusercontent.com'
        : null,
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      LogService.e("Google Sign In Error", e);
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      LogService.e("Email Registration Error", e);
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      LogService.e("Email Sign In Error", e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      LogService.i("User signed out.");
    } catch (e) {
      LogService.e("Sign out error", e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      LogService.i("Password reset email sent to: $email");
    } catch (e) {
      LogService.e("Password reset error", e);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Vercel uzerindeki API'ye silme istegi at
        try {
          final url = Uri.parse('https://dengim.app/api/delete-account');
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': user.uid})
          );
        } catch (e) {
          LogService.e("Failed to trigger cascade delete API", e);
        }
        
        // 2. Yerel oturumlari kapat (API Firebase'den sildigi icin sadece cikis yapiyoruz)
        await _googleSignIn.signOut();
        await _auth.signOut();
        LogService.i("User account deleted via Next.js API.");
      }
    } catch (e) {
      LogService.e("Delete account error", e);
      rethrow;
    }
  }

  // --- PHONE AUTH & EMAIL LINK AUTHENTICATION ---
  
  ConfirmationResult? _webConfirmationResult;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    if (kIsWeb) {
      try {
        final verifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container',
        );
        final confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber, verifier);
        _webConfirmationResult = confirmationResult;
        onCodeSent(confirmationResult.verificationId);
      } catch (e) {
        if (e is FirebaseAuthException) {
          onVerificationFailed(e);
        } else {
          onVerificationFailed(FirebaseAuthException(code: 'unknown', message: e.toString()));
        }
      }
    } else {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }
  }

  Future<UserCredential> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (kIsWeb && _webConfirmationResult != null) {
        return await _webConfirmationResult!.confirm(smsCode);
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      LogService.e("Phone verification/sign in failed", e);
      rethrow;
    }
  }

  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      final acs = ActionCodeSettings(
        url: 'https://dengim-kim.firebaseapp.com/__/auth/action?email=$email',
        handleCodeInApp: true,
        androidPackageName: 'dengim.kim',
        androidMinimumVersion: '12',
        androidInstallApp: true,
        iOSBundleId: 'dengim.kim',
      );
      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
      LogService.i("Email sign in link sent to: $email");
    } catch (e) {
      LogService.e("Error sending email link", e);
      rethrow;
    }
  }

  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  Future<UserCredential> signInWithEmailLink(String email, String emailLink) async {
    try {
      return await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    } catch (e) {
      LogService.e("Email link sign in error", e);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        return await _auth.signInWithCredential(credential);
      } else {
        LogService.w("Facebook login failed with status: ${result.status}, message: ${result.message}");
        return null;
      }
    } catch (e) {
      LogService.e("Facebook Sign In Error", e);
      rethrow;
    }
  }
}

