# Windows on ARM (Arm64) 支持配置指南

本目录包含了让 Kazumi 在 Windows Arm64 设备（如 Surface Pro X, Snapdragon X Elite 等）上运行所需的所有修改。

---

## 🚀 快速开始 (推荐)

如果你刚刚拉取了代码，或者构建失败，请按顺序执行以下步骤：

### 第一步：应用补丁 (必做)
这一步会将必要的配置文件 (`pubspec.yaml`, `CMakeLists.txt` 等) 覆盖到项目根目录。

**在项目根目录下运行 PowerShell:**
```powershell
.\windows_arm_support\apply.ps1
```
> *注意：如果提示覆盖文件，请输入 Y 确认。*

### 第二步：下载核心库 (必做)
这一步会下载并提取 Arm64 版本的 `libmpv-2.dll`。没有它，应用无法播放视频。

**在项目根目录下运行:**
```powershell
.\scripts\update_libmpv_arm64.ps1
```

### 第三步：清理并构建
建议使用 Flutter `master` 分支以获得最佳 Arm64 支持。

```powershell
# 1. 切换到 master 分支 (推荐)
fvm install master
fvm use master --force

# 2. 清理旧构建
fvm flutter clean
fvm flutter pub get

# 3. 开始构建
fvm flutter build windows
```

构建产物位于: `build\windows\arm64\runner\Release\kazumi.exe`

---

## 📂 文件说明 (为什么要这些文件？)

| 文件 | 作用 | 后果 (如果不覆盖) |
| :--- | :--- | :--- |
| **pubspec.yaml** | 强制使用支持 Arm64 的官方 `media_kit` 和兼容的 `webview_windows`。 | 依赖下载错误，应用无法启动。 |
| **windows/runner/CMakeLists.txt** | 配置构建系统，将 Arm64 版 `libmpv` 打包进 exe。 | 编译成功但运行报错 "找不到 libmpv"。 |
| **lib/.../player_controller.dart** | 移除新版 `media_kit` 不支持的旧 API (`adBlocker`)。 | 编译失败，提示参数错误。 |
| **scripts/...** | 提供 `libmpv` 下载工具和配置文件。 | 缺少播放器核心库。 |

---

## ❓ 常见问题

**Q: 每次更新上游代码后需要重新做吗？**
A: **是的**。因为上游更新可能会覆盖 `pubspec.yaml` 等文件。每次 `git pull` 后，建议重新运行一遍 `.\windows_arm_support\apply.ps1`。

**Q: 这是给 CI 用的还是本地用的？**
A: 这是一个**通用包**。
*   **GitHub Action**: 会自动使用这个包里的逻辑进行构建。
*   **本地开发**: 按照上述步骤手动操作即可。
