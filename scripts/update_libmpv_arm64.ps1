# Auto-download script for Windows on ARM libmpv

param (
    [string]$TargetDir = "windows"
)

$ErrorActionPreference = "Stop"

$ConfigFile = "$PSScriptRoot/libmpv_config.properties"

if (Test-Path $ConfigFile) {
    $ConfigContent = Get-Content $ConfigFile
    foreach ($line in $ConfigContent) {
        if ($line -match "^Url=(.*)$") {
            $Url = $matches[1]
            break
        }
    }
} else {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

if (-not $Url) {
    Write-Error "URL not found in config file."
    exit 1
}

$ArchiveName = "libmpv-aarch64.7z"
$ExtractDir = "libmpv_temp"

Write-Host "Checking for existing libmpv..."
if (Test-Path "$TargetDir/libmpv-2.dll") {
    Write-Host "libmpv-2.dll already exists in $TargetDir. Skipping download."
    exit 0
}

Write-Host "Downloading libmpv for Windows ARM64..."
Invoke-WebRequest -Uri $Url -OutFile $ArchiveName

Write-Host "Extracting..."
# Try using 7z if available, otherwise suggest installing it or use other method
# Note: Windows built-in tar can handles some formats, but not 7z usually.
# Assuming user might have 7z installed or we can find a zip version?
# Waiting... finding a zip version is harder for these builds.
# Let's try to assume 7z command line exists or use a .zip generic approach if possible.
# Actually, minnyres/mpv-windows-arm64 usually has checks.
# To be safe and dependency free, strictly we need a zip.
# But media-kit releases are 7z.

# Alternative: Check if 7z is installed
# Alternative: Check if 7z is installed, fallback to tar (bsdtar which supports 7z on Windows 10+)
if (Get-Command "7z" -ErrorAction SilentlyContinue) {
    7z e $ArchiveName -o"$ExtractDir" libmpv-2.dll -r
} elseif (Get-Command "7za" -ErrorAction SilentlyContinue) {
    7za e $ArchiveName -o"$ExtractDir" libmpv-2.dll -r
} elseif (Get-Command "tar" -ErrorAction SilentlyContinue) {
    # Windows native tar (bsdtar) supports 7z
    New-Item -ItemType Directory -Force -Path $ExtractDir
    tar -xf $ArchiveName -C $ExtractDir libmpv-2.dll
} else {
    Write-Error "7z or tar not found. Please install 7-Zip or ensure tar is in your PATH."
    exit 1
}

Write-Host "Installing libmpv-2.dll..."
Move-Item "$ExtractDir/libmpv-2.dll" "$TargetDir/libmpv-2.dll" -Force

Write-Host "Cleaning up..."
Remove-Item $ArchiveName
Remove-Item $ExtractDir -Recurse -Force

Write-Host "Done! libmpv-2.dll is ready for ARM64 build."
