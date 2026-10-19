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
    // This ensures we don't force settings on the app module from here,
    // which usually causes the "finalized" error.
    afterEvaluate {
        project.plugins.withId("com.android.library") {
            val android = project.extensions.getByType(com.android.build.api.dsl.LibraryExtension::class.java)
            
            // Set namespace if missing
            if (android.namespace == null) {
                android.namespace = "com.fruitsofspirit.ecommerce.${project.name.replace("-", "_")}"
            }

            // Use compileOptions only if not already finalized
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // This block forces the Kotlin compiler to use Java 17 across ALL tasks
    // This fixes the "Inconsistent JVM Target" error.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
