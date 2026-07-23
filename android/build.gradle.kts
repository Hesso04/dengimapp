plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// Kotlin version for plugins that use rootProject.ext.kotlin_version (Groovy compat)
extra.set("kotlin_version", "2.0.21")
extra.set("compileSdkVersion", 36)
extra.set("minSdkVersion", 23)
extra.set("targetSdkVersion", 36)

allprojects {
    extra.set("kotlin_version", "2.0.21")
    
    repositories {
        google()
        mavenCentral()
    }
}

// Force specific Kotlin version for ALL dependencies to avoid mismatches
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.0.21")
            }
        }
    }
}

// Force build output to ASCII-only path to avoid Turkish character issues
// val newBuildDir: Directory = rootProject.layout.projectDirectory.dir("C:/tmp/dengim-build")
// rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
