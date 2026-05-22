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

        # Find the first ASCII starting index (barcode payload)
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

            # End of barcode indicators (CR/LF or padding 0x00)
            if ($b -eq 10 -or $b -eq 13 -or $b -eq 0) {
                break
            }

            # Capture printable ASCII characters
            if ($b -ge 32 -and $b -le 126) {
                [void]$sb.Append([char]$b)
            }
        }

        $result = $sb.ToString()

        if ($result.Length -gt 0) {
            # --- THE LINUX HIDRAW COMPLIANT HANDSHAKE ---
            # Create a clean 64-byte hardware report buffer
            [byte[]]$linuxAckReport = New-Object byte[] 64

            # Byte 0: Linux Report ID (Must be 0x00 for standard HIDRAW output)
            $linuxAckReport[0] = 0x00

            # Bytes 1-4: The SNAPI host acknowledgment payload sequence
            $linuxAckReport[1] = 0x04  # Packet length
            $linuxAckReport[2] = 0xD0  # CMD_ACK Opcode
            $linuxAckReport[3] = 0x00  # Status OK
            $linuxAckReport[4] = 0x2C  # Complement Checksum

            try {
                # Write out the complete 64-byte report block
                $Stream.Write($linuxAckReport, 0, $linuxAckReport.Length)
                $Stream.Flush()
            }
            catch {
                Write-Warning "Could not deliver handshake back to the SNAPI interface."
            }
            # --------------------------------------------

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