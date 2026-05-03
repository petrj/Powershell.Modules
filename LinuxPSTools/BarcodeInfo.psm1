function Get-BarcodeInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
        [string]$Barcode
    )

    $url = "https://world.openfoodfacts.org/api/v0/product/$Barcode.json"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop

        if ($response.status -ne 1) {
            return [PSCustomObject]@{
                Barcode = $Barcode
                Found   = $false
                Message = "Product not found"
            }
        }

        $p = $response.product

        return [PSCustomObject]@{
            Barcode    = $Barcode
            Found      = $true
            Name       = $p.product_name
            Brand      = ($p.brands -split ",")[0]
            Category   = $p.categories
            Quantity   = $p.quantity
            Image      = $p.image_url
            NutriScore = $p.nutriscore_grade
            Countries  = $p.countries
        }

    } catch {
        return [PSCustomObject]@{
            Barcode = $Barcode
            Found   = $false
            Error   = $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Get-BarcodeInfo