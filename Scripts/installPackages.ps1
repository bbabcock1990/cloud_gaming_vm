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

#Start Sunshine
Set-location -Path 'C:\Program Files\Sunshine'
.\sunshine.exe 'C:\Program Files\Sunshine\config\sunshine.conf'
