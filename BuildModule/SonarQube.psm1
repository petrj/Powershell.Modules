function Test-SonarToolInstalled
{
    [CmdletBinding()]
    param(
        [string] $ToolName = "dotnet-sonarscanner"
    )

    $tool = dotnet tool list -g 2>$null |
        Select-String -Pattern "^$ToolName\s" |
        ForEach-Object { $_.Line }

    return [bool]$tool
}

function Install-SonarDotNetTool
{
    [CmdletBinding()]
    param(
        [string] $ToolName = "dotnet-sonarscanner"
    )

    if (-not (Test-SonarToolInstalled -ToolName $ToolName)) {
        Write-Host "$ToolName not found. Installing..."
        dotnet tool install --global $ToolName
    }
    else {
        Write-Host "$ToolName is already installed."
    }
}

function Initialize-TestResultsDirectory
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (Test-Path $Path) {
        Remove-Item -Recurse -Force $Path
    }

    New-Item -ItemType Directory -Path $Path | Out-Null
}

function Invoke-SonarAnalysis
{
    [CmdletBinding()]
    param(
        [string] $Token = $env:SONAR_TOKEN,
        [string] $ProjectKey = $env:SONAR_KEY,
        [string] $Url = $env:SONAR_URL,

        [string] $TestProject = "Tests/Tests.csproj",
        [string] $Exclusions = "**/bin/**,**/obj/**,Tests/**",

        [string] $WorkingDirectory = $PSScriptRoot
    )

    Push-Location $WorkingDirectory
    try {
        # Resolve secrets if not provided
        if (-not $Token) {
            $Token = Get-SecureStringFromUserInput -Message "Enter SonarQube token:"
        }

        if (-not $ProjectKey) {
            $ProjectKey = Get-SecureStringFromUserInput -Message "Enter SonarQube project key:"
        }

        if (-not $Url) {
            $Url = Get-SecureStringFromUserInput -Message "Enter SonarQube project URL:"
        }

        Install-SonarDotNetTool

        $testResultsDir = Join-Path $WorkingDirectory "TestResults"
        $testResultsPattern = Join-Path $testResultsDir "*.trx"
        $coveragePattern = Join-Path $testResultsDir "*" "coverage.opencover.xml"

        Initialize-TestResultsDirectory -Path $testResultsDir

        dotnet sonarscanner begin `
            /k:"$ProjectKey" `
            /d:sonar.host.url="$Url" `
            /d:sonar.token="$Token" `
            /d:sonar.exclusions="$Exclusions" `
            /d:sonar.cs.vstest.reportsPaths="$testResultsPattern" `
            /d:sonar.cs.opencover.reportsPaths="$coveragePattern"

        dotnet build

        Write-Host "Running unit tests and generating TRX + OpenCover coverage report..."

        dotnet test $TestProject `
            --logger "trx;LogFileName=TestResults.trx" `
            --results-directory "$testResultsDir" `
            --collect:"XPlat Code Coverage" `
            -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover

        if (-not (Get-ChildItem -Path $coveragePattern -ErrorAction SilentlyContinue)) {
            Write-Warning "No coverage.opencover.xml file found in $testResultsDir"
        }

        dotnet sonarscanner end /d:sonar.token="$Token"
    }
    finally {
        Pop-Location
    }
}

