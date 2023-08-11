<# Control Windows Update via PowerShell
Gary Blok - GARYTOWN.COM
NOTE: I'm using this in a RUN SCRIPT, so I hav the Parameters set to STRING, and in the RUN SCRIPT, I Create a list of options (TRUE & FALSE).
In a normal script, you wouldn't do this... so modify for your deployment method.

This was also intended to be used with ConfigMgr, if you're not, feel free to remove the $CMReboot & Corrisponding Function

Installing Updates using this Method does NOT notify the user, and does NOT let the user know that updates need to be applied at the next reboot.  It's 100% hidden.

HResult Lookup: https://docs.microsoft.com/en-us/windows/win32/wua_sdk/wua-success-and-error-codes-

#>
[CmdletBinding()]
    Param (
            [Parameter(Mandatory=$false)][string]$InstallUpdates = "TRUE"
	    )


function Confirm-TSProgressUISetup(){
    if ($Script:TaskSequenceProgressUi -eq $null){
        try{$Script:TaskSequenceProgressUi = New-Object -ComObject Microsoft.SMS.TSProgressUI}
        catch{throw "Unable to connect to the Task Sequence Progress UI! Please verify you are in a running Task Sequence Environment. Please note: TSProgressUI cannot be loaded during a prestart command.`n`nErrorDetails:`n$_"}
        }
    }

function Confirm-TSEnvironmentSetup(){
    if ($Script:TaskSequenceEnvironment -eq $null){
        try{$Script:TaskSequenceEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment}
        catch{throw "Unable to connect to the Task Sequence Environment! Please verify you are in a running Task Sequence Environment.`n`nErrorDetails:`n$_"}
        }
    }

function Show-TSActionProgress(){

    param(
        [Parameter(Mandatory=$true)]
        [string] $Message,
        [Parameter(Mandatory=$true)]
        [long] $Step,
        [Parameter(Mandatory=$true)]
        [long] $MaxStep
    )

    Confirm-TSProgressUISetup
    Confirm-TSEnvironmentSetup

    $Script:TaskSequenceProgressUi.ShowActionProgress(`
        $Script:TaskSequenceEnvironment.Value("_SMSTSOrgName"),`
        $Script:TaskSequenceEnvironment.Value("_SMSTSPackageName"),`
        $Script:TaskSequenceEnvironment.Value("_SMSTSCustomProgressDialogMessage"),`
        $Script:TaskSequenceEnvironment.Value("_SMSTSCurrentActionName"),`
        [Convert]::ToUInt32($Script:TaskSequenceEnvironment.Value("_SMSTSNextInstructionPointer")),`
        [Convert]::ToUInt32($Script:TaskSequenceEnvironment.Value("_SMSTSInstructionTableSize")),`
        $Message,`
        $Step,`
        $MaxStep)
}

$Results = @(
@{ ResultCode = '0'; Meaning = "Not Started"}
@{ ResultCode = '1'; Meaning = "In Progress"}
@{ ResultCode = '2'; Meaning = "Succeeded"}
@{ ResultCode = '3'; Meaning = "Succeeded With Errors"}
@{ ResultCode = '4'; Meaning = "Failed"}
@{ ResultCode = '5'; Meaning = "Aborted"}
)



$WUDownloader=(New-Object -ComObject Microsoft.Update.Session).CreateUpdateDownloader()
$WUInstaller=(New-Object -ComObject Microsoft.Update.Session).CreateUpdateInstaller()
$WUUpdates=New-Object -ComObject Microsoft.Update.UpdateColl
((New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsInstalled=0 and Type='Software'")).Updates|%{
    if(!$_.EulaAccepted){$_.EulaAccepted=$true}
    if ($_.Title -notmatch "Preview"){[void]$WUUpdates.Add($_)}
}

if ($WUUpdates.Count -ge 1){
    if ($InstallUpdates -eq "TRUE"){
        $WUInstaller.ForceQuiet=$true
        $WUInstaller.Updates=$WUUpdates
        $WUDownloader.Updates=$WUUpdates
        $UpdateCount = $WUDownloader.Updates.count
        Write-Output "Downloading $UpdateCount Updates"
        Show-TSActionProgress -Message "Downloading $UpdateCount Updates" -Step 1 -MaxStep 3 -ErrorAction SilentlyContinue
        foreach ($update in $WUInstaller.Updates){Write-Output "$($update.Title)"}
        $Download = $WUDownloader.Download()
        if ($Download.HResult -ne 0){
            $Convert = $Install.HResult
            $Hex = [System.Convert]::ToString($Convert, 16)
            $Hex = $Hex.Replace("ffffffff","0x")
            Write-Output "Download HResult HEX: $Hex"

        }
        $InstallUpdateCount = $WUInstaller.Updates.count
        Write-Output "Installing $InstallUpdateCount Updates"
        Show-TSActionProgress -Message "Installing $InstallUpdateCount Updates" -Step 2 -MaxStep 3 -ErrorAction SilentlyContinue
        $Install = $WUInstaller.Install()
        $ResultMeaning = ($Results | Where-Object {$_.ResultCode -eq $Install.ResultCode}).Meaning
        Write-Output "Result: $ResultMeaning"
        if ($Install.HResult -ne 0){
            $Convert = $Install.HResult
            $Hex = [System.Convert]::ToString($Convert, 16)
            $Hex = $Hex.Replace("ffffffff","0x")
            Write-Output "Install HResult HEX: $Hex"

        }
        if ($Install.RebootRequired -eq $true){
            Write-Output "Updates Require Restart"
        }
    }
    else
        {
        Write-Output "Available Updates:"
        foreach ($update in $WUUpdates){Write-Output "$($update.Title)"}
     }
} 
else {
    write-Output "No updates detected"
}
