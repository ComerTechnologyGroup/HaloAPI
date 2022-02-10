<#
    .SYNOPSIS
        Build script for HaloAPI module - uses 'Invoke-Build' https://github.com/nightroman/Invoke-Build
#>
Param (
    [String]$Configuration = 'Development'
)

#region Config: Use string mode when building.
Set-StrictMode -Version Latest
#endregion

#region Task: Update the PowerShell Module Help Files.
# Pre-requisites: PowerShell Module PlatyPS.
task UpdateHelp {
    Import-Module -Name 'HaloAPI' -Force
    Update-MarkdownHelp -Path "$($PSScriptRoot)\Docs\Markdown"
    New-ExternalHelp -Path "$($PSScriptRoot)\Docs\Markdown" -OutputPath "$($PSScriptRoot)\Docs\en_GB" -Force
}
#endregion

#region Task: Copy PowerShell Module files to output folder for release on PSGallery
task CopyModuleFiles {
    # Copy Module Files to Output Folder
    if (-not (Test-Path "$($PSScriptRoot)\Output\HaloAPI")) {
        New-Item -Path "$($PSScriptRoot)\Output\HaloAPI" -ItemType Directory | Out-Null
    }
    Copy-Item -Path "$($PSScriptRoot)\Classes\" -Filter *.* -Recurse -Destination "$($PSScriptRoot)\Output\HaloAPI" -Force
    Copy-Item -Path "$($PSScriptRoot)\Data\" -Filter *.* -Recurse -Destination "$($PSScriptRoot)\Output\HaloAPI" -Force
    Copy-Item -Path "$($PSScriptRoot)\Private\" -Filter *.* -Recurse -Destination "$($PSScriptRoot)\Output\HaloAPI" -Force
    Copy-Item -Path "$($PSScriptRoot)\Public\" -Filter *.* -Recurse -Destination "$($PSScriptRoot)\Output\HaloAPI" -Force

    #Copy Module Manifest files
    Copy-Item -Path @(
        "$($PSScriptRoot)\LICENSE.md"
        "$($PSScriptRoot)\CHANGELOG.md"
        "$($PSScriptRoot)\README.md"
        "$($PSScriptRoot)\HaloAPI.psd1"
        "$($PSScriptRoot)\HaloAPI.psm1"
    ) -Destination "$($PSScriptRoot)\Output\HaloAPI" -Force
}
#endregion

#region Task: Run all Pester tests in folder .\Tests
task Test {
    $Result = Invoke-Pester "$($PSScriptRoot)\Tests" -PassThru
    if ($Result.FailedCount -gt 0) {
        throw 'Pester tests failed'
    }
}
#endregion

#region Task: Update the Module Manifest file with info from the Changelog.
task UpdateManifest {
    # Import PlatyPS. Needed for parsing the versions in the Changelog.
    Import-Module -Name PlatyPS

    # Find Latest Version in Change log.
    $CHANGELOG = Get-Content -Path "$($PSScriptRoot)\CHANGELOG.md"
    $MarkdownObject = [Markdown.MAML.Parser.MarkdownParser]::new()
    [regex]$Regex = '\d\.\d\.\d'
    $Versions = $Regex.Matches($MarkdownObject.ParseString($CHANGELOG).Children.Spans.Text) | ForEach-Object { $_.Value }
    $ChangeLogVersion = ($Versions | Measure-Object -Maximum).Maximum

    $ManifestPath = "$($PSScriptRoot)\HaloAPI.psd1"

    # Start by importing the manifest to determine the version, then add 1 to the Build
    $Manifest = Test-ModuleManifest -Path $ManifestPath
    [System.Version]$Version = $Manifest.Version

    if ($ChangeLogVersion -eq $Version) {
        Throw 'No new version found in CHANGELOG.md'
    }

    Write-Output -InputObject ("Current Module Version: $($Version)")
    Write-Output -InputObject ("New Module version: $($ChangeLogVersion)")

    # Update Manifest file with Release Notes
    $CHANGELOG = Get-Content -Path "$($PSScriptRoot)\CHANGELOG.md"
    $MarkdownObject = [Markdown.MAML.Parser.MarkdownParser]::new()
    $ReleaseNotes = ((($MarkdownObject.ParseString($CHANGELOG).Children.Spans.Text) -Match '\d\.\d\.\d') -Split ' - ')[1]

    #Update Module with new version
    Update-ModuleManifest -ModuleVersion $ChangeLogVersion -Path "$($PSScriptRoot)\HaloAPI.psd1" -ReleaseNotes $ReleaseNotes
}
#endregion

#region Task: Publish Module to PowerShell Gallery
task PublishModule -if ($Configuration -eq 'Production') {
    Try {
        # Build a splat containing the required details and make sure to Stop for errors which will trigger the catch
        $params = @{
            Path = ("$($PSScriptRoot)\Output\HaloAPI")
            NuGetApiKey = $env:PSGalleryAPI
            ErrorAction = 'Stop'
        }
        $ManifestPath = "$($PSScriptRoot)\HaloAPI.psd1"
        $Manifest = Test-ModuleManifest -Path $ManifestPath
        [System.Version]$Version = $Manifest.Version
        Publish-Module @params
        Write-Output -InputObject ("HaloAPI PowerShell Module version $($Version) published to the PowerShell Gallery")
    } Catch {
        Throw $_
    }
}
#endregion

#region Task: Clean up Output folder
task Clean {
    # Clean output folder
    if ((Test-Path "$($PSScriptRoot)\Output")) {
        Remove-Item -Path "$($PSScriptRoot)\Output" -Recurse -Force
    }
}
#endregion

#region Default Task. Runs Clean, Test, CopyModuleFiles Tasks
task . Clean, Test, CopyModuleFiles, PublishModule, Clean
#endregion