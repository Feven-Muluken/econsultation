allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension == null) {
            return@afterEvaluate
        }

        val getNamespace = androidExtension.javaClass.methods.find {
            it.name == "getNamespace" && it.parameterCount == 0
        }
        val setNamespace = androidExtension.javaClass.methods.find {
            it.name == "setNamespace" && it.parameterCount == 1
        }

        if (getNamespace != null && setNamespace != null) {
            val currentNamespace = getNamespace.invoke(androidExtension) as String?
            if (currentNamespace == null || currentNamespace.isBlank()) {
                val fallback = "com.econsultation.${project.name.replace('-', '_')}"
                setNamespace.invoke(androidExtension, fallback)
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
