#cmtrace x:\windows\temp\smstslog\smsts.log
Write-Output "--------------------------------------"
Write-Output ""
Write-Output "OSDCloud Apply OS Step"
Write-Output ""
#Set OSDCloud Params
$OSName = "Windows 11 23H2 x64"
Write-Output "OSName: $OSName"
$OSEdition = "Pro"
Write-Output "OSEdition: $OSEdition"
$OSActivation = "Retail"
Write-Output "OSActivation: $OSActivation"
$OSLanguage = "nb-no"
Write-Output "OSLanguage: $OSLanguage"

$Global:MyOSDCloud = [ordered]@{
        Restart = [bool]$False
        RecoveryPartition = [bool]$True
        SkipAllDiskSteps = [bool]$True
        #DriverPackName = "None"
        SkipAutopilot = $true
        SkipODT = $true
        LaunchMethod = "OSDCloudCLI"
    }

Write-Output "Global:MyOSDCloud"
$Global:MyOSDCloud

#Update Files in Module that have been updated since last PowerShell Gallery Build (Testing Only)
$ModulePath = (Get-ChildItem -Path "$($Env:ProgramFiles)\WindowsPowerShell\Modules\osd" | Where-Object {$_.Attributes -match "Directory"} | select -Last 1).fullname
import-module "$ModulePath/OSD.psd1" -Force

#Launch OSDCloud
Write-Output "Launching OSDCloud"
Write-Output ""
Write-Output "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
Write-Output ""
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
Write-Output ""
Write-Output "--------------------------------------"

#================================================
#   WinPE PostOS Sample
#   Set AutopilotOOBE JSON
#================================================
$AutopilotOOBEJson = @'
{
    "Assign":  {
                   "IsPresent":  true
               },
    "GroupTag":  "Standard",
    "GroupTagOptions":  [
                            "Utvikling",
                            "Standard",
                            "Shared",
                            "Kiosk",
                            "Frontline",
                            "Vakt",
                            "PAW"
                        ],
    "Hidden":  [
                   "AddToGroup",
                   "AssignedComputerName",
                   "AssignedUser",
                   "PostAction"
               ],
    "PostAction":  "Restart",
    "Run":  "NetworkingWireless",
    "Docs":  "https://autopilotoobe.osdeploy.com/",
    "Title":  "Stortinget Autopilot Registrering"
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

$Params = @{
    Title = 'Stortinget Autopilot Registrering'
    GroupTag = 'Standard'
    GroupTagOptions = 'Utvikling','Standard'
    Hidden = 'AddToGroup','AssignedComputerName','AssignedUser'
    Assign = $true
    Run = 'NetworkingWireless'
    PostAction = 'Restart'
    Disabled = 'Assign','GroupTag'
}
#AutopilotOOBE @Params
#================================================
#   WinPE PostOS Sample
#   OOBEDeploy Offline Staging
#================================================
$Params = @{
    Autopilot = $true
    RemoveAppx = "CommunicationsApps","OfficeHub","People","Skype","Solitaire","Xbox","ZuneMusic","ZuneVideo"
    UpdateDrivers = $true
    UpdateWindows = $true
}
#Start-OOBEDeploy @Params
#================================================
#   WinPE PostOS
#   Set OOBEDeploy CMD.ps1
#================================================
$SetCommand = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts

:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi

:: Install the latest OSD Module
start "Install-Module OSD" /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose

:: Start-OOBEDeploy
:: There are multiple example lines. Make sure only one is uncommented
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json
REM start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy
:: The next line assumes that you do not have a configuration saved in or want to ensure that these are applied
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy -AddNetFX3 -UpdateDrivers -UpdateWindows -Autopilot -RemoveAppx "CommunicationsApps","OfficeHub","People","Skype","Solitaire","Xbox","ZuneMusic","ZuneVideo"

exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Force
#================================================
#   WinPE PostOS
#   Set AutopilotOOBE CMD.ps1
#================================================
$SetCommand = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts

:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi

:: Install the latest AutopilotOOBE Module
start "Install-Module AutopilotOOBE" /wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose

:: Start-AutopilotOOBE
:: There are multiple example lines. Make sure only one is uncommented
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json
start "Start-AutopilotOOBE" PowerShell -NoL -C Start-AutopilotOOBE
:: The next line is how you would apply a CustomProfile
REM start "Start-AutopilotOOBE" PowerShell -NoL -C Start-AutopilotOOBE -CustomProfile OSDeploy
:: The next line is how you would configure everything from the command line
REM start "Start-AutopilotOOBE" PowerShell -NoL -C Start-AutopilotOOBE -Title 'OSDeploy Autopilot Registration' -GroupTag Enterprise -GroupTagOptions Development,Enterprise -Assign

exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\Autopilot.cmd" -Encoding ascii -Force
#================================================
#   PostOS
#   Restart-Computer
#================================================
#Get-Process cmtrace |Stop-Process
