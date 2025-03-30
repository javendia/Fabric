<#
.SYNOPSIS 
    Migration of reports from Power BI Report Server or previous versions of Power BI.
.DESCRIPTION
    This script recycles the visual content of the previous file as follows:
        1. Create a folder for each report to process
        2. Convert .pbix file to Power BI project (.pbip)
        3. Upload the report to the Power BI destination workspace, binding to the desired semantic model
#>

# Variables

# Power BI files path
$libPath = Read-Host -Prompt "Please enter the path to Power BI files"
# Power BI workspace name
$workspaceName = Read-Host -Prompt "Please enter the Power BI workspace name"
# Power BI semantic model
$semanticModelId = Read-Host -Prompt "Please enter the Power BI semantic model GUID"

# Download modules and install
New-Item -ItemType Directory -Path ".\modules" -ErrorAction SilentlyContinue | Out-Null
@("https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1"
, "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1") |% {
    Invoke-WebRequest -Uri $_ -OutFile ".\modules\$(Split-Path $_ -Leaf)"
}
if (-not (Get-Module Az.Accounts -ListAvailable)) { 
    Install-Module Az.Accounts -Scope CurrentUser -Force
}
Import-Module ".\modules\FabricPS-PBIP" -Force

# Authenticate
Set-FabricAuthToken -reset

$pbixFiles = Get-ChildItem -Path $libPath -Filter "*.pbix"

# Iterating over the .pbix files
foreach ($pbixFile in $pbixFiles) 
{
    $fileName = $pbixFile.BaseName
    $path = "$($libPath)\$($fileName)"
    
    If(!(test-path -PathType container $path))
    {
          New-Item -ItemType Directory -Path $path
    }

    $source = "$($libPath)\$($fileName).pbix"
    $destination =  "$($libPath)\$($fileName)\$($fileName).pbix"

    Move-Item -Path $source -Destination $destination

    Start-Process -filePath $destination

    $pbipReportPath = "$($path)\$($fileName).Report"

    $default = 1
    do {
        $response = Read-Host -Prompt "Did you save the file as PBIP? (Press Y to continue)"
        if ($response -eq 'Y') {
            if (Test-Path -Path $pbipReportPath) {
                $default = 0
            }
        }
    } while ($default -eq 1)

    # Ensure workspace exists
    $workspaceId = New-FabricWorkspace  -name $workspaceName -skipErrorIfExists

    # Import the report and ensure its binded to the previous imported report
    Import-FabricItem -workspaceId $workspaceId -path $pbipReportPath -itemProperties @{"semanticModelId" = $semanticModelId}
}