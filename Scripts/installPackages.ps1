#This leverages the run command on the VM itself. 90 minute timeout.

param (
    [switch]$installSteam = $true,
    [switch]$installSunshine = $true,
    [string]$downloadDir = (Join-Path $env:TEMP "ScriptDownloads_$(Get-Date -Format 'yyyyMMddHHmmssff')") # Unique, user-specific temp directory
)

# Security Note: All downloads should be performed over HTTPS.
# File integrity can be further enhanced by verifying checksums (hashes) or digital signatures if available from the source.

# Function to verify file checksum (example, use if you have known hashes)
function Test-FileIntegrity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$ExpectedHash,

        [Parameter(Mandatory=$false)]
        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5")]
        [string]$Algorithm = "SHA256"
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }

    Write-Output "Calculating hash for $FilePath using $Algorithm..."
    $actualHash = (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash
    Write-Output "Actual hash: $actualHash"
    Write-Output "Expected hash: $ExpectedHash"

    if ($actualHash.Equals($ExpectedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Output "Checksum validated successfully for $FilePath."
        return $true
    } else {
        Write-Error "CHECKSUM MISMATCH for $FilePath. Expected: $ExpectedHash, Actual: $actualHash. The file may be corrupted or tampered with."
        return $false
    }
}

# Example of how to use Test-FileIntegrity (requires you to provide the expected hash):
# $steamSetupPath = Join-Path -Path $downloadDir -ChildPath "SteamSetup.exe"
# $steamExpectedHash = "YOUR_SHA256_HASH_FOR_STEAMSETUP_EXE_HERE" # Replace with actual hash
# if (Test-Path $steamSetupPath) { # Check if downloaded
#     if (-not (Test-FileIntegrity -FilePath $steamSetupPath -ExpectedHash $steamExpectedHash)) {
#         Write-Error "Steam installation will be skipped due to checksum failure."
#         # Decide here: exit script, or just skip this component
#         # For now, we'll allow the script to continue and install other components if $installSteam was true.
#         # To make it stricter, you could set $installSteam = $false here or exit the script.
#     }
# }

# For more advanced verification, especially for .exe and .msi files, consider Get-AuthenticodeSignature:
# $signature = Get-AuthenticodeSignature -FilePath "$downloadDir\SomeInstaller.exe"
# if ($signature.Status -ne "Valid") {
#     Write-Warning "Digital signature for SomeInstaller.exe is not valid: $($signature.StatusMessage)"
# } else {
#     Write-Output "Digital signature for SomeInstaller.exe is valid. Signer: $($signature.SignerCertificate.Subject)"
# }

# Download Files
# Speed up downloads by removing the "progress bars"
$ProgressPreference = 'SilentlyContinue'

# Create the download directory if it doesn't exist
if (-not (Test-Path -Path $downloadDir)) {
    Write-Output "Creating download directory: $downloadDir"
    New-Item -ItemType Directory -Path $downloadDir -ErrorAction Stop
} else {
    Write-Output "Download directory already exists: $downloadDir"
}

$commonUrls = @(
    "https://github.com/nomi-san/parsec-vdd/releases/download/v0.45.1/ParsecVDisplay-v0.45-setup.exe",
    "https://raw.githubusercontent.com/bbabcock1990/cloud_gaming_vm/main/Scripts/config.zip",
    "https://download.microsoft.com/download/0/8/1/081db0c3-d2c0-44ae-be45-90a63610b16e/AMD-Azure-NVv4-Driver-23Q3-win10-win11.exe",
    "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip",
    "https://www.tightvnc.com/download/2.8.84/tightvnc-2.8.84-gpl-setup-64bit.msi"
)

$steamUrl = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
$sunshineUrl = "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe"

$allUrls = $commonUrls
if ($installSteam) { $allUrls += $steamUrl }
if ($installSunshine) { $allUrls += $sunshineUrl }


# Loop through each URL
foreach ($url in $allUrls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    $filePath = Join-Path -Path $downloadDir -ChildPath $fileName
    Write-Output "Downloading $fileName to $filePath..."
    try {
        # Ensure HTTPS is used for all downloads
        if ($url -notmatch "^https://") {
            Write-Error "Skipping download for $fileName: URL is not HTTPS."
            continue # Skip to the next URL
        }
        Invoke-WebRequest -Uri $url -OutFile $filePath -ErrorAction Stop
        Write-Output "Successfully downloaded $fileName."

        # Warning for files where checksum isn't pre-defined in this script
        if ($fileName -in ("SteamSetup.exe", "sunshine-windows-installer.exe", "AMD-Azure-NVv4-Driver-23Q3-win10-win11.exe", "VBCABLE_Driver_Pack43.zip", "tightvnc-2.8.84-gpl-setup-64bit.msi", "ParsecVDisplay-v0.45-setup.exe", "config.zip")) {
            Write-Warning "Downloaded $fileName via HTTPS. Automatic checksum verification against a known hash is not performed by this script for this file. Ensure you trust the download source."
            # To implement checksum for a specific file, uncomment and adapt the Test-FileIntegrity example above.
            # For example, for ParsecVDisplay:
            # $parsecPath = Join-Path -Path $downloadDir -ChildPath "ParsecVDisplay-v0.45-setup.exe"
            # $parsecExpectedHash = "YOUR_PARSEC_SHA256_HASH_HERE" # Replace if you have it
            # if (-not (Test-FileIntegrity -FilePath $parsecPath -ExpectedHash $parsecExpectedHash)) { Write-Error "Parsec VDD checksum failed."; continue; }
        }

    } catch {
        Write-Error "Failed to download $fileName. Error: $($_.Exception.Message)"
        # Optionally, decide if script should exit or continue if a download fails
        # Example: throw "Critical download $fileName failed."
    }
}

# Install applications
Write-Output "Starting application installations..."

if ($installSteam) {
    $steamInstallerPath = Join-Path -Path $downloadDir -ChildPath "SteamSetup.exe"
    if (Test-Path $steamInstallerPath) {
        Write-Output "Installing Steam..."
        # Add Test-FileIntegrity call here if $steamExpectedHash is defined and valid
        try {
            Start-Process -FilePath $steamInstallerPath -ArgumentList "/S" -Wait -ErrorAction Stop
            Write-Output "Steam installed successfully."
        } catch {
            Write-Error "Failed to install Steam. Error: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Steam installer not found at $steamInstallerPath. Skipping Steam installation."
    }
}

if ($installSunshine) {
    $sunshineInstallerPath = Join-Path -Path $downloadDir -ChildPath "sunshine-windows-installer.exe"
    $sunshineConfigZipPath = Join-Path -Path $downloadDir -ChildPath "config.zip"
    if (Test-Path $sunshineInstallerPath) {
        Write-Output "Installing Sunshine..."
        # Add Test-FileIntegrity call here for sunshine-windows-installer.exe if hash is known
        try {
            Start-Process -FilePath $sunshineInstallerPath -ArgumentList "/S" -Wait -ErrorAction Stop
            Write-Output "Sunshine installed successfully."

            if (Test-Path $sunshineConfigZipPath) {
                Write-Output "Extracting Sunshine config..."
                # Add Test-FileIntegrity call here for config.zip if hash is known
                try {
                    Expand-Archive -Path $sunshineConfigZipPath -DestinationPath "$downloadDir\config_extracted" -Force -ErrorAction Stop
                    Write-Output "Sunshine config extracted."

                    Write-Output "Copying Sunshine config files..."
                    Copy-Item -Path "$downloadDir\config_extracted\*" -Destination 'C:\Program Files\Sunshine\config' -Recurse -Force -ErrorAction Stop
                    Write-Output "Sunshine config files copied."
                } catch {
                    Write-Error "Failed to configure Sunshine. Error: $($_.Exception.Message)"
                }
            } else {
                Write-Warning "Sunshine config.zip not found at $sunshineConfigZipPath. Skipping Sunshine configuration."
            }
        } catch {
            Write-Error "Failed to install Sunshine. Error: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Sunshine installer not found at $sunshineInstallerPath. Skipping Sunshine installation."
    }
}

$parsecInstallerPath = Join-Path -Path $downloadDir -ChildPath "ParsecVDisplay-v0.45-setup.exe"
if (Test-Path $parsecInstallerPath) {
    Write-Output "Installing Parsec Virtual Display Driver..."
    # Add Test-FileIntegrity call here if hash is known
    try {
        Start-Process -FilePath $parsecInstallerPath -ArgumentList "/silent" -Wait -ErrorAction Stop
        Write-Output "Parsec Virtual Display Driver installed successfully."
    } catch {
        Write-Error "Failed to install Parsec Virtual Display Driver. Error: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Parsec Virtual Display Driver installer not found. Skipping installation."
}

$amdDriverPath = Join-Path -Path $downloadDir -ChildPath "AMD-Azure-NVv4-Driver-23Q3-win10-win11.exe"
if (Test-Path $amdDriverPath) {
    Write-Output "Installing AMD GPU Drivers..."
    # Add Test-FileIntegrity call here if hash is known
    try {
        Start-Process -FilePath $amdDriverPath -ArgumentList "-Install" -Wait -ErrorAction Stop
        Write-Output "AMD GPU Drivers installed successfully."
    } catch {
        Write-Error "Failed to install AMD GPU Drivers. Error: $($_.Exception.Message)"
    }
} else {
    Write-Warning "AMD GPU Driver installer not found. Skipping installation."
}

$vbCableZipPath = Join-Path -Path $downloadDir -ChildPath "VBCABLE_Driver_Pack43.zip"
if (Test-Path $vbCableZipPath) {
    Write-Output "Extracting Virtual Audio Drivers..."
    # Add Test-FileIntegrity call here if hash is known
    try {
        Expand-Archive -Path $vbCableZipPath -DestinationPath "$downloadDir\VBCABLE_Driver_Pack43" -Force -ErrorAction Stop
        Write-Output "Virtual Audio Drivers extracted."
        # Installation of VBCABLE driver often requires interaction or specific silent flags not available.
        # Write-Warning "VB-CABLE driver extracted. Manual installation of VBCABLE_Setup_x64.exe may be required from $downloadDir\VBCABLE_Driver_Pack43."
    } catch {
        Write-Error "Failed to extract Virtual Audio Drivers. Error: $($_.Exception.Message)"
    }
} else {
    Write-Warning "VB Audio Cable zip not found. Skipping extraction."
}

# TightVNC (Example of an MSI install)
$tightVncPath = Join-Path -Path $downloadDir -ChildPath "tightvnc-2.8.84-gpl-setup-64bit.msi"
if (Test-Path $tightVncPath) {
    Write-Output "Installing TightVNC..."
    # Add Test-FileIntegrity call here if hash is known
    try {
        # Standard silent install for MSI
        Start-Process msiexec.exe -ArgumentList "/i `"$tightVncPath`" /qn /norestart" -Wait -ErrorAction Stop
        Write-Output "TightVNC installed successfully."
    } catch {
        Write-Error "Failed to install TightVNC. Error: $($_.Exception.Message)"
    }
} else {
    Write-Warning "TightVNC installer not found. Skipping installation."
}


# Schedule Automatic Reboot
Write-Output "All installations and configurations are complete."
Write-Output "Scheduling an automatic system reboot in 1 minute to apply all changes."

# Define the task name
$taskName = "ScheduledRebootByScript"

# Define the action to reboot the computer
$action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 60" # 60 second delay

# Define the trigger to start 1 minute from the current time
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1))

try {
    # Register the scheduled task
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Automatically reboots the computer 1 minute after script completion to finalize setup." -User "SYSTEM" -RunLevel Highest -Force -ErrorAction Stop
    Write-Output "Automatic reboot scheduled successfully for 1 minute from now."
} catch {
    Write-Error "Failed to schedule automatic reboot. Please reboot manually to ensure all changes take effect. Error: $($_.Exception.Message)"
}

Write-Output "Script finished. The system will reboot automatically."