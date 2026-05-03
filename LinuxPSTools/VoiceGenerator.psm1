function Send-ToVoiceGenerator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Text,

        [string]$Language = "en"
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Text)) { return }

        $cleanText = $Text.Trim()

        try {
            # IMPORTANT: force argument array form
            & spd-say @("-l", $Language, $cleanText)
        }
        catch {
            Write-Error "spd-say failed: $_"
        }
    }
}

Export-ModuleMember -Function Send-ToVoiceGenerator