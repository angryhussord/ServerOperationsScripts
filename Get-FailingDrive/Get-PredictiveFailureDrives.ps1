#Find predictive failure drives

$drives = Get-WmiObject -namespace root\wmi –class MSStorageDriver_FailurePredictStatus
$results = @();
foreach ($drive in $drives) {
    $result = New-Object PSObject;
    $result | Add-Member -MemberType NoteProperty -Name Vendor -Value ($drive.InstanceName.Split("\")[1].Split("&")[1].Substring(4))
    $result | Add-Member -MemberType NoteProperty -Name Model -Value ($drive.InstanceName.Split("\")[1].Split("&")[2].Split("_")[1])
    $result | Add-Member -MemberType NoteProperty -Name Active -Value ($drive.Active)
    $result | Add-Member -MemberType NoteProperty -Name PredictiveFailure -Value ($drive.PredictFailure)
    $results += $result;
}
$results | ft