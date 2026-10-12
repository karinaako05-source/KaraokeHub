import os

def patch_build_gradle():
    # Configure jniLibs directory in build.gradle if needed
    gradle_file = "android/app/build.gradle"
    if os.path.exists(gradle_file):
        with open(gradle_file, "r") as f:
            content = f.read()
        # Remove externalNativeBuild if present
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
        
        # Ensure sourceSets includes jniLibs
        if "jniLibs.srcDirs" not in content and "android {" in content:
            idx = content.find("android {")
            insert = "\n    sourceSets {\n        main {\n            jniLibs.srcDirs = ['src/main/jniLibs']\n        }\n    }\n"
            content = content[:idx+9] + insert + content[idx+9:]
        with open(gradle_file, "w") as f:
            f.write(content)

    kts_file = "android/app/build.gradle.kts"
    if os.path.exists(kts_file):
        with open(kts_file, "r") as f:
            content = f.read()
        if "jniLibs.srcDirs" not in content and "android {" in content:
            idx = content.find("android {")
            insert = "\n    sourceSets {\n        getByName(\"main\") {\n            jniLibs.srcDirs(\"src/main/jniLibs\")\n        }\n    }\n"
            content = content[:idx+9] + insert + content[idx+9:]
        with open(kts_file, "w") as f:
            f.write(content)

if __name__ == "__main__":
    patch_build_gradle()
