#Get-LockedOutUser2.ps1

function Get-FSMORoleOwners () {
    $domain_owners = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain();
    $forest_owners = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest();
    $owners = New-Object PSObject;
    Add-Member -InputObject $owners -MemberType NoteProperty -Name PDCEmulator -Value $domain_owners.PdcRoleOwner;
    Add-Member -InputObject $owners -MemberType NoteProperty -Name RIDMaster -Value $domain_owners.RidRoleOwner;
    Add-Member -InputObject $owners -MemberType NoteProperty -Name InfrastructureMaster -Value $domain_owners.InfrastructureRoleOwner;
    Add-Member -InputObject $owners -MemberType NoteProperty -Name SchemaMaster -Value $forest_owners.SchemaRoleOwner;
    Add-Member -InputObject $owners -MemberType NoteProperty -Name DomainNamingMaster -Value $forest_owners.NamingRoleOwner;
    return $owners;
}

$events = Get-WinEvent -computername (Get-FSMORoleOwners).PDCEmulator -filterhashtable @{Id=4740;logname='security'} | select message
$caller = $events[0] | Select-String -SimpleMatch "Caller Computer Name:";
$LockoutSourceDC = $caller.Split(":")[1].TrimStart();
$lockoutevents = Get-WinEvent -computername $LockoutSourceDC -filterhashtable @{Id=4625;logname='security'} | select message;