import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is a credential (modules.md §24, C16): read from the git-ignored
// android/key.properties when a human provides it; never committed.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.shubhlms.mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (push notifications shown by the app) needs java.time on API 26+.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // The app's identity on a device and on Google Play. The dev and staging flavors add a suffix, and each of
        // the three is registered in Firebase (google-services.json) and vouched for in assetlinks.json.
        applicationId = "com.shubhlms.mobile"
        // 26 (Android 8.0): the live room's Jitsi Meet SDK (org.jitsi.react:jitsi-meet-sdk 13.x) requires it.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "ZuviloAI Dev"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appLabel"] = "ZuviloAI Staging"
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appLabel"] = "ZuviloAI"
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Without key.properties the release build is debug-signed for local verification
            // only; it is never distributed (modules.md §24).
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Native symbol tables go into the bundle, so Play Console can symbolicate native
            // crashes and ANRs without a separate upload.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// The live room's Jitsi SDK ships react-native-video with media3's RTSP classes compiled in; video_player
// (lesson videos) pulls the same classes as media3-exoplayer-rtsp. One copy only: the SDK's.
configurations.all {
    exclude(group = "androidx.media3", module = "media3-exoplayer-rtsp")
}

// A Play Store bundle must carry the upload key. Without key.properties the release build type falls back
// to debug signing (fine for a local APK check), so the bundle task refuses rather than produce an .aab
// Play would reject — or worse, one that registers the debug key as the app's identity.
gradle.taskGraph.whenReady {
    val storeBundle = allTasks.any { it.project == project && it.name == "bundleProdRelease" }
    if (storeBundle && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "bundleProdRelease needs android/key.properties (storeFile, storePassword, keyAlias, keyPassword) " +
                "for the upload key (modules.md §24). Nothing was built.",
        )
    }
}
