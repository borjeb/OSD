<#  GARY BLOK - RecastSoftware.com @gwblok
2022.02.15

Update PowerShellGet and PackageManagement
#>

$WorkingDir = $env:TEMP
$dist = 'C:\Program Files'

#PowerShellGet from PSGallery URL
if (!(Get-Module -Name PowerShellGet)){
    $PowerShellGetURL = "https://psg-prod-eastus.azureedge.net/packages/powershellget.2.2.5.nupkg"
    Invoke-WebRequest -UseBasicParsing -Uri $PowerShellGetURL -OutFile "$WorkingDir\powershellget.2.2.5.zip"
    $Null = New-Item -Path "$WorkingDir\2.2.5" -ItemType Directory -Force
    Expand-Archive -Path "$WorkingDir\powershellget.2.2.5.zip" -DestinationPath "$WorkingDir\2.2.5"
    $Null = New-Item -Path "$dist\WindowsPowerShell\Modules\PowerShellGet" -ItemType Directory -ErrorAction SilentlyContinue
    Move-Item -Path "$WorkingDir\2.2.5" -Destination $dist\WindowsPowerShell\Modules\PowerShellGet\2.2.5"
    Remove-Item -Path "$dist\WindowsPowerShell\Modules\PowerShellGet\1.0.0.1" -Recurse -force
    }

#PackageManagement from PSGallery URL
if (!(Get-Module -Name PackageManagement)){
    $PackageManagementURL = "https://psg-prod-eastus.azureedge.net/packages/packagemanagement.1.4.8.1.nupkg"
    Invoke-WebRequest -UseBasicParsing -Uri $PackageManagementURL -OutFile "$WorkingDir\packagemanagement.1.4.8.1.zip"
    $Null = New-Item -Path "$WorkingDir\1.4.8.1" -ItemType Directory -Force
    Expand-Archive -Path "$WorkingDir\packagemanagement.1.4.8.1.zip" -DestinationPath "$WorkingDir\1.4.8.1"
    $Null = New-Item -Path "$dist\WindowsPowerShell\Modules\PackageManagement" -ItemType Directory -ErrorAction SilentlyContinue
    Move-Item -Path "$WorkingDir\1.4.8.1" -Destination "$dist\WindowsPowerShell\Modules\PackageManagement\1.4.8.1"
    }
    
#PSReadline from PSGallery URL
if (!(Get-Module -Name PSReadline)){
    $PSReadlineURL = "https://psg-prod-eastus.azureedge.net/packages/psreadline.2.3.4.nupkg"
    Invoke-WebRequest -UseBasicParsing -Uri $PSReadlineURL -OutFile "$WorkingDir\psreadline.2.3.4.zip"
    $Null = New-Item -Path "$WorkingDir\2.3.4" -ItemType Directory -Force
    Expand-Archive -Path "$WorkingDir\psreadline.2.3.4.zip" -DestinationPath "$WorkingDir\2.3.4"
    $Null = New-Item -Path "$dist\WindowsPowerShell\Modules\PSReadline" -ItemType Directory -ErrorAction SilentlyContinue
    Move-Item -Path "$WorkingDir\2.3.4" -Destination "$dist\WindowsPowerShell\Modules\PSReadline\2.3.4"
    }
