import os

def patch_build_gradle():
    gradle_file = "android/app/build.gradle"
    if os.path.exists(gradle_file):
        with open(gradle_file, "r") as f:
            content = f.read()
        if "externalNativeBuild" not in content:
            idx = content.find("android {")
            if idx != -1:
                insert = "\n    externalNativeBuild {\n        cmake {\n            path \"src/main/cpp/CMakeLists.txt\"\n        }\n    }\n"
                content = content[:idx+9] + insert + content[idx+9:]
                with open(gradle_file, "w") as f:
                    f.write(content)

    kts_file = "android/app/build.gradle.kts"
    if os.path.exists(kts_file):
        with open(kts_file, "r") as f:
            content = f.read()
        if "externalNativeBuild" not in content:
            idx = content.find("android {")
            if idx != -1:
                insert = "\n    externalNativeBuild {\n        cmake {\n            path = file(\"src/main/cpp/CMakeLists.txt\")\n        }\n    }\n"
                content = content[:idx+9] + insert + content[idx+9:]
                with open(kts_file, "w") as f:
                    f.write(content)

if __name__ == "__main__":
    patch_build_gradle()
