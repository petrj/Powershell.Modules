Set-Location $PSScriptRoot

if (Get-Module -Name LinuxPSTools) {
    Write-Host "Reloading LinuxPSTools module..."
    Remove-Module LinuxPSTools
}

Import-Module ..\Powershell.Modules\LinuxPSTools\LinuxPSTools.psd1

Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"
"/dev/ttyUSB0" | Show-TTYDisplayClockAnimation
