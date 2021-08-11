Function Set-HaloKBArticle {
    <#
    .SYNOPSIS
        Updates a knowledgebase article via the Halo API.
    .DESCRIPTION
        Function to send an knowledgebase article update request to the Halo API
    .OUTPUTS
        Outputs an object containing the response from the web request.
    #>
    [CmdletBinding()]
    Param (
        # Object containing properties and values used to update an existing knowedgebase article.
        [Parameter( Mandatory = $True )]
        [PSCustomObject]$KBArticle
    )
    Invoke-HaloUpdate -Object $KBArticle -Endpoint "kbarticle" -Update
}