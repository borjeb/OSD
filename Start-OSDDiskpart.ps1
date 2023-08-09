function Start-OSDDiskPart {
    [CmdletBinding()]
    param ()
#=================================================
#	DiskPart Script TXT
#=================================================
$DiskPartScript = @'
list volume
select disk 0
clean
convert gpt
create partition EFI size=496
assign letter=S
format fs=fat32 quick label=System
create partition MSR size=128
create partition PRIMARY
format fs=ntfs quick label=Windows
assign letter=C
rescan
list partition  
select partition 3  
shrink desired=984 minimum=984  
create partition primary  
format quick fs=ntfs label=Recovery  
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"  
gpt attributes=0x8000000000000001  
list partition  
exit 
'@

    $DiskPartPath = "$env:TEMP\DiskPartScript.txt"

    Write-Verbose "Creating $DiskPartPath "
    $DiskPartScript | Out-File -FilePath $DiskPartPath -Encoding utf8 -Width 2000 -Force
    Write-Host "Running DiskPart"
    &X:\Windows\System32\DiskPart.exe /s $DiskPartPath
    Get-Partition
    Get-Volume
    #=================================================
}
Start-OSDDiskPart
