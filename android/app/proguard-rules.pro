# Flutter-specific ProGuard rules

# Keep Flutter wrapper classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================================
# APPLICATION MODEL & ENUM PROTECTION
# ============================================================
-keep class com.dengim.** { *; }

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================
# FIREBASE / FIRESTORE KORUMASI
# ============================================================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firestore internal classes & annotations
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.cloud.firestore.** { *; }

-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Messaging (FCM)
-keep class com.google.firebase.messaging.** { *; }

# Firebase Remote Config
-keep class com.google.firebase.remoteconfig.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# ============================================================
# LIVEKIT (VOICE / VIDEO CALLS) & WEBRTC KORUMASI
# ============================================================
-keep class io.livekit.** { *; }
-dontwarn io.livekit.**
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn com.cloudwebrtc.webrtc.**

# Native JNI Method protection (WebRTC native audio engines)
-keepclasseswithmembernames class * {
    native <methods>;
}

# OkHttp / WebSocket signaling for LiveKit RTC
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Kotlin Coroutine & Reflective Access
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# AGORA - eski/aktif değil ama geriye uyumluluk için kurallar kalsın
-keep class io.agora.** { *; }
-dontwarn io.agora.**

-keep class io.agora.rtc2.** { *; }
-dontwarn io.agora.rtc2.**

# ============================================================
# PERMISSION HANDLER & SYSTEM PLUGINS
# ============================================================
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ============================================================
# PROTOBUF & gRPC (Firestore internal)
# ============================================================
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# ============================================================
# GOOGLE PLAY SERVICES & CORE
# ============================================================
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**

# AndroidX Window extensions
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# Amazon Appstore SDK
-dontwarn com.amazon.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Prevent stripping of Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
