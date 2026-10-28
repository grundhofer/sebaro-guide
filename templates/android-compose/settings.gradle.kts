// Musterapp: a starter for an Android app with the sebaro design system (Kotlin, Jetpack Compose).
//
// sebaro comes only as the private Maven package de.sebaro_ventures.design:sebaro-compose from GitHub Packages.
// Read access needs a token with read:packages: gpr.user / gpr.key in ~/.gradle/gradle.properties (never in this
// folder), or the environment variables GITHUB_ACTOR / GITHUB_TOKEN. With -PsebaroLocal=true the package comes from
// mavenLocal() instead (built and published there from a sebaroDesign checkout), and no token is needed.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

val sebaroLocal = providers.gradleProperty("sebaroLocal").orNull.toBoolean()

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // the sebaro group comes from exactly one repository, every other group never from it
        exclusiveContent {
            if (sebaroLocal) {
                forRepository { mavenLocal() }
            } else {
                forRepository {
                    maven {
                        name = "sebaroPackages"
                        url = uri("https://maven.pkg.github.com/grundhofer/sebaroDesign")
                        credentials {
                            username = providers.gradleProperty("gpr.user").orNull ?: System.getenv("GITHUB_ACTOR")
                            password = providers.gradleProperty("gpr.key").orNull ?: System.getenv("GITHUB_TOKEN")
                        }
                    }
                }
            }
            filter { includeGroup("de.sebaro_ventures.design") }
        }
        google()
        mavenCentral()
    }
}

rootProject.name = "musterapp"
include(":app")
