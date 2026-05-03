# BarcodeScanner.psm1
# Cross-platform barcode scanner (keyboard wedge)

$script:KeyboardLayout = "US"
$script:TimeoutMs = 200

# -----------------------------
# Layout management
# -----------------------------

function Get-KeyboardLayout {
    return $script:KeyboardLayout
}

function Set-KeyboardLayout {
    param(
        [ValidateSet("US", "CZ")]
        [string]$Layout = "US"
    )

    $script:KeyboardLayout = $Layout
}

# -----------------------------
# Barcode reader
# -----------------------------

function Read-Barcode {
    param(
        [int]$TimeoutMs = 200,
        $Title = "Scan barcode"
    )
    End
    {
        $buffer = ""
        $last = Get-Date

        while ($true) {
            if ([System.Console]::KeyAvailable) {
                $key = [System.Console]::ReadKey($true)
                $now = Get-Date

                if (($now - $last).TotalMilliseconds -gt $TimeoutMs) {
                    $buffer = ""
                }

                $last = $now

                if ($key.Key -eq "Enter") {
                    if ($buffer.Length -gt 0) {
                        return Update-Barcode $buffer
                    }
                } else {
                    $buffer += $key.KeyChar
                }
            }
            else {
                Start-Sleep -Milliseconds 5
            }
        }
    }
}

function Update-Barcode {
    param([string]$Value)

    # mapping observed from scanner symbols → digits
    $map = @{
        33 = '1'
        64 = '2'
        35 = '3'
        36 = '4'
        37 = '5'
        94 = '6'
        38 = '7'
        42 = '8'
        40 = '9'
        41 = '0'
    }

    $output = ""

    foreach ($c in $Value.ToCharArray())
    {
        $code = [int][char]$c

        if ($map.ContainsKey($code))
        {
            $output += $map[$code]
        }
        else
        {
            $output += $c
        }
    }

    return $output
}

# -----------------------------
# Device helpers
# -----------------------------

function Get-BarcodeScannerDevice {
    if ($IsLinux) {
        Get-ChildItem /dev/input/by-id -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "kbd|scanner|barcode|symbol" } |
            Select-Object Name, FullName
    }
    elseif ($IsWindows) {
        Get-CimInstance Win32_Keyboard |
            Select-Object Name, Description
    }
}

function Get-BarcodePlatform {
    if ($IsWindows) { "Windows" }
    elseif ($IsLinux) { "Linux" }
    elseif ($IsMacOS) { "MacOS" }
    else { "Unknown" }
}

Export-ModuleMember -Function `
    Read-Barcode, `
    Get-KeyboardLayout, `
    Set-KeyboardLayout, `
    Update-Barcode, `
    Get-BarcodeScannerDevice, `
    Get-BarcodePlatform