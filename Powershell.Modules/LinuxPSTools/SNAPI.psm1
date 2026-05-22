function Open-SNAPIBarcodeScanner
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$DevicePath
    )

    if (-not (Test-Path $DevicePath))
    {
        throw "Device not found: $DevicePath"
    }

    $stream = [System.IO.File]::Open(
        $DevicePath,
        'Open',
        'Read',
        'ReadWrite'
    )

    return $stream
}

function Read-SNAPIBarcode {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Stream
    )

    $buffer = New-Object byte[] 64

    while ($true) {

        $read = $Stream.Read($buffer, 0, $buffer.Length)
        if ($read -le 0) { continue }

        # najdeme první ASCII start (barcode payload)
        $startIndex = -1

        for ($i = 0; $i -lt $read; $i++) {
            if ($buffer[$i] -ge 48 -and $buffer[$i] -le 57) { # '0'–'9'
                $startIndex = $i
                break
            }
        }

        if ($startIndex -lt 0) {
            continue
        }

        $sb = New-Object System.Text.StringBuilder

        for ($i = $startIndex; $i -lt $read; $i++) {

            $b = $buffer[$i]

            # konec barcode (CR/LF nebo padding 0x00)
            if ($b -eq 10 -or $b -eq 13 -or $b -eq 0) {
                break
            }

            # pouze ASCII čísla (EAN/Code128 safe)
            if ($b -ge 32 -and $b -le 126) {
                [void]$sb.Append([char]$b)
            }
        }

        $result = $sb.ToString()

        if ($result.Length -gt 0) {
            return $result
        }
    }
}

function Close-SNAPIBarcodeScanner
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Stream
    )

    if ($Stream)
    {
        $Stream.Close()
    }
}


Export-ModuleMember -Function Open-SNAPIBarcodeScanner, Read-SNAPIBarcode, Close-SNAPIBarcodeScanner