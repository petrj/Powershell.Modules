Set-Location $PSScriptRoot

Import-Module ./Powershell.Modules/BuildModule/BuildModule.psd1

$token = Get-SecureStringFromUserInput -Message "Enter github access token:" -EnvironmentVariable $env:GITHUB_TOKEN

dotnet build -c Release .\Powershell.Modules\Powershell.Modules.csproj

Publish-Nuget -ProjectName "Powershell.Modules" -PackageVersion "1.0.3" -SolutionPath "." -Token $token
