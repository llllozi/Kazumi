# Auto-download script for Windows on ARM libmpv and ANGLE

param (
    [string]$TargetDir = "windows"
)

$ErrorActionPreference = "Stop"

$ConfigFile = "$PSScriptRoot/libmpv_config.properties"

# Parse config file
$Url = $null
$AngleUrl = $null

if (Test-Path $ConfigFile) {
    $ConfigContent = Get-Content $ConfigFile
    foreach ($line in $ConfigContent) {
        if ($line -match "^Url=(.*)$") {
            $Url = $matches[1]
        }
        if ($line -match "^AngleUrl=(.*)$") {
            $AngleUrl = $matches[1]
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

# Function to extract files using available tools
function Extract-Archive {
    param (
        [string]$ArchivePath,
        [string]$OutputDir,
        [string[]]$FilesToExtract = @()
    )
    
    if ($ArchivePath -match "\.zip$") {
        # Use built-in Expand-Archive for zip files
        Expand-Archive -Path $ArchivePath -DestinationPath $OutputDir -Force
    } elseif (Get-Command "7z" -ErrorAction SilentlyContinue) {
        if ($FilesToExtract.Count -gt 0) {
            $files = $FilesToExtract -join " "
            7z e $ArchivePath -o"$OutputDir" $FilesToExtract -r
        } else {
            7z x $ArchivePath -o"$OutputDir" -r
        }
    } elseif (Get-Command "7za" -ErrorAction SilentlyContinue) {
        if ($FilesToExtract.Count -gt 0) {
            7za e $ArchivePath -o"$OutputDir" $FilesToExtract -r
        } else {
            7za x $ArchivePath -o"$OutputDir" -r
        }
    } elseif (Get-Command "tar" -ErrorAction SilentlyContinue) {
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
        tar -xf $ArchivePath -C $OutputDir
    } else {
        Write-Error "No extraction tool found. Please install 7-Zip."
        exit 1
    }
}

$ExtractDir = "libmpv_temp"
$AngleExtractDir = "angle_temp"

# --- Download and extract libmpv ---
Write-Host "Checking for existing libmpv-2.dll..."
if (-not (Test-Path "$TargetDir/libmpv-2.dll")) {
    Write-Host "Downloading libmpv for Windows ARM64..."
    $MpvArchive = "libmpv-aarch64.7z"
    Invoke-WebRequest -Uri $Url -OutFile $MpvArchive
    
    Write-Host "Extracting libmpv-2.dll..."
    New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null
    Extract-Archive -ArchivePath $MpvArchive -OutputDir $ExtractDir -FilesToExtract @("libmpv-2.dll")
    
    Move-Item "$ExtractDir/libmpv-2.dll" "$TargetDir/libmpv-2.dll" -Force
    
    Remove-Item $MpvArchive
    Remove-Item $ExtractDir -Recurse -Force
    Write-Host "[OK] libmpv-2.dll installed."
} else {
    Write-Host "[SKIP] libmpv-2.dll already exists."
}

# --- Download and extract ANGLE libraries ---
if ($AngleUrl) {
    Write-Host "Checking for ANGLE libraries (libEGL.dll, libGLESv2.dll)..."
    if (-not (Test-Path "$TargetDir/libEGL.dll") -or -not (Test-Path "$TargetDir/libGLESv2.dll")) {
        Write-Host "Downloading ANGLE ARM64 libraries..."
        $AngleArchive = "angle-arm64.zip"
        Invoke-WebRequest -Uri $AngleUrl -OutFile $AngleArchive
        
        Write-Host "Extracting ANGLE libraries..."
        New-Item -ItemType Directory -Force -Path $AngleExtractDir | Out-Null
        Extract-Archive -ArchivePath $AngleArchive -OutputDir $AngleExtractDir
        
        # Copy ANGLE DLLs to target directory
        $angleDlls = @("libEGL.dll", "libGLESv2.dll", "d3dcompiler_47.dll")
        foreach ($dll in $angleDlls) {
            $dllPath = Get-ChildItem -Path $AngleExtractDir -Filter $dll -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($dllPath) {
                Copy-Item $dllPath.FullName "$TargetDir/$dll" -Force
                Write-Host "[OK] $dll installed."
            }
        }
        
        Remove-Item $AngleArchive
        Remove-Item $AngleExtractDir -Recurse -Force
    } else {
        Write-Host "[SKIP] ANGLE libraries already exist."
    }
} else {
    Write-Host "[WARN] AngleUrl not set in config, skipping ANGLE download."
}

Write-Host ""
Write-Host "All libraries ready for ARM64 build!" -ForegroundColor Green
