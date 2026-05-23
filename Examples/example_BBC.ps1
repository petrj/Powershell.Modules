Set-Location $PSScriptRoot

if (Get-Module -Name LinuxPSTools) {
    Write-Host "Reloading LinuxPSTools module..."
    Remove-Module LinuxPSTools
}

Import-Module ..\Powershell.Modules\LinuxPSTools\LinuxPSTools.psd1

Clear-TTYDisplay -DeviceName "/dev/ttyUSB0"

function Get-BbcDisplayLines {
    [CmdletBinding()]
    param()

    process {
        try {
            $rssUrl = "http://feeds.bbci.co.uk/news/world/rss.xml"

            # Stažení surového XML
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            [xml]$xml = $webClient.DownloadString($rssUrl)

            # Vytažení všech titulků pomocí XPath
            $nodes = $xml.SelectNodes("//item/title")
            if ($nodes.Count -eq 0) {
                throw "V XML nebyl nalezen zadny element <title>"
            }

            $resultArray = [System.Collections.Generic.List[string]]::new()

            # Projdeme úplně všechny nalezené zprávy
            foreach ($node in $nodes) {
                $rawTitle = $node.InnerText

                # Odstranění diakritiky (převod na čisté ASCII)
                $normalized = $rawTitle.Normalize([System.Text.NormalizationForm]::FormD)
                $sb = New-Object System.Text.StringBuilder
                foreach ($char in $normalized.ToCharArray()) {
                    if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
                        [void]$sb.Append($char)
                    }
                }
                $cleanText = ($sb.ToString() -replace '&quot;','"' -replace '&amp;','&').Trim()

                # Extrakce pouze první věty
                $sentences = $cleanText -split '(?<=[.!?])\s+'
                $firstSentence = $sentences[0]

                # Oříznutí konkrétní věty na max 255 znaků
                if ($firstSentence.Length -gt 255) {
                    $firstSentence = $firstSentence.Substring(0, 255)
                }

                if ($firstSentence) {
                    $resultArray.Add($firstSentence)
                }
            }

            # Vrácení kompletního pole stringů
            return ,$resultArray.ToArray()
        }
        catch {
            Write-Warning "Detaily selhani: $_"
            return ,@("Chyba stazeni dat z BBC RSS.")
        }
    }
}


function Get-WeatherTTY {
    [CmdletBinding()]
    param (
        [string]$Location = "Prague"
    )

    process {
        $Url = "https://wttr.in/$Location`?format=j1"

        try {
            $WeatherJson = Invoke-RestMethod -Uri $Url -UserAgent "curl"

            # Extract current conditions
            $AreaName    = $WeatherJson.nearest_area[0].areaName[0].value
            $CurrentTemp = $WeatherJson.current_condition[0].temp_C
            $Condition   = $WeatherJson.current_condition[0].weatherDesc[0].value

            # Safeguard tomorrow's data extraction
            $TomorrowMin = $WeatherJson.weather[1].mintemp_C
            $TomorrowMax = $WeatherJson.weather[1].maxtemp_C

            # Fallback if wttr.in returns empty forecast strings
            if ([string]::IsNullOrWhiteSpace($TomorrowMin) -or [string]::IsNullOrWhiteSpace($TomorrowMax)) {
                # Use today's min/max as a safe layout placeholder if tomorrow is missing
                $TomorrowMin = $WeatherJson.weather[0].mintemp_C
                $TomorrowMax = $WeatherJson.weather[0].maxtemp_C
            }

            # Assemble the string with fallback protection
            if (-not [string]::IsNullOrWhiteSpace($TomorrowMin)) {
                $RawText = "${AreaName}: ${Condition} +${CurrentTemp}C, tomorrow: ${TomorrowMin} to ${TomorrowMax}C"
            } else {
                # Ultimate fallback if forecast array is completely empty
                $RawText = "${AreaName}: ${Condition} +${CurrentTemp}C"
            }

            # Final TTY Sanitization pass
            $NormalizedText = $RawText.Normalize([System.Text.NormalizationForm]::FormD)
            $AsciiBuilder = New-Object System.Text.StringBuilder

            foreach ($Character in $NormalizedText.ToCharArray()) {
                $AsciiValue = [int]$Character
                if ($AsciiValue -ge 32 -and $AsciiValue -le 126) {
                    [void]$AsciiBuilder.Append($Character)
                }
            }

            return $AsciiBuilder.ToString()
        }
        catch {
            Write-Error "Failed to retrieve weather data: $_"
        }
    }
}



function Convert-TTYText
{
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    param (
        [string]$InputText
    )
    process
    {
        Write-Host "Converting text for TTY display: $InputText"

        $InputText = $InputText.Replace("'", "#")
        $InputText = $InputText.Replace("`"", "#")
        $InputText = $InputText.Replace("%TIME%", [datetime]::Now.ToString("HH:mm:ss"))
        $InputText = $InputText.Replace("%DATE%", [datetime]::Now.ToString("d.M.yyyy"))
        $InputText = $InputText.Replace("%DAY%", [datetime]::Now.ToString("dddd"))
    }
    end
    {
        return $InputText
    }
}

while ($true)
{

    if ($global:news -eq $null)
    {
        $global:news = Get-BbcDisplayLines
    }
    if ($global:weather -eq $null)
    {
        $global:weather = Get-WeatherTTY -Location "Benesov"
    }
    $weather = $global:weather
    $news = $global:news

    $news = $news | Get-Random -Count $news.Count

    $display = @()

    $newsIndex = 0;
    $infoIndex = 0;

    while (($newsIndex -lt $news.Count))
    {
        # Title
        switch ($infoIndex)
        {
            5 {
                $title = "%TIME%"
                $line = "%DATE%"
              }
            3 {
                $title = "Weather"
                $line = $weather
            }
            default
            {
                $title = "BBC News"
                $line = $news[$newsIndex]
                $newsIndex++
            }
        }

        $display+= @{
            Title = $title
            Line = $line
        }

        $infoIndex++;
        if ($infoIndex -gt 7)
        {
            $infoIndex = 0
        }
    }


    $twentyChars = "                    "

    foreach ($item in $display)
    {
        # Title
        "/dev/ttyUSB0" | Set-TTYDisplayPosition -Position 49

        $title = Convert-TTYText -InputText $item.Title
        $title = $title.PadRight(20)

        "/dev/ttyUSB0" | Write-TTYDisplayText -Text $title

        $displayText = Convert-TTYText -InputText $item.Line
        $displayText = ($twentyChars + $displayText)

        # scroll text
        $pos = 0
        while ($pos -le $displayText.Length)
        {
            "/dev/ttyUSB0" | Set-TTYDisplayPosition -Position 69

            $substring = $displayText.Substring($pos, [Math]::Min(20, $displayText.Length - $pos))

            while ($substring.Length -lt 20) { $substring = $substring + " " } # clearing

            "/dev/ttyUSB0" | Write-TTYDisplayText -Text $substring
            Start-Sleep -Milliseconds 50
            $pos++
        }
    }

}