plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "hr.prijavko.prijavko"

    // WHY: SDK targets are pinned to literals rather than `flutter.*` so that
    // a silent Flutter channel bump cannot drift the Play Store surface. Any
    // change here is a deliberate, reviewable edit and must be mirrored in
    // docs/ci/README.md "SDK targets". See Story 1.1 AC7.
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "hr.prijavko.prijavko"

        // WHY: API 24 (Android 7.0) is the floor promised in the PRD
        // (NFR-C1) — roughly 98% Play device coverage while shedding
        // pre-Nougat edge cases (no `NetworkSecurityConfig`, no JIT).
        minSdk = 24

        // WHY: Android 16 (API 36). Play already mandates 35 for new apps
        // (effective 2025-08-31) and moves the floor to 36 on 2026-08-31 —
        // pinning 36 now clears that cliff months ahead and matches
        // Flutter 3.38.x's default so codegen paths stay on the hot path.
        // Policy source: https://developer.android.com/google/play/requirements/target-sdk
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // WHY: R8 code shrinking + resource shrinking on release only.
            // Dart obfuscation is separate (flutter build --obfuscate); this
            // block hardens the Kotlin/Java side. Keep rules in proguard-rules.pro
            // protect reflection-bound classes from Drift/Dio native plugins
            // that land in Story 1.3+.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
