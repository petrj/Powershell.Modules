function Publish-Nuget
{
    [CmdletBinding()]
    param (
        [string]$ProjectName,
        [string]$PackageVersion,
        [string]$Token,
        [string]$SolutionPath
    )
    process
    {
        $ProjectPath = Join-Path $SolutionPath -ChildPath "$ProjectName\$ProjectName.csproj"

        dotnet build $ProjectPath -c Release /p:PackageVersion=$packageVersion

        $fName = Join-Path $SolutionPath -ChildPath "$ProjectName\bin\Release\$ProjectName.$PackageVersion.nupkg"

        dotnet nuget push $fName -k $Token --source "github"  --timeout 3000 # --skip-duplicate
    }
}

function Build-Project
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Runtime,

        [Parameter(Mandatory = $false)]
        [string]$Configuration = "Release",

        [string] $Version = "0.0.0.1",

        [string] $SolutionPath = "",
        [string] $ProjectFolder = "RadiI0",
        [string] $ProjectName = "RadiI0",

        [switch]$Compress
    )
    process
    {
        # Define supported runtimes in a single place for easy maintenance
        $AllowedRuntimes = @(
            "linux-x64", "linux-arm64", "linux-arm",
            "win-x64", "win-x86", "win-arm64"
        )

        # 1. Interactive Runtime selection if not provided via parameter
        if ([string]::IsNullOrWhiteSpace($Runtime))
        {
            Write-Host "Available Runtimes:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $AllowedRuntimes.Count; $i++)
            {
                Write-Host ("{0}) {1}" -f ($i + 1), $AllowedRuntimes[$i])
            }

            $selection = Read-Host "Select Runtime [default: 1]"
            if ([string]::IsNullOrWhiteSpace($selection)) { $selection = "1" }

            $idx = -1

            if ([int]::TryParse($selection, [ref]$idx) -and $idx -ge 1 -and $idx -le $AllowedRuntimes.Count)
            {
                $Runtime = $AllowedRuntimes[$idx - 1]
            }
            else
            {
                throw "Invalid selection."
            }
        }
        # Validate provided Runtime parameter
        elseif ($Runtime -notin $AllowedRuntimes)
        {
            throw "Invalid Runtime '$Runtime'. Supported values: $($AllowedRuntimes -join ', ')"
        }

        # 2. Setup paths and versioning
        # Using Push-Location to ensure we work from the script's root directory
        Push-Location $SolutionPath
        try
        {
            $projectPath = "$ProjectFolder/$ProjectName.csproj"
            $publishDir = "$ProjectFolder/bin/$Configuration/net10.0/$Runtime/publish"
            $baseFileName = "$ProjectName.v$Version.$Runtime"

            if ($Runtime -like "linux*")
            {
                $archiveName = "$baseFileName.tar.xz"
            }
            else
            {
                $archiveName = "$baseFileName.7z"
            }

            Write-Host "--- Starting Build Process ---" -ForegroundColor Green
            Write-Host "Configuration : $Configuration"
            Write-Host "Runtime       : $Runtime"
            Write-Host "Output Name   : $archiveName"

            # 3. Execute dotnet publish
            dotnet publish $projectPath -c $Configuration -r $Runtime --self-contained --property:Version=$Version
            if ($LASTEXITCODE -ne 0) { throw "Dotnet publish failed with exit code $LASTEXITCODE." }

            if ($Compress)
            {
                if (Test-Path $archiveName) { Remove-Item $archiveName -Force }

                # 4. Create Archive based on OS platform
                if ($Runtime -like "linux*")
                {
                    Write-Host "Compressing to TAR.XZ..." -ForegroundColor Gray

                    & tar -cvJf $archiveName -C $publishDir .
                }
                else
                {
                    Write-Host "Compressing to 7z..." -ForegroundColor Gray

                    & 7z a -mx=9 $archiveName "./$publishDir/*"
                }

                Write-Host "Success! Build saved to: $archiveName" -ForegroundColor Green

                Return Get-Item -Path $archiveName
            } else
            {
                Return Get-Item -Path $publishDir
            }
        }
        catch
        {
            Write-Error "Build failed: $_"
            throw
        } finally
        {
            Pop-Location
        }
    }
}