# LinuxPsTools and BuildModule

This repository contains two PowerShell modules:

- `LinuxPSTools` — Linux-focused utilities for barcode scanning, display control, voice generation, and product information lookup.
- `BuildModule` — build automation and SonarQube tooling for .NET and PowerShell projects.

## Features

- **Barcode Scanning**: Cross-platform barcode reader with keyboard wedge support
- **Display Control**: Control Gigatek/Promag serial displays
- **Voice Generation**: Text-to-speech using spd-say
- **Product Information**: Lookup product details from OpenFoodFacts API

## Installation

1. Clone or download this repository
2. Place the module files in a directory accessible to PowerShell
3. Import the module:

```powershell
Import-Module .\LinuxPsTools.psd1
```

## Requirements

- PowerShell 5.1 or higher
- Linux environment (tested on Raspberry Pi)
- `spd-say` for voice generation (install with `sudo apt-get install speech-dispatcher`)
- Serial display device (optional, for display functions)

## Functions

### BarcodeInfo Module
- `Get-BarcodeInfo` - Lookup product information from barcode

### BarcodeScanner Module
- `Read-Barcode` - Read barcode from keyboard input
- `Get-KeyboardLayout` - Get current keyboard layout
- `Set-KeyboardLayout` - Set keyboard layout (US/CZ)
- `Update-Barcode` - Translate scanner symbols to digits
- `Get-BarcodeScannerDevice` - List barcode scanner devices
- `Get-BarcodePlatform` - Get current platform

### GigatekDisplay Module
- `Write-TTYDisplayText` - Write text to serial display
- `Clear-TTYDisplay` - Clear display
- `Set-TTYDisplayPosition` - Set cursor position
- `Show-TTYDisplayClockAnimation` - Display animated clock
- `Show-TTYDisplayEyeAnimation` - Display animated eyes
- `Show-TTYDisplayCarAnimation` - Display animated car

### VoiceGenerator Module
- `Send-ToVoiceGenerator` - Convert text to speech

### BuildModule
- `Publish-Nuget` - Publish a NuGet package
- `Build-Project` - Build a project or solution
- `Get-SecureStringFromUserInput` - Prompt the user for secure string input
- `Test-SonarToolInstalled` - Check whether Sonar tools are installed
- `Install-SonarDotNetTool` - Install Sonar .NET analyzer tooling
- `Invoke-SonarAnalysis` - Run SonarQube analysis

## Usage Examples

### Basic Barcode Scanning
```powershell
Import-Module .\LinuxPsTools.psd1

# Scan a barcode
$barcode = Read-Barcode

# Get product info
$info = Get-BarcodeInfo -Barcode $barcode
Write-Host "Product: $($info.Name)"

# Display on serial display
"/dev/ttyUSB0" | Write-TTYDisplayText -Text $info.Name

# Speak the product name
$info.Name | Send-ToVoiceGenerator
```

### Display Animations
```powershell
# Show clock animation
"/dev/ttyUSB0" | Show-TTYDisplayClockAnimation

# Show car animation
"/dev/ttyUSB0" | Show-TTYDisplayCarAnimation

# Show eye animation
"/dev/ttyUSB0" | Show-TTYDisplayEyeAnimation
```

### Keyboard Layout Management
```powershell
# Set Czech keyboard layout
Set-KeyboardLayout -Layout "CZ"

# Check current layout
Get-KeyboardLayout
```

## Module Structure

This repository contains two separate modules:

- `LinuxPSTools/`
  - `BarcodeInfo.psm1` - Product information lookup
  - `BarcodeScanner.psm1` - Barcode scanning functionality
  - `GigatekDisplay.psm1` - Serial display control
  - `VoiceGenerator.psm1` - Text-to-speech
  - `LinuxPsTools.psd1` - LinuxPsTools module manifest
- `BuildModule/`
  - `BuildTools.psm1` - Build automation functions
  - `UserInputTools.psm1` - Secure user input helpers
  - `SonarQube.psm1` - Sonar analysis tool functions
  - `BuildModule.psd1` - BuildModule manifest

## Hardware Requirements

### Barcode Scanner
- USB barcode scanner configured as keyboard wedge
- Supports both US and Czech keyboard layouts

### Serial Display
- Gigatek or Promag serial display
- Connected via USB-to-serial adapter (typically `/dev/ttyUSB0`)

### Audio
- Speech dispatcher (`spd-say`) for text-to-speech
- Default audio output device

## Troubleshooting

### Barcode Scanner Not Working
- Check device permissions: `ls -l /dev/input/by-id/`
- Ensure scanner is in keyboard wedge mode
- Try different keyboard layout: `Set-KeyboardLayout -Layout "CZ"`

### Display Not Responding
- Check serial port: `ls /dev/ttyUSB*`
- Verify device permissions
- Test connection: `echo "test" > /dev/ttyUSB0`

### Voice Not Working
- Install speech dispatcher: `sudo apt-get install speech-dispatcher`
- Test manually: `spd-say "test"`
- Check audio device

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is open source. See individual module files for license information.