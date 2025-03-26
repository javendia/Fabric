<#
.SYNOPSIS 
    Migration of reports from Power BI Report Server or previous versions of Power BI.
.DESCRIPTION
    This script recycles the visual content of the previous file as follows:
        1. Create a folder for each report to process
        2. Convert .pbix file to Power BI project (.pbip)
        3. Upload the .pbix files to the Power BI destination workspace, binding to the desired semantic model
#>

# Variables

# Power BI files path
$libPath = Read-Host -Prompt "Please enter the path to Power BI files: "
# Power BI workspace name
$workspaceName = Read-Host -Prompt "Please enter Power BI workspace name: "

# Download modules and install
New-Item -ItemType Directory -Path ".\modules" -ErrorAction SilentlyContinue | Out-Null
@("https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1"
, "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1") |% {
    Invoke-WebRequest -Uri $_ -OutFile ".\modules\$(Split-Path $_ -Leaf)"
}
if(-not (Get-Module Az.Accounts -ListAvailable)) { 
    Install-Module Az.Accounts -Scope CurrentUser -Force
}
if(-not (Get-Module PBIXtoPBIP_PBITConversion -ListAvailable)) { 
    Install-Module PBIXtoPBIP_PBITConversion -Scope CurrentUser -Force
}
Import-Module ".\modules\FabricPS-PBIP" -Force

# Authenticate
Set-FabricAuthToken -reset

$pbixFiles = Get-ChildItem -Path $libPath -Filter "*.pbix"

# Iterating over the .pbix files
foreach ($pbixFile in $pbixFiles) 
{
    $path = $libPath + "\" + $pbixFile.BaseName
    If(!(test-path -PathType container $path))
    {
          New-Item -ItemType Directory -Path $path
    }

    $source = $libPath + "\" + "$($pbixFile.BaseName).pbix"
    $destination =  $libPath + "\" + $pbixFile.BaseName + "\" + "$($pbixFile.BaseName).pbix"

    Move-Item -Path $source -Destination $destination

    PBIXtoPBIP_PBITConversion -PBIXFilePath $destination -ConversionFileType "pbip"

    $pbipReportPath = "$($path)\$($pbixFile.BaseName).Report"

    # Ensure workspace exists
    $workspaceId = New-FabricWorkspace  -name $workspaceName -skipErrorIfExists

    # Import the report and ensure its binded to the previous imported report
    Import-FabricItem -workspaceId $workspaceId -path $pbipReportPath -itemProperties @{"semanticModelId" = $semanticModelId}
}