# Reglas ProGuard/R8 para Alcancía 5k.
# Flutter inyecta código por reflection: sin estos keep, release falla en runtime.

# Flutter engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Plugins generados (GeneratedPluginRegistrant)
-keep class io.flutter.embedding.android.FlutterActivity { *; }

# Play Core (referenciado por Flutter, no esta en el APK)
-dontwarn com.google.android.play.core.**

# Kotlin
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**
