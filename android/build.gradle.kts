allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../build").get())

subprojects {
    // Only override the build directory for the main app project
    // This prevents Gradle from trying to create relative paths across drives
    // for plugins located in the pub cache (e.g. at C:\Users\Pc\...)
    if (project.path.startsWith(":app")) {
        project.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir(project.name).get())
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
