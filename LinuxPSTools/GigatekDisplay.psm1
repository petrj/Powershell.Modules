Function Write-TTYDisplayText
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName,

        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$Text,

        [switch]
        $Clear
    )
    Begin
    {
        $Text = $Text.Replace("`r","").Replace("`n","");
    }
    Process
    {
        try
        {
            if ($Clear)
            {
                $DeviceName | Clear-TTYDisplay
            }

            Invoke-Expression -Command "echo '$Text' > $DeviceName"
        }
        catch
        {
            $_
            throw
        }
    }
}

Function Clear-TTYDisplay
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateRange(0x31,0x58)]
        [byte]$StartPosition = 0x31,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateRange(0x31,0x58)]
        [byte]$EndPosition = 0x58
    )
    Process
    {
        try
        {
            $cmd = "$([char]0x04)$([char]0x01)$([char]0x43)"
            $cmd += [System.Text.Encoding]::ASCII.GetString($StartPosition)
            $cmd += [System.Text.Encoding]::ASCII.GetString($EndPosition)
            $cmd +="$([char]0x17)"

            $DeviceName | Write-TTYDisplayText -Text $cmd
        }
        catch
        {
            $_
            throw
        }
    }
}

Function Set-TTYDisplayPosition
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName,

        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateRange(0x31,0x58)]
        [byte]$Position
    )
    Process
    {
        try
        {
            $cmd = "$([char]0x04)$([char]0x01)$([char]0x50)"
            $cmd += [System.Text.Encoding]::ASCII.GetString($Position)
            $cmd +="$([char]0x17)"

            $DeviceName | Write-TTYDisplayText -Text $cmd
        }
        catch
        {
            $_
            throw
        }
    }
}

Function Show-TTYDisplayClockAnimation
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName
    )
    Process
    {
        $min = 0x31;
        $max = 0x58;

        $pos = $min;

        while ($true)
        {
            try
            {

                    $DeviceName | Clear-TTYDisplay
                    $DeviceName | Set-TTYDisplayPosition -Position $pos

                    $DeviceName | Write-TTYDisplayText -Text ([DateTime]::Now.ToString("HH:mm:ss")+" ")

                    Start-Sleep -Milliseconds 1000;
                    $pos++
                    if ($pos -gt $max)
                    {
                        $pos = $min
                    }
            }
            catch
            {
                $_
                #throw
            }
        }
    }
}

Function Show-TTYDisplayEyeAnimation
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName
    )
    Process
    {
        $eyePos = 0;

        $eyePosMin = 0;
        $eyePosMax = 4;

        while ($true)
        {
            try
            {
                    $DeviceName | Clear-TTYDisplay

                    switch ($eyePos)
                    {
                        0 { $eye = "(OO)" }
                        1 { $eye = "(oO)" }
                        2 { $eye = "(OO)" }
                        3 { $eye = "(Oo)" }
                        4 { $eye = "(OO)" }
                    }

                    $DeviceName | Write-TTYDisplayText -Text $eye

                    Start-Sleep -Milliseconds 200;

                    $eyePos++
                    if ($eyePos -gt $eyePosMax)
                    {
                        $eyePos = $eyePosMin
                    }
            }
            catch
            {
                $_
                #throw
            }
        }
    }
}

Function Show-TTYDisplayCarAnimation
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName
    )
    Process
    {
        $pos = 0;
        $max = 20;

        while ($true)
        {
            try
            {
                    $DeviceName | Clear-TTYDisplay

                    $carFirstLine =  " _/^\_ "
                    $carSecondLine = "(o---o)"

                    $DeviceName | Set-TTYDisplayPosition -Position (0x31 + $pos)
                    $DeviceName | Write-TTYDisplayText -Text $carFirstLine

                    $DeviceName | Set-TTYDisplayPosition -Position (0x31 + 20 + $pos)
                    $DeviceName | Write-TTYDisplayText -Text $carSecondLine

                    Start-Sleep -Milliseconds 500;

                    $pos++
                    if ($pos -ge $max)
                    {
                        $pos = 0
                    }
            }
            catch
            {
                $_
                #throw
            }
        }
    }
}

