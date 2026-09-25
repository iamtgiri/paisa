import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.variant.LibraryAndroidComponentsExtension
import org.gradle.kotlin.dsl.configure

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Isar 3.1 predates AGP 8's required namespace property.
subprojects {
    plugins.withId("com.android.library") {
        if (name == "isar_flutter_libs") {
            extensions.configure<LibraryExtension> {
                namespace = "dev.isar.isar_flutter_libs"
            }
            extensions.configure<LibraryAndroidComponentsExtension> {
                finalizeDsl { extension ->
                    extension.compileSdk = 36
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
