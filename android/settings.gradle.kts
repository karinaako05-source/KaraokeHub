include(":app")

val flutterSdkPath = run {
    val properties = java.util.Properties()
    val propertiesFile = File(settingsDir.parentFile, "local.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use { properties.load(it) }
    }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
    assert(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
    flutterSdkPath
}

apply(from = "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle")
