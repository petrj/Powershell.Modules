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
        $minLine1 = 0x31;
        $maxLine1 = 0x3D;

        $minLine2 = 0x45;
        $maxLine2 = 0x51;

        $pos = $minLine1;
        $i = $true;
        $Line1 = $true;

        while ($true)
        {
            try
            {
                    $DeviceName | Clear-TTYDisplay
                    $DeviceName | Set-TTYDisplayPosition -Position $pos

                    $DeviceName | Write-TTYDisplayText -Text ([DateTime]::Now.ToString("HH:mm:ss")+" ")

                    $date = [DateTime]::Now.ToString("d.M.yyyy")
                    if ($Line1)
                    {
                        $DeviceName | Set-TTYDisplayPosition -Position ($minLine2+(20-$date.Length)/2)
                    } else
                    {
                        $DeviceName | Set-TTYDisplayPosition -Position ($minLine1+(20-$date.Length)/2)
                    }
                    $DeviceName | Write-TTYDisplayText -Text $date


                    Start-Sleep -Milliseconds 1000;

                    if ($i)
                    {
                        $pos++
                    } else
                    {
                        $pos--
                    }

                    if (( ($Line1) -and ($pos -ge $maxLine1)) -or ( (-not $Line1) -and ($pos -ge $maxLine2)))
                    {
                        $i = $false
                    }

                    if (( ($Line1) -and ($pos -le $minLine1)) -or ( (-not $Line1) -and ($pos -le $minLine2)) )
                    {
                        $i = $true

                        $Line1 = -not $Line1
                        if ($Line1)
                        {
                            $pos = $minLine1
                        } else
                        {
                            $pos = $minLine2;
                        }
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

Function Show-TTYDisplayClock
{
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$DeviceName
    )
    Process
    {
        $DeviceName | Clear-TTYDisplay

        while ($true)
        {
            try
            {
                    $time = ("  " + [DateTime]::Now.ToString("HH:mm:ss") + "  ")

                    $DeviceName | Set-TTYDisplayPosition -Position 52
                    $DeviceName | Write-TTYDisplayText -Text $time

                    Start-Sleep -Milliseconds 1000;
            }
            catch
            {
                $_
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

        $x=0
        $y=0

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


                    $eye = "".PadLeft($x) + $eye

                    if ($y -gt 0)
                    {
                        $eye = "".PadLeft(20) + $eye
                    }

                    $DeviceName | Write-TTYDisplayText -Text $eye

                    Start-Sleep -Milliseconds 200;

                    $eyePos++
                    if ($eyePos -gt $eyePosMax)
                    {
                        $eyePos = $eyePosMin
                        $x++;

                        if ($x -gt 15)
                        {
                            $x = 0
                            $y++;

                            if ($y -gt 1)
                            {
                                $y = 0
                            }
                        }
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

Export-ModuleMember -Function Write-TTYDisplayText, Clear-TTYDisplay, Set-TTYDisplayPosition, Show-TTYDisplayClock, Show-TTYDisplayClockAnimation, Show-TTYDisplayEyeAnimation, Show-TTYDisplayCarAnimation