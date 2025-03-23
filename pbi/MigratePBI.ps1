<#
.NOTES
    File Name: MigratePBI.ps1
    Author: Javier Buendía
.SYNOPSIS 
    Moving reports from Power BI Report Server or Power BI Desktop previous versions.
.DESCRIPTION
    This script builds a new report using a template and recycles the visual content of the previous file as follows:
        1. Convert .pbix files to .zip files
        2. Modifiy the .zip content, deleting everything except the “Report” folder
        4. Copy files from the template folder to the .zip file (excluding the Report folder)
        5. Convert the .zip files to .pbix files
        6. Upload the .pbix files to the Power BI destination workspace
#>

# Variables

# Power BI files path
$libPath = Read-Host -Prompt "Please enter the path to Power BI files: "
# Template file path
$templatePath = Read-Host -Prompt "Please enter the path to the template file: "
# Power BI workspace name
$workspaceName = Read-Host -Prompt "Please enter Power BI workspace name: "

$pbixFiles = Get-ChildItem -Path $libPath -Filter "*.pbix"

# Iterating over the .pbix files
foreach ($pbixFile in $pbixFiles) 
{

    # .pbix a .zip
    [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression')
    $zipPath = "$libPath\$($pbixFile.BaseName).zip"
    Rename-Item -Path $pbixFile.FullName -NewName $zipPath

    # Open the .zip file
    $stream = New-Object IO.FileStream($zipPath, [IO.FileMode]::Open)
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Update)

    # We make a list of the entries (we should use a list because .Entries is read-only)
    $zipEntries = @($zip.Entries)

    # Delete zip entries except "Report" folder
    foreach ($entry in $zipEntries) 
    {
        if ($entry.FullName -notlike "Report/*" -and $entry.FullName -ne "Report") 
        {
            $entry.Delete()
        }
    }

    # Copy files from the template to the .zip file, except "Report" folder
    $itemsToCopy = Get-ChildItem -Path $templatePath -Recurse | Where-Object {
        $_.FullName -notlike "*\Report*" -and -not $_.PsIsContainer
    }

    foreach ($item in $itemsToCopy) 
    {
        $destinationPath = $item.Name
        $entry = $zip.GetEntry($destinationPath)

        # Delete entry if it already exists
        if ($entry) 
        {
            $entry.Delete()
        }

        # Create new zip entry
        $entry = $zip.CreateEntry($destinationPath)
        $entryStream = $entry.Open()

        # Copy files from the template to the .zip file
        $itemStream = [System.IO.File]::OpenRead($item.FullName)
        $itemStream.CopyTo($entryStream)
        $itemStream.Close()

        # Close zip entry
        $entryStream.Close()
    }

    # Close zip file
    $zip.Dispose()
    $stream.Close()

    # .zip to .pbix
    $pbixFinalPath = "$libPath\$($pbixFile.BaseName).pbix"
    Rename-Item -Path $zipPath -NewName $pbixFinalPath
}

# PUBLISHING TO POWER BI
# Connect to Power BI
Connect-PowerBIServiceAccount

# Get the Power BI workspace GUID
$workspace = Get-PowerBIWorkspace -Name $workspaceName

# Iterating over the .pbix files
foreach ($pbixFile in $pbixFiles) 
{
    # Get path and report name
    $pbixFilePath = Join-Path -Path $libPath -ChildPath $pbixFile.Name
    $reportName = [System.IO.Path]::GetFileNameWithoutExtension($pbixFile.Name)
    
    # Publish the report
    New-PowerBIReport -Path $pbixFilePath -Name $reportName -Workspace $workspace
}