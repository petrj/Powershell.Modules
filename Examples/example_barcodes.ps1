Set-Location $PSScriptRoot

if (Get-Module -Name LinuxPSTools) {
    Write-Host "Reloading LinuxPSTools module..."
    Remove-Module LinuxPSTools
}
Import-Module ..\Powershell.Modules\LinuxPSTools\LinuxPSTools.psd1

Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"

while ($true)
{
    $msg = "Press Enter to scan a barcode, or type 'exit' to quit."
    Write-Host $msg

    $barcode = Read-Barcode

    if (-not [string]::IsNullOrWhiteSpace($barcode))
    {
        if ($barcode.Trim().ToLower() -eq "exit")
        {
            Write-Host "Exiting..."
            break
        }

        Write-Host "Scanned barcode: $barcode"
        $info = Get-BarcodeInfo -Barcode $barcode
        if ($info.Found)
        {
	    Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"
            "/dev/ttyUSB0" | Write-TTYDisplayText -Text ($info.Name + " " + $info.Brand  )

            $info

            Write-Host "Product found: $($info.Name) by $($info.Brand)"
            Send-ToVoiceGenerator -Text $info.Name -Language "cs"
    	    Start-Sleep -Seconds 1
            Send-ToVoiceGenerator -Text $info.Brand -Language "cs"
        }
        else
        {
            "/dev/ttyUSB0" | Write-TTYDisplayText -Text "???"

            Write-Host "Product not found for barcode: $barcode"
            Send-ToVoiceGenerator -Text "Tohle jsem nenašel" -Language "cs"
        }
    }
    else
    {
        "/dev/ttyUSB0" | Write-TTYDisplayText -Text "Error"

        Write-Host "No barcode entered. Please try again."
    }
}
