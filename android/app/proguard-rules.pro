# =============================================================================
# prijavko — ProGuard / R8 keep rules
# =============================================================================
# WHY: Release builds run `flutter build appbundle --obfuscate
# --split-debug-info=build/symbols/` with `isMinifyEnabled = true` and
# `isShrinkResources = true` on the release buildType (see build.gradle.kts).
# R8 operates on the Kotlin/Java side only — Dart code is obfuscated
# separately by the Flutter --obfuscate flag.
#
# The libraries named below (Drift, Riverpod, Freezed, Dio) are Dart-only as
# of Story 1.1. They do NOT emit Android bytecode directly, so these keep
# rules currently match nothing. They are committed now because:
#   1. Story 1.3 introduces native plugin dependencies (sqlite3_flutter_libs
#      for Drift, `native_dio_adapter` + Cronet for Dio) that DO ship Kotlin
#      code resolved reflectively — R8 must not rename those classes.
#   2. Having the rules green from commit #1 means no Story-1.3+ dev has to
#      debug a release-only ClassNotFoundException in the middle of wiring
#      auth / queue. Poka-yoke: the rule set catches the mistake at build
#      time, not at first launch on the Play Store.
#
# Reference: each library's official ProGuard / R8 guidance.
#   - Drift: https://drift.simonbinder.eu/platforms/  (sqlite3_flutter_libs)
#   - Dio: https://pub.dev/packages/native_dio_adapter  (Cronet / OkHttp)
#   - Riverpod / Freezed: Dart-only; kept for documentation + Kotlin mirror
#     scenarios (sealed-class bridges, telemetry shims).
# =============================================================================

# -----------------------------------------------------------------------------
# Flutter engine & plugin entry points
# -----------------------------------------------------------------------------
# The Flutter Gradle plugin applies most engine keep rules automatically, but
# plugin authors occasionally forget `consumer-proguard-rules.pro` in their
# POMs. Pinning these explicitly is cheap insurance.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# -----------------------------------------------------------------------------
# Drift — sqlite3_flutter_libs native loader
# -----------------------------------------------------------------------------
# Drift itself is pure Dart. Its native SQLite runtime is supplied by
# `sqlite3_flutter_libs` (package author: simolus3), whose plugin class is
# resolved reflectively by name from the Dart isolate. Renaming it breaks the
# JNI bridge with `ClassNotFoundException` at first DB open.
-keep class com.simolus3.sqlite3_flutter_libs.** { *; }
-dontwarn com.simolus3.sqlite3_flutter_libs.**

# If a future spike moves Drift onto a background isolate, kotlinx.coroutines
# field-volatile reflection needs protection.
-keepclassmembernames class kotlinx.coroutines.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# -----------------------------------------------------------------------------
# Riverpod — @riverpod generated providers
# -----------------------------------------------------------------------------
# Riverpod is Dart-only. These rules exist as a placeholder for the day a
# Kotlin-side telemetry shim reflects on provider class names (Story 9.2+).
# Today they match nothing, which is the correct behaviour.
-dontwarn riverpod_annotation.**
-dontwarn riverpod.**

# -----------------------------------------------------------------------------
# Freezed — $CopyWith / $When generated artefacts
# -----------------------------------------------------------------------------
# Freezed generates Dart code (`*.freezed.dart`). No Kotlin/Java is emitted.
# The patterns below protect any hypothetical Kotlin sealed-class mirror of a
# Freezed union (e.g. a native JSON serializer bridge) from being renamed.
-keep class **$CopyWithImpl { *; }
-keep class **$Copy { *; }
-keep class **$When { *; }

# -----------------------------------------------------------------------------
# Dio — HttpClientAdapter, Interceptor, and the Cronet adapter path
# -----------------------------------------------------------------------------
# Dio's `HttpClientAdapter` and `Interceptor` are Dart interfaces. The
# Android-side concern is `native_dio_adapter` + Cronet (reserved for Story
# 1.3's networking layer): Cronet ships native classes loaded reflectively by
# the Chromium net stack. Certificate pinning (Story 1.3) relies on these
# symbols surviving R8.
-keep class org.chromium.net.** { *; }
-keep interface org.chromium.net.** { *; }
-dontwarn org.chromium.net.**

# OkHttp arrives transitively with Firebase and AdMob plugins. Keep its SSL
# and interceptor surfaces so custom interceptors and cert pinning keep
# working after R8.
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# -----------------------------------------------------------------------------
# Attributes required by reflection-driven frameworks (Crashlytics, Firebase)
# -----------------------------------------------------------------------------
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature, Exceptions
-keepattributes SourceFile, LineNumberTable

# Hide original source file name but keep line numbers for Crashlytics
# symbol uploads (Story 9.2 wires the upload; the attribute must be kept now).
-renamesourcefileattribute SourceFile
