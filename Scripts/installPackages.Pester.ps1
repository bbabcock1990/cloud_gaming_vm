#Requires -Module Pester

<#
.SYNOPSIS
    Pester tests for installPackages.ps1
#>

# --- Configuration ---
# Path to the script to be tested. Adjust if your test file is in a different location relative to the script.
$ScriptPath = Join-Path $PSScriptRoot "installPackages.ps1"

# --- Test Cases ---

Describe "installPackages.ps1 Script Tests" -Tags 'Unit' {

    # Mock external commands to prevent actual system changes and to assert calls
    BeforeEach {
        # Mock file system operations
        Mock Test-Path { return $true } -ModuleName $ScriptPath # Assume paths exist by default
        Mock New-Item {} -ModuleName $ScriptPath
        Mock Join-Path { param($Path, $ChildPath) "$Path\$ChildPath" } -ModuleName $ScriptPath # Simple mock for Join-Path
        Mock Expand-Archive {} -ModuleName $ScriptPath
        Mock Copy-Item {} -ModuleName $ScriptPath
        Mock Get-FileHash { return @{ Hash = "MOCKHASH" } } -ModuleName $ScriptPath # For Test-FileIntegrity

        # Mock external process calls
        Mock Invoke-WebRequest { param($Uri, $OutFile) Write-Output "Mocked Invoke-WebRequest: $Uri to $OutFile" } -ModuleName $ScriptPath
        Mock Start-Process { Write-Output "Mocked Start-Process: $($_.FilePath) with $($_.ArgumentList)" } -ModuleName $ScriptPath
        Mock msiexec.exe { Write-Output "Mocked msiexec.exe with $($_.ArgumentList)"} # For MSI installs

        # Mock user interaction and system changes
        Mock Read-Host { return 'N' } -ModuleName $ScriptPath # Default to 'No' for reboot prompt
        Mock Register-ScheduledTask {} -ModuleName $ScriptPath
        Mock Write-Output {} # Suppress normal output during tests unless specifically checked
        Mock Write-Warning {}
        Mock Write-Error {}

        # Mock the Test-FileIntegrity function defined within the script for focused testing of other parts
        # When testing Test-FileIntegrity itself, this mock should be removed or overridden in that Context.
        Mock Test-FileIntegrity { return $true } -ModuleName $ScriptPath
    }

    Context "Parameter Handling" {
        It "Should use default value for -downloadDir if not provided" {
            . $ScriptPath # Run the script with its defaults
            $DefaultDirPattern = "ScriptDownloads_"
            Assert-MockCalled New-Item -ParameterFilter { $Path -like "*$DefaultDirPattern*" } -Times 1 -ModuleName $ScriptPath
        }

        It "Should use provided -downloadDir" {
            $CustomDir = "C:\MyCustomDownloads"
            . $ScriptPath -downloadDir $CustomDir
            Assert-MockCalled New-Item -ParameterFilter { $Path -eq $CustomDir } -Times 1 -ModuleName $ScriptPath
        }

        It "Should default -installSteam to $true" {
            # This implies Steam download/install logic would be hit
            . $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*SteamSetup.exe*" } -ModuleName $ScriptPath
        }

        It "Should default -installSunshine to $true" {
            # This implies Sunshine download/install logic would be hit
            . $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*sunshine-windows-installer.exe*" } -ModuleName $ScriptPath
        }

        It "Should respect -installSteam:$false" {
            . $ScriptPath -installSteam:$false
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*SteamSetup.exe*" } -Times 0 -ModuleName $ScriptPath
            Assert-MockCalled Start-Process -ParameterFilter { $_.FilePath -like "*SteamSetup.exe*" } -Times 0 -ModuleName $ScriptPath
        }

        It "Should respect -installSunshine:$false" {
            . $ScriptPath -installSunshine:$false
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*sunshine-windows-installer.exe*" } -Times 0 -ModuleName $ScriptPath
            Assert-MockCalled Start-Process -ParameterFilter { $_.FilePath -like "*sunshine-windows-installer.exe*" } -Times 0 -ModuleName $ScriptPath
            Assert-MockCalled Expand-Archive -ParameterFilter { $_.Path -like "*config.zip*" } -Times 0 -ModuleName $ScriptPath # Sunshine config
        }
    }

    Context "Download Logic" {
        It "Should attempt to download common URLs" {
            . $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*ParsecVDisplay*" } -ModuleName $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*AMD-Azure-NVv4-Driver*" } -ModuleName $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*VBCABLE_Driver_Pack43.zip*" } -ModuleName $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*tightvnc*.msi*" } -ModuleName $ScriptPath
        }

        It "Should attempt to download Steam if installSteam is $true" {
            . $ScriptPath -installSteam:$true
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*SteamSetup.exe*" } -Times 1 -ModuleName $ScriptPath
        }

        It "Should attempt to download Sunshine if installSunshine is $true" {
            . $ScriptPath -installSunshine:$true
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*sunshine-windows-installer.exe*" } -Times 1 -ModuleName $ScriptPath
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*config.zip*" } -Times 1 -ModuleName $ScriptPath # Sunshine config
        }

        It "Should skip download if URL is not HTTPS" {
            # Need to override the script's $commonUrls or $allUrls for this test
            # This is more complex with Pester's scoping and script Sourcing.
            # A more direct way would be to refactor the download loop into a function.
            # For now, this scenario is noted as harder to test directly without refactoring.
            Skip "HTTPS check test requires refactoring or more complex mocking setup."
        }

        It "Should call Write-Warning for specified files after download" {
            . $ScriptPath
            # Check one specific file as an example
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -like "*SteamSetup.exe*" } -ModuleName $ScriptPath
            Assert-MockCalled Write-Warning -ParameterFilter { $_ -like "*SteamSetup.exe*checksum verification against a known hash is not performed*" } -ModuleName $ScriptPath
        }
    }

    Context "Installation Logic" {
        BeforeEach {
             # Ensure Test-Path for installer files returns $true so install logic is hit
            Mock Test-Path { param($Path) return $true } -ModuleName $ScriptPath
        }

        It "Should attempt to install Steam if -installSteam is $true and file exists" {
            . $ScriptPath -installSteam:$true
            Assert-MockCalled Start-Process -ParameterFilter { $_.FilePath -like "*SteamSetup.exe*" } -ModuleName $ScriptPath
        }

        It "Should NOT attempt to install Steam if installer file does not exist" {
            Mock Test-Path { param($Path) if ($Path -like "*SteamSetup.exe*") { return $false } else { return $true } } -ModuleName $ScriptPath
            . $ScriptPath -installSteam:$true
            Assert-MockCalled Start-Process -ParameterFilter { $_.FilePath -like "*SteamSetup.exe*" } -Times 0 -ModuleName $ScriptPath
            Assert-MockCalled Write-Warning -ParameterFilter { $_ -like "*Steam installer not found*" } -ModuleName $ScriptPath
        }

        It "Should attempt to install Sunshine and configure it if -installSunshine is $true and files exist" {
            . $ScriptPath -installSunshine:$true
            Assert-MockCalled Start-Process -ParameterFilter { $_.FilePath -like "*sunshine-windows-installer.exe*" } -ModuleName $ScriptPath
            Assert-MockCalled Expand-Archive -ParameterFilter { $_.Path -like "*config.zip*" } -ModuleName $ScriptPath
            Assert-MockCalled Copy-Item -ParameterFilter { $_.Destination -like "*Sunshine\config*" } -ModuleName $ScriptPath
        }

        It "Should attempt to install TightVNC MSI" {
             . $ScriptPath # Assuming TightVNC is always attempted if downloaded
             Assert-MockCalled Start-Process -ParameterFilter { $_.FilePath -eq "msiexec.exe" -and $_.ArgumentList -like "*/i*tightvnc*.msi* /qn*" } -ModuleName $ScriptPath
        }
    }

    Context "Error Handling" {
        It "Should call Write-Error if Invoke-WebRequest fails" {
            Mock Invoke-WebRequest { throw "Download failed" } -ModuleName $ScriptPath
            . $ScriptPath
            Assert-MockCalled Write-Error -ParameterFilter { $_ -like "*Failed to download*" } -Times ([array]$allUrls).Count -ModuleName $ScriptPath # Check it's called for each URL
        }

        It "Should call Write-Error if Start-Process for an install fails" {
            Mock Start-Process { throw "Installation failed" } -ModuleName $ScriptPath
            . $ScriptPath -installSteam:$true # Test with Steam
            Assert-MockCalled Write-Error -ParameterFilter { $_ -like "*Failed to install Steam*" } -ModuleName $ScriptPath
        }
    }

    Context "Reboot Prompt" {
        It "Should call Register-ScheduledTask if user inputs 'Y' to reboot" {
            Mock Read-Host { return 'Y' } -ModuleName $ScriptPath
            . $ScriptPath
            Assert-MockCalled Register-ScheduledTask -ModuleName $ScriptPath
        }

        It "Should NOT call Register-ScheduledTask if user inputs 'N' to reboot" {
            Mock Read-Host { return 'N' } -ModuleName $ScriptPath
            . $ScriptPath
            Assert-MockCalled Register-ScheduledTask -Times 0 -ModuleName $ScriptPath
        }

        It "Should call Write-Error if Register-ScheduledTask fails" {
            Mock Read-Host { return 'Y' } -ModuleName $ScriptPath # User agrees to reboot
            Mock Register-ScheduledTask { throw "Failed to schedule task" } -ModuleName $ScriptPath
            . $ScriptPath
            Assert-MockCalled Write-Error -ParameterFilter { $_ -like "*Failed to schedule reboot*" } -ModuleName $ScriptPath
        }
    }

    Context "Test-FileIntegrity Function (Internal)" {
        # For testing this specific function, we remove the general mock of it.
        # We also need to ensure Get-FileHash is unmocked or mocked specifically for these tests.
        BeforeEach {
            Remove-Mock -CommandName Test-FileIntegrity -ModuleName $ScriptPath
            Mock Get-FileHash { param($Path, $Algorithm) return @{ Hash = "CORRECT_HASH_FOR_TEST"; Algorithm = $Algorithm } } -ModuleName $ScriptPath
        }

        It "Should return $true if hashes match" {
            Invoke-Command -ScriptBlock ([scriptblock]::Create("param(`$FilePath, `$ExpectedHash) . $ScriptPath; return Test-FileIntegrity -FilePath `$FilePath -ExpectedHash `$ExpectedHash")) -ArgumentList "dummy.file", "CORRECT_HASH_FOR_TEST" | Should -Be $true
            Assert-MockCalled Write-Output -ParameterFilter { $_ -like "*Checksum validated successfully*" } -ModuleName $ScriptPath # Check specific output from the function
        }

        It "Should return $false if hashes do not match" {
            Invoke-Command -ScriptBlock ([scriptblock]::Create("param(`$FilePath, `$ExpectedHash) . $ScriptPath; return Test-FileIntegrity -FilePath `$FilePath -ExpectedHash `$ExpectedHash")) -ArgumentList "dummy.file", "WRONG_HASH" | Should -Be $false
            Assert-MockCalled Write-Error -ParameterFilter { $_ -like "*CHECKSUM MISMATCH*" } -ModuleName $ScriptPath
        }

        It "Should return $false if file does not exist (via Test-Path mock)" {
            Mock Test-Path { return $false } -ModuleName $ScriptPath # Override global Test-Path mock for this test
            Invoke-Command -ScriptBlock ([scriptblock]::Create("param(`$FilePath, `$ExpectedHash) . $ScriptPath; return Test-FileIntegrity -FilePath `$FilePath -ExpectedHash `$ExpectedHash")) -ArgumentList "nonexistent.file", "ANY_HASH" | Should -Be $false
            Assert-MockCalled Write-Error -ParameterFilter { $_ -like "*File not found*" } -ModuleName $ScriptPath
        }
    }
}

# To run these tests (assuming Pester is installed and PowerShell is available):
# 1. Save this file as installPackages.Pester.ps1 in the same directory as installPackages.ps1.
# 2. Open a PowerShell terminal in that directory.
# 3. Run: Invoke-Pester

Write-Host "Pester test file 'installPackages.Pester.ps1' created."
Write-Host "Note: PowerShell (pwsh or powershell) was not found in the environment, so Pester could not be installed or tests executed."
Write-Host "The tests are written and can be run in an environment with PowerShell and Pester."
