import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        val target = project.provider {
            project.tasks.withType<JavaCompile>().firstOrNull()?.targetCompatibility ?: "17"
        }
        compilerOptions.jvmTarget.set(target.map { JvmTarget.fromTarget(it) })
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
