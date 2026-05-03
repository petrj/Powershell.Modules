@{
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-5678-9abc-def0-1234567890ab'
    Author            = 'Combined Modules'
    CompanyName       = 'Open Source'
    Description       = 'Combined PowerShell module for barcode scanning, display control, voice generation, and product information lookup'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    NestedModules     = @(
        'BarcodeInfo.psm1',
        'BarcodeScanner.psm1',
        'GigatekDisplay.psm1',
        'VoiceGenerator.psm1'
    )

    FunctionsToExport = @(
        'Get-BarcodeInfo',
        'Get-KeyboardLayout',
        'Set-KeyboardLayout',
        'Read-Barcode',
        'Update-Barcode',
        'Get-BarcodeScannerDevice',
        'Get-BarcodePlatform',
        'Write-TTYDisplayText',
        'Clear-TTYDisplay',
        'Set-TTYDisplayPosition',
        'Show-TTYDisplayClockAnimation',
        'Show-TTYDisplayEyeAnimation',
        'Show-TTYDisplayCarAnimation',
        'Send-ToVoiceGenerator'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags = @(
                'barcode',
                'scanner',
                'display',
                'voice',
                'tts',
                'keyboard',
                'hid',
                'linux',
                'windows',
                'raspberrypi',
                'gigatek',
                'promag'
            )

            ReleaseNotes = 'Combined BarcodeInfo, BarcodeScanner, GigatekDisplay, and VoiceGenerator modules into a single PSTools module with separate .psm1 files.'
        }
    }
}