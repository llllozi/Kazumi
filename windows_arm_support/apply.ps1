# 自动应用 Windows on ARM 补丁
$PatchDir = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $PatchDir

Write-Host "正在应用 Windows on ARM 补丁..." -ForegroundColor Cyan

# 复制 pubspec.yaml
Copy-Item -Path "$PatchDir\pubspec.yaml" -Destination "$ProjectRoot\pubspec.yaml" -Force
Write-Host "  [+] 已更新 pubspec.yaml"

# 复制 scripts
Copy-Item -Path "$PatchDir\scripts" -Destination "$ProjectRoot" -Recurse -Force
Write-Host "  [+] 已更新 scripts/"

# 复制 windows 构建脚本
Copy-Item -Path "$PatchDir\windows" -Destination "$ProjectRoot" -Recurse -Force
Write-Host "  [+] 已更新 windows/runner/CMakeLists.txt"

# 复制 lib 代码适配
Copy-Item -Path "$PatchDir\lib" -Destination "$ProjectRoot" -Recurse -Force
Write-Host "  [+] 已更新 lib/pages/player/player_controller.dart"

Write-Host ""
Write-Host "Patch applied successfully!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Run download script: .\scripts\update_libmpv_arm64.ps1"
Write-Host "2. Clean and Build:"
Write-Host "   fvm flutter clean; fvm flutter pub get; fvm flutter build windows"
