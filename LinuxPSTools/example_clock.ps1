Set-Location $PSScriptRoot

if (Get-Module -Name PSTools) {
    Write-Host "Reloading PSTools module..."
    Remove-Module PSTools
}

Import-Module .\PSTools.psm1

Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"
"/dev/ttyUSB0" | Show-TTYDisplayClockAnimation
