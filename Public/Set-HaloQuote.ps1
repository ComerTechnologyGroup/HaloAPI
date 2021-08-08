Function Set-HaloQuote {
    <#
    .SYNOPSIS
        Updates a Quote via the Halo API.
    .DESCRIPTION
        Function to send a Quote creation update to the Halo API
    .OUTPUTS
        Outputs an object containing the response from the web request.
    #>
    [CmdletBinding()]
    Param (
        [Parameter( Mandatory = $True )]
        [PSCustomObject]$Quote
    )
    Invoke-HaloUpdate -Object $Quote -Endpoint "Quotation" -update
}