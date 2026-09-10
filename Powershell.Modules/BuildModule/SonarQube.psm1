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

function Export-SonarQubeAnalysis 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectKey,

        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:9000",

        [Parameter(Mandatory = $false)]
        [string]$Token = "",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\SonarQubeAnalysis.json",

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV")]
        [string]$Format = "JSON",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetrics
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Token)) 
        {
            throw "SonarQube API token is missing. Pass -Token or set `$env:SONAR_TOKEN."
        }

        $ServerUrl = $ServerUrl.TrimEnd('/')
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Token}:"))
        $headers = @{ Authorization = "Basic $auth" }

        Write-Host "Fetching issues for project '$ProjectKey' from $ServerUrl..." -ForegroundColor Cyan

        # 1. Fetch itemized issues with pagination
        $allIssues = [System.Collections.Generic.List[PSObject]]::new()
        $page = 1
        $pageSize = 500

        do {
            $issuesUrl = "${ServerUrl}/api/issues/search?componentKeys=${ProjectKey}&resolved=false&ps=${pageSize}&p=${page}"
            try 
            {
                $response = Invoke-RestMethod -Uri $issuesUrl -Headers $headers -Method Get
            }
            catch 
            {
                throw "Failed to fetch issues from SonarQube API: $_"
            }

            foreach ($issue in $response.issues) 
            {
                # Format component path to relative file path
                $filePath = $issue.component -replace "^${ProjectKey}:", ""

                $allIssues.Add([PSCustomObject]@{
                    Key        = $issue.key
                    Rule       = $issue.rule
                    Severity   = $issue.severity
                    Type       = $issue.type
                    Component  = $filePath
                    Line       = $issue.line
                    Message    = $issue.message
                    Effort     = $issue.effort
                    Creation   = $issue.creationDate
                })
            }

            $total = $response.total
            $page++
        } while ($allIssues.Count -lt $total)

        Write-Host "Retrieved $($allIssues.Count) issues." -ForegroundColor Green

        # 2. Optionally fetch summary metrics
        $metricsData = $null
        if ($IncludeMetrics) 
        {
            Write-Host "Fetching summary metrics..." -ForegroundColor Cyan
            $metricKeys = "bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,security_hotspots"
            $metricsUrl = "${ServerUrl}/api/measures/component?component=${ProjectKey}&metricKeys=${metricKeys}"
            try 
            {
                $metricsResponse = Invoke-RestMethod -Uri $metricsUrl -Headers $headers -Method Get
                $metricsData = $metricsResponse.component.measures
            }
            catch 
            {
                Write-Warning "Could not retrieve measures: $_"
            }
        }

        # 3. Export data based on requested format
        if ($Format -eq "CSV") 
        {
            $allIssues | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
            Write-Host "Exported issues to CSV: $OutputPath" -ForegroundColor Green
        }
        else 
        {
            if ($IncludeMetrics) 
            {
                $exportPayload = [PSCustomObject]@{
                    ProjectKey  = $ProjectKey
                    ExportedAt  = (Get-Date).ToString("o")
                    Measures    = $metricsData
                    IssuesCount = $allIssues.Count
                    Issues      = $allIssues
                }
            }
            else 
            {
                $exportPayload = $allIssues
            }

            $exportPayload | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
            Write-Host "Exported analysis to JSON: $OutputPath" -ForegroundColor Green
        }
    }
}
