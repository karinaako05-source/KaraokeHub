import os

PROGUARD_RULES = """
-dontobfuscate
-dontshrink
-dontoptimize

# Keep all BASS native classes and struct members
-keep class com.un4seen.bass.** { *; }
-keepclassmembers class com.un4seen.bass.** { *; }

# Keep SongHub NativeLib JNI bindings
-keep class com.songhub.android.database.** { *; }
-keepclassmembers class com.songhub.android.database.** { *; }

# Keep KaraokeHub Next native activity and engine
-keep class com.karaokehub.next.** { *; }
-keepclassmembers class com.karaokehub.next.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
"""

def patch_build_gradle():
    # 1. Create proguard-rules.pro in android/app/
    os.makedirs("android/app", exist_ok=True)
    with open("android/app/proguard-rules.pro", "w") as f:
        f.write(PROGUARD_RULES.strip() + "\n")
    print("Created android/app/proguard-rules.pro")

    # 2. Patch gradle.properties
    gradle_props = "android/gradle.properties"
    prop_lines = []
    if os.path.exists(gradle_props):
        with open(gradle_props, "r") as f:
            prop_lines = f.read().splitlines()
    for p in ["android.enableR8=false", "android.enableR8.fullMode=false"]:
        if p not in prop_lines:
            prop_lines.append(p)
    with open(gradle_props, "w") as f:
        f.write("\n".join(prop_lines) + "\n")
    print("Patched android/gradle.properties")

    # 3. Patch build.gradle (Groovy)
    gradle_file = "android/app/build.gradle"
    if os.path.exists(gradle_file):
        with open(gradle_file, "r") as f:
            content = f.read()

        if "externalNativeBuild" in content:
            lines = content.split("\n")
            cleaned = []
            skip = False
            for line in lines:
                if "externalNativeBuild" in line:
                    skip = True
                    continue
                if skip and "}" in line:
                    skip = False
                    continue
                if not skip:
                    cleaned.append(line)
            content = "\n".join(cleaned)

        if "jniLibs.srcDirs" not in content and "android {" in content:
            idx = content.find("android {")
            insert = "\n    sourceSets {\n        main {\n            jniLibs.srcDirs = ['src/main/jniLibs']\n        }\n    }\n"
            content = content[:idx+9] + insert + content[idx+9:]

        # Disable minification in release build type
        if "signingConfig signingConfigs.debug" in content:
            content = content.replace(
                "signingConfig signingConfigs.debug",
                "signingConfig signingConfigs.debug\n            minifyEnabled false\n            shrinkResources false\n            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'"
            )

        with open(gradle_file, "w") as f:
            f.write(content)
        print("Patched android/app/build.gradle")

    # 4. Patch build.gradle.kts (Kotlin DSL)
    kts_file = "android/app/build.gradle.kts"
    if os.path.exists(kts_file):
        with open(kts_file, "r") as f:
            content = f.read()

        if "jniLibs.srcDirs" not in content and "android {" in content:
            idx = content.find("android {")
            insert = "\n    sourceSets {\n        getByName(\"main\") {\n            jniLibs.srcDirs(\"src/main/jniLibs\")\n        }\n    }\n"
            content = content[:idx+9] + insert + content[idx+9:]

        # Disable minification in release build type
        if 'signingConfig = signingConfigs.getByName("debug")' in content:
            content = content.replace(
                'signingConfig = signingConfigs.getByName("debug")',
                'signingConfig = signingConfigs.getByName("debug")\n            isMinifyEnabled = false\n            isShrinkResources = false\n            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")'
            )

        with open(kts_file, "w") as f:
            f.write(content)
        print("Patched android/app/build.gradle.kts")

if __name__ == "__main__":
    patch_build_gradle()
