plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

// the Android 16 framework jar Robolectric draws with, fetched by Gradle like any dependency
val robolectricAndroidAll = configurations.create("robolectricAndroidAll")

android {
    namespace = "de.example.musterapp"
    // compileSdk 37: the sebaro package is compiled against it
    compileSdk = 37

    defaultConfig {
        applicationId = "de.example.musterapp"
        // minSdk 24 as the sebaro package (spec/08 §2.1); targetSdk 35 or later for edge-to-edge (spec/08 §2.2),
        // 36 because Google Play requires it for new apps and updates
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // java.time (dates in SbMessages, SbSortableTable) below API 26
        isCoreLibraryDesugaringEnabled = true
    }

    // the in-app language choice needs every language in the base APK of an app bundle
    bundle {
        language {
            enableSplit = false
        }
    }

    lint {
        abortOnError = true
        // the language list lives in res/xml/locales_config.xml
        disable += "OldTargetApi"
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all { test ->
                // Screenshots (Roborazzi): by default every run records into build/screenshots/ to look at;
                // -Pshots=record writes the references into app/screenshots/ (git-ignored),
                // -Pshots=verify compares a fresh drawing with them and fails on a difference.
                val shots = providers.gradleProperty("shots").orNull
                val dir = if (shots == null) layout.buildDirectory.dir("screenshots").get().asFile
                else layout.projectDirectory.dir("screenshots").asFile
                test.systemProperty("musterapp.shots.dir", dir.absolutePath)
                if (shots == "verify") {
                    test.systemProperty("roborazzi.test.verify", "true")
                } else {
                    test.systemProperty("roborazzi.test.record", "true")
                }
                // Robolectric draws with the Android 16 framework jar that Gradle fetched (no download in the test)
                val androidAll = robolectricAndroidAll
                test.inputs.files(androidAll)
                test.systemProperty("robolectric.offline", "true")
                test.doFirst { test.systemProperty("robolectric.dependency.dir", androidAll.singleFile.parent) }
                // SDK 36 reaches into java.base internals that JDK 17+ closes
                test.jvmArgs(
                    "--add-opens=java.base/jdk.internal.access=ALL-UNNAMED",
                    "--add-opens=java.base/java.io=ALL-UNNAMED",
                )
                test.maxHeapSize = "3g"
            }
        }
    }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.sebaro.compose)
    implementation(libs.activity.compose)
    coreLibraryDesugaring(libs.desugar.jdk.libs)

    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    debugImplementation(libs.compose.ui.test.manifest)
    robolectricAndroidAll(libs.robolectric.android.all)
}

// sebaro's text checks over the app's Kotlin sources (tools/lint-sebaro-android.sh, needs a POSIX shell);
// part of ./gradlew check, or run alone with ./gradlew lintSebaro
val lintSebaro = tasks.register<Exec>("lintSebaro") {
    group = "verification"
    description = "Checks the Kotlin sources for sebaro parts drawn without the package's wrappers."
    val script = rootProject.layout.projectDirectory.file("tools/lint-sebaro-android.sh")
    val sources = layout.projectDirectory.dir("src/main/kotlin")
    inputs.file(script)
    inputs.dir(sources)
    commandLine("sh", script.asFile.path, sources.asFile.path)
}
tasks.named("check") { dependsOn(lintSebaro) }
