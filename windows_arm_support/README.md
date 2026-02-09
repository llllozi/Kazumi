# Windows on ARM (Arm64) 支持补丁包

## 1. 为什么不仅需要脚本？

这个补丁包不仅包含下载脚本，还必须包含以下文件的修改版本，否则项目**无法编译**或**运行崩溃**：

*   **`pubspec.yaml` (依赖配置)**
    *   **作用**: 强制项目使用**官方版** `media_kit` (支持 Arm64)，而不是旧的 Fork 版本 (不支持)。同时修复了 `webview_windows` 的版本兼容性。
    *   **后果**:如果不覆盖此文件，Flutter 会试图下载错误的 x64 库，导致应用无法启动。

*   **`windows/runner/CMakeLists.txt` (构建脚本)**
    *   **作用**: 告诉编译器："打包时，把下载好的 Arm64 版 `libmpv-2.dll` 复制到最终的 `kazumi.exe` 目录"。
    *   **后果**: 如果不覆盖此文件，虽然你下载了库，但它不会被打包进去，运行时会报错 "找不到 libmpv-2.dll"。

*   **`lib/pages/player/player_controller.dart` (代码适配)**
    *   **作用**: 删除了官方新版 `media_kit` 不支持的一行旧代码 (`adBlocker` 参数)。
    *   **后果**: 如果不覆盖此文件，编译会直接失败。

---

## 如何应用更改

**方法一：一键脚本 (推荐)**
在 `windows_arm_support` 目录下运行 PowerShell 脚本：
```powershell
.\windows_arm_support\apply.ps1
```

**方法二：手动复制**
将本目录下的所有文件覆盖到项目根目录对应的位置：
```powershell
Copy-Item -Recurse -Force .\windows_arm_support\* .
```

---

## 3. 构建步骤 (覆盖文件后)

### 第一步：准备 SDK (推荐 Master 分支)
```powershell
fvm install master
fvm use master --force
```

### 第二步：下载运行库
这一步会从 `scripts/libmpv_config.properties` 配置的地址下载 Arm64 版 `libmpv`。
```powershell
./scripts/update_libmpv_arm64.ps1
```

### 第三步：编译与运行
```powershell
fvm flutter clean
fvm flutter pub get
fvm flutter build windows
```
构建产物在 `build/windows/arm64/runner/Release/kazumi.exe`。
