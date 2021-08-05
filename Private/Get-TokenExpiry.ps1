#Requires -Version 7
function Get-TokenExpiry {
    <#
    .SYNOPSIS
        Calculates and returns the expiry date/time of a Halo token.
    .DESCRIPTION
        Takes the expires in time for an auth token and returns a PowerShell date/time object containing the expiry date/time of the token.
    .OUTPUTS
        A powershell date/time object representing the token expiry.
    #>
    [CmdletBinding()]
    param (
        # Timestamp value for token expiry. e.g 3600
        [Parameter(
            Mandatory = $True
        )]
        [int64]$ExpiresIn
    )
    $Now = Get-Date
    $TimeZone = Get-TimeZone
    $UTCTime = $Now.AddMilliseconds($ExpiresIn)
    $UTCOffset = $TimeZone.GetUtcOffset($(Get-Date)).TotalMinutes
    $ExpiryDateTime = $UTCTime.AddMinutes($UTCOffset)
    Write-Verbose "Calcuated token expiry as $($ExpiryDateTime.ToString())"
    Return $ExpiryDateTime
}