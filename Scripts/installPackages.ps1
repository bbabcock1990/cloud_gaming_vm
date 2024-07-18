#Install Steam
# Define the URL for the Steam installer
$steamInstallerUrl = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
# Define the path where the installer will be downloaded
$installerPath = "$env:USERPROFILE\Downloads\SteamSetup.exe"
# Download the Steam installer
Invoke-WebRequest -Uri $steamInstallerUrl -OutFile $installerPath
# Run the installer silently
Start-Process -FilePath $installerPath -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path $installerPath


#Install Sunshine
# Define the URL for the Sunshine installer
$sunshineInstallerUrl = "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe"
# Define the path where the installer will be downloaded
$installerPath = "$env:USERPROFILE\Downloads\sunshine-windows-installer.exe"
# Download the Sunshine installer
Invoke-WebRequest -Uri $sunshineInstallerUrl -OutFile $installerPath
# Run the installer silently
Start-Process -FilePath $installerPath -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path $installerPath


#Install Parsec Virtual Display Driver
# Define the URL for the Parsec
$parsecInstallerUrl = "https://github.com/nomi-san/parsec-vdd/releases/latest/download/ParsecVDisplay-v0.45-setup.exe"
# Define the path where the installer will be downloaded
$installerPath = "$env:USERPROFILE\Downloads\ParsecVDisplay-v0.45-setup.exe"
# Download the Sunshine installer
Invoke-WebRequest -Uri $parsecInstallerUrl -OutFile $installerPath
# Run the installer silently
Start-Process -FilePath $installerPath -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path $installerPath

