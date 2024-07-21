#This leverages the run command on the VM itself. 90 minute timeout.

#Install Steam
# Define the URL for the Steam installer
$steamInstallerUrl = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
# Download the Steam installer
Invoke-WebRequest -Uri $steamInstallerUrl -OutFile 'SteamSetup.exe'
# Run the installer silently
Start-Process -FilePath 'SteamSetup.exe' -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path 'SteamSetup.exe'

#Install Sunshine
# Define the URL for the Sunshine installer
$sunshineInstallerUrl = "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe"
# Download the Sunshine installer
Invoke-WebRequest -Uri $sunshineInstallerUrl -OutFile 'sunshine-windows-installer.exe'
# Run the installer silently
Start-Process -FilePath 'sunshine-windows-installer.exe' -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path 'sunshine-windows-installer.exe'

# Define variables
$sunshineConfigZip = "https://raw.githubusercontent.com/bbabcock1990/cloud_gaming_vm/main/Scripts/config.zip"  # URL of the ZIP file

# Download the ZIP file
Invoke-WebRequest -Uri $sunshineConfigZip -OutFile 'config.zip'

# Extract the ZIP file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory('config.zip', 'C:\Temp') #Need to fix.

# Copy the extracted files to the destination folder, overwriting existing files
Copy-Item -Path "C:\Temp\config\*" -Destination 'C:\Program Files\Sunshine\config\' -Recurse -Force

# Clean up
Remove-Item -Path 'config.zip'
Remove-Item -Path 'C:\Temp' -Recurse



#Install Parsec
# Define the URL for the Parsec Virtual Driver installer
$driverUrl = "https://github.com/nomi-san/parsec-vdd/releases/download/v0.45.1/ParsecVDisplay-v0.45-setup.exe"
$driverPath = "C:\ParsecVirtualDriver.exe"
$configFilePath = "C:\parsec_config.txt"

# Download the Parsec Virtual Driver installer
Invoke-WebRequest -Uri $driverUrl -OutFile $driverPath

# Create the configuration file
$configContent = @"
virtual_monitor_width=1920
virtual_monitor_height=1080
virtual_monitor_refresh_rate=60
"@
Set-Content -Path $configFilePath -Value $configContent

# Install the Parsec Virtual Driver silently
Start-Process -FilePath $driverPath -ArgumentList "/S" -Wait

# Apply the configuration file
Copy-Item -Path $configFilePath -Destination "C:\Program Files\Parsec\config.txt" -Force



#Install AMD Drivers
# Define the URL for the AMD GPU driver
$driverUrl = "https://go.microsoft.com/fwlink/?linkid=2248541"

# Download the AMD GPU driver
Invoke-WebRequest -Uri $driverUrl -OutFile 'AMD_GPU_Driver.exe'

# Install the AMD GPU driver silently
Start-Process -FilePath 'AMD_GPU_Driver.exe' -ArgumentList "/S" -Wait


#Start Sunshine
Set-location -Path 'C:\Program Files\Sunshine'
.\sunshine.exe 'C:\Program Files\Sunshine\config\sunshine.conf'

# Reboot the VM
Restart-Computer -Force