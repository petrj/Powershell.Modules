@{
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-5678-9abc-def0-1234567890ac'
    Author            = 'Combined Modules'
    CompanyName       = 'Open Source'
    Description       = 'Build tools PowerShell module'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    NestedModules     = @(
        'BuildTools.psm1',
        'UserInputTools.psm1',
        'SonarQube.psm1'
    )

    FunctionsToExport = @(
        'Publish-Nuget',
        'Build-Project',
        'Get-SecureStringFromUserInput',
        'Test-SonarToolInstalled',
        'Install-SonarDotNetTool',
        'Invoke-SonarAnalysis'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
