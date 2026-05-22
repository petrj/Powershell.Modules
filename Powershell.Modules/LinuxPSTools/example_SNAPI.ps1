Set-Location $PSScriptRoot

Write-Host "Setting up module"

if (Get-Module -Name LinuxPSTools)
{
    Write-Host "Reloading LinuxPSTools module..."
    Remove-Module LinuxPSTools
} else
{
    Write-Host "LinuxPSTools module not loaded, loading for the first time..."
}

Import-Module .\LinuxPSTools.psd1

$SNAPIStream = Open-SNAPIBarcodeScanner -DevicePath "/dev/hidraw0"
$SNAPIStream | Read-SNAPIBarcode
$SNAPIStream | Close-SNAPIBarcodeScanner
