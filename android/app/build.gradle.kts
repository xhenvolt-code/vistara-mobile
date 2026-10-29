plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vistara.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vistara.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

val apkOutputDirectory = layout.buildDirectory.dir("outputs/flutter-apk")
val pubspecVersion = Regex("""(?m)^version:\s*(\S+)\s*$""")
    .find(file("../../pubspec.yaml").readText())
    ?.groupValues
    ?.get(1)
    ?: error("Unable to read the app version from pubspec.yaml.")
val hasRevision = '+' in pubspecVersion
val apkChannels = mapOf(
    "Release" to "stable",
    "Profile" to "beta",
    "Debug" to "development",
)

apkChannels.forEach { (buildType, defaultChannel) ->
    val assembleTaskName = "assemble$buildType"
    val namingTask = tasks.register("copyVistara${buildType}Apks") {
        doLast {
            val channel = (System.getenv("VISTARA_CHANNEL") ?: defaultChannel)
                .trim()
                .lowercase()
            require(channel.matches(Regex("[a-z0-9]+(?:-[a-z0-9]+)*"))) {
                "VISTARA_CHANNEL must contain lowercase letters, numbers, or hyphens."
            }

            val version = android.defaultConfig.versionName
                ?: error("The Android version name is not configured.")
            val revision = android.defaultConfig.versionCode
            val revisionSuffix = if (hasRevision) "-$revision" else ""
            val outputDirectory = apkOutputDirectory.get().asFile
            val apkFiles = outputDirectory.listFiles()
                ?.filter { file ->
                    file.isFile &&
                        file.extension == "apk" &&
                        (file.name == "app-${buildType.lowercase()}.apk" ||
                            file.name.startsWith("app-") &&
                            file.name.endsWith("-${buildType.lowercase()}.apk"))
                }
                .orEmpty()
            check(apkFiles.isNotEmpty()) {
                "No Flutter APK outputs were found for the $buildType build."
            }

            apkFiles.forEach { source ->
                val variant = source.name
                    .removePrefix("app")
                    .removeSuffix("-${buildType.lowercase()}.apk")
                    .trimStart('-')
                val variantSuffix = if (variant.isEmpty()) "" else "-$variant"
                val target = outputDirectory.resolve(
                    "vistara-$version-$channel$revisionSuffix$variantSuffix.apk",
                )
                if (source != target) {
                    source.copyTo(target, overwrite = true)
                    logger.lifecycle("Vistara APK: ${target.absolutePath}")
                }
            }
        }
    }

    tasks.matching { it.name == assembleTaskName }.configureEach {
        finalizedBy(namingTask)
    }
}
