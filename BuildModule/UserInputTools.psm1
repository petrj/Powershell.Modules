
Function Get-SecureStringFromUserInput
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string] $Message = 'Enter password:',

        [Parameter(Mandatory=$false)]
        [string] $EnvironmentVariable = $null
    )
    Process
    {
        Write-Host $Message -NoNewline

        if (-not ([String]::IsNullOrEmpty($EnvironmentVariable)))
        {
            $plainToken = $EnvironmentVariable
            Write-Host ".. using environment variable"
        } else
        {

            $secureToken = Read-Host -AsSecureString

            $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
            try
            {
                $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
            }
            finally
            {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
            }
        }

        Write-Output $plainToken
    }
}