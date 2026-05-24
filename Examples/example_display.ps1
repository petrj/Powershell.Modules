Set-Location $PSScriptRoot

if (Get-Module -Name LinuxPSTools)
{
    Write-Host "Reloading LinuxPSTools module..."
    Remove-Module LinuxPSTools
}

Import-Module ..\Powershell.Modules\LinuxPSTools\LinuxPSTools.psd1

function Convert-ToAscii
{
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text))
    {
        return ""
    }

    $normalized = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $withoutDiacritics = $normalized -replace '\p{M}', ''

    $withoutDiacritics = $withoutDiacritics.Replace("'", "*")
    $withoutDiacritics = $withoutDiacritics.Replace("`"", "*")
    $withoutDiacritics = $withoutDiacritics.Replace("’", "*")

    return $withoutDiacritics -replace '[^\x00-\x7F]', ''
}

Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"
Write-TTYDisplayText -DeviceName "/dev/ttyUSB0" -Text "Hello, World!"

$port = 5000

$udpClient = New-Object System.Net.Sockets.UdpClient($port)
$udpClient.Client.ReceiveTimeout = 1000

Write-Host "Listening on UDP port $port ..."

$radioName = "";
$radioText = "";
$radioFreq = "";
$radioStatus = "";

$LASTROW1 = "";
$LASTROW2 = "";
$LASTRADIOText = "";

$row2Offset = 0;

while ($true)
{
    $remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
    $gotPacket = $false

    try
    {
        $bytes = $udpClient.Receive([ref]$remoteEndPoint)
        $gotPacket = $true
    }
    catch [System.Net.Sockets.SocketException]
    {
        if ($_.Exception.SocketErrorCode -ne [System.Net.Sockets.SocketError]::TimedOut)
        {
            throw
        }
    }

    if ($gotPacket)
    {
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)

        # Parse JSON
        $data = $json | ConvertFrom-Json

        $radioStatus = Convert-ToAscii -Text ([string]$data.status)
        $radioFreq = Convert-ToAscii -Text ([string]$data.freq)
        $radioName = Convert-ToAscii -Text ([string]$data.name)
        $radioText = Convert-ToAscii -Text ([string]$data.dynamicLabel)

        if ($radioText -ne $LASTRADIOText)
        {
            $row2Offset = 0
            $LASTRADIOText = $radioText
        }
    }

    if ($radioText.Length -gt 20)
    {
        $row2Offset = ($row2Offset + 1) % ($radioText.Length + 20)
    }
    else
    {
        $row2Offset = 0
    }

    $currentTime = Get-Date -Format 'HH:mm:ss'
    $cycleMode = [math]::Floor((Get-Date).Second / 10) % 4
    switch ($cycleMode)
    {
        0 { $row1Source = [string]$radioName }
        1 { $row1Source = [string]$radioFreq }
        2 { $row1Source = [string]$radioStatus }
        3 { $row1Source = $currentTime }
        default { $row1Source = [string]$radioName }
    }

    $row1 = $row1Source.PadRight(20)
    if ($row1.length -gt 20)
    {
        $row1 = $row1.Substring(0, 20)
    }

    if ($radioText.Length -gt 20)
    {
        $scrollText = $radioText + (" " * 20)
        $start = $row2Offset % $scrollText.Length
        if ($start + 20 -le $scrollText.Length)
        {
            $row2 = $scrollText.Substring($start, 20)
        }
        else
        {
            $row2 = $scrollText.Substring($start) + $scrollText.Substring(0, 20 - ($scrollText.Length - $start))
        }
    }
    else
    {
        $row2 = $radioText.PadRight(20)
    }

    if ($row1 -ne $LASTROW1 -or $row2 -ne $LASTROW2)
    {
        $LASTROW1 = $row1
        $LASTROW2 = $row2

        Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"
        Write-TTYDisplayText -DeviceName "/dev/ttyUSB0" -Text ($row1 + $row2)
    }
}

Write-Host "<ENTER>"
Read-Host