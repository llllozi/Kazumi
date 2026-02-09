# Windows on ARM Support - LLM Context Prompt

**Goal**: Enable and maintain Windows on ARM (Arm64) support for the Kazumi Flutter project.

**Project Context**:
This project targets Windows on ARM (Qualcomm Snapdragon devices).
Historically, dependencies like `media_kit` and `webview_windows` lacked prebuilt Arm64 binaries or required specific versions.
We have created a patch mechanism to resolve these compatibility issues.

**Key Files & Purpose**:

1.  **`windows_arm_support/` Directory**:
    *   Contains all necessary patches.
    *   **`apply.ps1`**: Automated script to copy these patches to the project root.
    *   **`libs/mpv-2.dll`**: (Downloaded by script) The core media playback library for Arm64.

2.  **`scripts/update_libmpv_arm64.ps1`**:
    *   **Purpose**: Downloads `libmpv-2.dll` (Arm64 version) from a URL specified in `scripts/libmpv_config.properties`.
    *   **Logic**: Checks if `libmpv-2.dll` exists in `windows/`. If not, downloads and extracts it.

3.  **`pubspec.yaml` (Patched)**:
    *   **Purpose**: Forces the use of official `media_kit` (Arm64 compatible) and a specific git version of `webview_windows` (for headless support).
    *   **Critical**: If this file is reset to upstream, the project might try to download x64 binaries.

4.  **`windows/runner/CMakeLists.txt` (Patched)**:
    *   **Purpose**: Contains a custom command to **copy** `libmpv-2.dll` from the `windows/` folder to the build output directory (`Release/`).
    *   **Critical**: Without this, the app builds but crashes at runtime (DLL missing).

5.  **`lib/pages/player/player_controller.dart` (Patched)**:
    *   **Purpose**: Removes `adBlocker` parameter from `PlayerConfiguration` as it is not supported in the newer `media_kit` version used for Arm64.

**Build Process (Windows on ARM)**:

1.  **Apply Patches**: Run `.\windows_arm_support\apply.ps1`.
2.  **Download Libs**: Run `.\scripts\update_libmpv_arm64.ps1`.
3.  **Flutter Build**:
    ```powershell
    fvm install master
    fvm use master --force
    fvm flutter clean
    fvm flutter pub get
    fvm flutter build windows
    ```

**GitHub Actions (CI/CD)**:
*   Workflow: `.github/workflows/windows_build.yml`
*   **Strategy**: Uses `ilammy/msvc-dev-cmd` with `arch: amd64_arm64` to cross-compile on x64 runners.
*   **Build Command**: Uses manual `cmake -A ARM64` commands because standard `flutter build windows` defaults to x64 on CI runners.

**Troubleshooting Guide for LLM**:

*   **Issue**: "libmpv-2.dll not found" at runtime.
    *   **Fix**: Check if `scripts/update_libmpv_arm64.ps1` was run. Check if `windows/runner/CMakeLists.txt` has the copy logic.

*   **Issue**: "Target platform x64" or "Architecture mismatch".
    *   **Fix**: Ensure you are running on an Arm64 machine OR using the specific cross-compile setup in GitHub Actions. Verify `pubspec.yaml` is using the patched version.

*   **Issue**: `webview_windows` compilation error.
    *   **Fix**: Ensure `pubspec.yaml` points to the `Predidit/flutter-webview-windows` fork (git dependency), not the official version which lacks some APIs.

*   **Issue**: `adBlocker` named parameter not defined.
    *   **Fix**: Re-apply `lib/pages/player/player_controller.dart` patch from `windows_arm_support`.
