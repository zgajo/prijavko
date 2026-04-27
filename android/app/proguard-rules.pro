# =============================================================================
# prijavko — ProGuard / R8 keep rules
# =============================================================================
# WHY: release builds run `flutter build appbundle --obfuscate
# --split-debug-info=build/symbols/` with `isMinifyEnabled = true` and
# `isShrinkResources = true` on the release buildType (see build.gradle.kts).
# R8 operates on the Kotlin/Java side only — Dart code is obfuscated
# separately by the Flutter --obfuscate flag.
#
# Story 1.1 scope (per AC6 amendment in the story file's Review Findings):
# the only Kotlin/Java code in this app today is the Flutter engine plus the
# single-line MainActivity. No native plugins are in `pubspec.yaml` yet, so
# there is nothing library-specific for R8 to keep. This file therefore ships
# with:
#
#   1. Flutter engine & plugin-registry keeps  — the Flutter Gradle plugin
#      applies most engine keeps automatically, but some plugin authors skip
#      `consumer-proguard-rules.pro`. Pinning these explicitly is cheap
#      insurance and cannot regress.
#   2. Crashlytics-adjacent attribute keeps   — symbol upload (Story 9.2)
#      depends on `SourceFile` and `LineNumberTable` surviving shrink.
#
# Native-plugin keeps (sqlite3_flutter_libs for Drift, native_dio_adapter /
# Cronet / OkHttp for Dio cert pinning, Firebase / AdMob transitive keeps)
# land with the STORIES that introduce those plugins. Writing them
# speculatively today would be Muri (overburden): we would be maintaining
# package-name and reflection-contract guesses against libraries this repo
# does not yet import. Story 1.3 (Security Primitives) adds Dio's rules;
# Story 9.2 (Telemetry) confirms Crashlytics; Epic 6+ adds the SQLite-path
# rules alongside the Drift dependency itself.
# =============================================================================

# -----------------------------------------------------------------------------
# Flutter engine & plugin entry points
# -----------------------------------------------------------------------------
# Plugins discovered via GeneratedPluginRegistrant are constructed by name;
# R8 renaming them breaks the registry lookup at app launch. Keeping the
# embedding surface also protects the method-channel plumbing used by every
# plugin the project will eventually pull in.
# flutter_secure_storage — Story 1.3 AC13
-keep class com.it_nomads.fluttersecurestorage.** { *; }
# path_provider — Story 1.3 AC13
-keep class io.flutter.plugins.pathprovider.** { *; }
# cryptography_flutter uses BouncyCastle / system provider — no custom classes to keep
# dio, cookie_jar — pure Dart, no native code, no keep rules needed

# -----------------------------------------------------------------------------
# Flutter engine & plugin entry points (Story 1.1 blanket — kept until all
# plugins are known; refine in a future Kaizen pass)
# -----------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# -----------------------------------------------------------------------------
# Attributes required by reflection-driven frameworks + Crashlytics uploads
# -----------------------------------------------------------------------------
# `SourceFile` + `LineNumberTable` are what lets Story 9.2's Crashlytics
# symbol upload resolve an obfuscated stack trace back to source. Stripping
# them saves ~a few KB per class but destroys post-crash triage.
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature, Exceptions
-keepattributes SourceFile, LineNumberTable

# Hide the original source filename while preserving line numbers — the
# Crashlytics symbol uploader re-maps filenames server-side.
-renamesourcefileattribute SourceFile
