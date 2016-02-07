<######
Test-EWS.ps1
By Jason Barbier (v-jasonb@microsoft.com)

.Description
    This script is to test EWS and will do so by connecting to a users mailbox over EWS and
    pull a count of all items in their Inbox and the first 10 subjects.

    Please note this script requires the EWS managed API DLLs to be in the same location as the script.

.Parameter Mailbox
    This is the primary SMTP address of the mailbox you wish to test against

.Parameter Credential
    This is the credentials that have access to read the mailbox provided by Mailbox

.Parameter EWSUrl
    This is the EWS URL you wish to test. This is optional and if you do not supply it
    autodiscover based off the primary smtp address will be used.

.Parameter DefaultCreds
    This switch is used to supply the credentials taken from the session you are currently logged
    on to.


######>

Param (
$Mailbox = $null,
$Credential = $null,
$EWSUrl = $null,
[switch]$DefaultCreds
)

Import-Module -Name ".\Microsoft.Exchange.WebServices.dll"

try{
    $EWS = new-object Microsoft.Exchange.WebServices.Data.ExchangeService

    # Configure and connect to EWS
    if ($mailbox -eq $null){
        $mailbox = read-host "Please enter a valid Primary SMTP address"
    }
    if ($DefaultCreds -eq $true){
        $EWS.UseDefaultCredentials = $true
    }
    else{
        if ($Credential -eq $null){
            $Credential = Get-Credential
            $EWS.Credentials = new-object Microsoft.Exchange.WebServices.Data.WebCredentials($Credential)
        }
        else {
            $EWS.Credentials = new-object Microsoft.Exchange.WebServices.Data.WebCredentials.GetNetworkCredential($Credential)
            
        }
    }

    if ($EWSUrl -eq $null){
        Write-Host -ForegroundColor Yellow "No EWS location Provided, attempting AutoDiscover"
        $EWS.AutoDiscoverURL($mailbox);
        write-host -ForegroundColor Green "Found EWS at:" $EWS.Url.AbsoluteUri
    }
    else{
        $EWS.Url = $EWSUrl
    }

    # Find the Inbox of the user and bind to it.
    $inboxid = new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox,$mailbox) 
    $Inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($EWS,$inboxid)

    #Poll all of the Items in the inbox folder
    $iview = New-Object Microsoft.Exchange.WebServices.Data.ItemView(1000)
    $fiResult = $Inbox.FindItems($iview)
    
    #Output Results
    $fiResult|select -First 10 |ft -AutoSize Subject
    $items = $mailbox+"'s "+$Inbox.DisplayName+" contains "+$Inbox.TotalCount+" items"
    $items
}

#Catch and handle all Exceptions
catch{
Write-Error $_.Exception
}