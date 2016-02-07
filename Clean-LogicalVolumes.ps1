#This code snippet and function should remove any logical drives other than 0, which should be the C: drive
#before making this available in any sort of script, you'll want to add some safeguards/logging to record
#who is using this script...don't rely on the user...pull their ms-mla-* account and write it to the log.

function Remove-LogicalVolume ($LD) {
	#Build the diskpart command
	$command = "
	select disk $LD
	select partition 1
	delete partition override
	"
	
	#run the diskpart script to remove the volume
	$command | diskpart | Out-Null
} #Remove-LogicalVolume

$mounted_dbs = Get-MailboxDatabaseCopyStatus | Where {$_.Status -eq "Mounted"}
if ($mounted_dbs -ne $null) {
	Write-Host "This script has detected Mounted database copies on this server."
	Write-Host "To prevent possible data loss, this script is ending early."
	Write-Host "Please move any Mounted copies off of this server before re-running this script."
	Exit 1
}

$LD = 0
$volumes = @()
$result = ("select disk $LD" | diskpart)[6].Split(" ")[1]
while ($result -ne "disk") {
	$volumes += $result
	$LD++
	$result = ("select disk $LD" | diskpart)[6].Split(" ")[1]
}

#disk 0 is always the C: drive, so we can delete the rest of them
foreach ($vol in $volumes) {
	if ($vol -ne 0) {
		Remove-LogicalVolume $vol | Out-Null
		Write-Host "Removed Logical Volume $vol"
	}
}