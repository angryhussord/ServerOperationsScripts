#Install System Center Endpoint Protection
Write-Output "Installing System Center Endpoint Protection."
.\SCEPInstall.exe /S
Write-Output "Installation complete."

#Need to wait for .NET Optimization service, check to make sure it's running.
#Check if MsMpEng.exe is running
$count = 0;
while ((Get-Process -Name MsMpEng -ErrorAction:SilentlyContinue) -ne $null -and $count -lt 30) {
    Sleep -Seconds 10
    $count++;
}
if ($count -eq 50) {
    Write-Output "Couldn't verify that System Center Endpoint Protection is running. Please reboot the computer and perform a manual update of the definitions.";
    Exit;
} else {
    Write-Output "System Center Endpoint Protection is now running."
}

#Now, let's update the definitions for SCEP...
Write-Output "Updating System Center Endpoint Protection definitions..."
Import-Module “$env:ProgramFiles\Microsoft Security Client\MpProvider”;
Update-MProtSignature -UpdateSource MicrosoftUpdateServer;

Write-Output "Update complete, performing Quick Scan."
Start-MProtScan -ScanType QuickScan
Write-Output "Quick Scan complete."