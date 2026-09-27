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

// isar_flutter_libs 3.1.0+1 predates AGP's mandatory `namespace` and pins an
// old compileSdk that's too low for its own transitive deps; backfill both
// from here instead of patching the pub-cache. :app is skipped since it's
// force-evaluated early by evaluationDependsOn(":app") above, and calling
// afterEvaluate on an already-evaluated project throws.
subprojects {
    if (name == "app") return@subprojects

    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android.namespace == null) {
            android.namespace = group.toString()
        }
    }

    afterEvaluate {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        android?.compileSdkVersion(36)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
