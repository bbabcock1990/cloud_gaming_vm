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
Start-Process -FilePath $installerPath -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path $installerPath


<# #Install Parsec Virtual Display Driver
# Define the URL for the Parsec
$parsecInstallerUrl = "https://github.com/nomi-san/parsec-vdd/releases/latest/download/ParsecVDisplay-v0.45-setup.exe"
# Download the Sunshine installer
Invoke-WebRequest -Uri $parsecInstallerUrl -OutFile 'ParsecVDisplay-v0.45-setup.exe'
# Run the installer silently
Start-Process -FilePath $installerPath -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path $installerPath


#Install TigerVNC Server
# Define the URL for the TigerVNC
$tigerInstallerUrl = "https://phoenixnap.dl.sourceforge.net/project/tigervnc/stable/1.13.1/tigervnc64-winvnc-1.13.1.exe?viasf=1"
Invoke-WebRequest -Uri $tigerInstallerUrl -OutFile 'tigervnc64-winvnc-1.13.1.exe'
# Run the installer silently
Start-Process -FilePath $installerPath -ArgumentList "/S" -NoNewWindow -Wait
# Remove the installer after installation
Remove-Item -Path $installerPath #>
