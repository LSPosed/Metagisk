plugins {
    `kotlin-dsl`
}
repositories {
    google()
    mavenCentral()
}

gradlePlugin {
    plugins {
        register("MagiskPlugin") {
            id = "MagiskPlugin"
            implementationClass = "MagiskPlugin"
        }
    }
}

dependencies {
    implementation(embeddedKotlin("gradle-plugin"))
    implementation("com.android.tools.build:gradle:8.2.0")
    implementation("androidx.navigation:navigation-safe-args-gradle-plugin:2.7.5")
    implementation("org.lsposed.lsparanoid:gradle-plugin:0.6.0")
    implementation("org.eclipse.jgit:org.eclipse.jgit:6.8.0.202311291450-r")
}
