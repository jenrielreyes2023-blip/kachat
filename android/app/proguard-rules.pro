# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Tencent Cloud Chat & IM SDK
-keep class com.tencent.** { *; }
-dontwarn com.tencent.**

# TRTC & LiteAV SDK
-keep class io.trtc.** { *; }
-dontwarn io.trtc.**

# Gson & Glide
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**
