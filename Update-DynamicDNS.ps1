<#
 .SYNOPSIS
    Updates dynamic DNS records for Zone Edit.
 .DESCRIPTION
    Automatically finds your externally facing IP using the DomainTools.com service. Then connects to the Dynamic DNS API
    and updates Zone Edit records. It requires you username and password to be able to securely update dynamic records with
    your current IP address. This script is meant to be run as a scheduled task at a frequency of your choice. Ideally, it'd
    match the frequency of updates to TTL on the record to make sure it's up-to-date all the time.
 .PARAMETER Record
    The name of the record being updated.
    This parameter is required.
 .PARAMETER Username
    Your ZoneEdit.com username. Required to login to the API to allow the DNS changes to occur.
    This parameter is required.
 .PARAMETER Password
    Your ZoneEdit.com password. Required to login to the API to allow the DNS changes to occur.
    This parameter is required.
 .EXAMPLE
    .\Update-DynamicDNS.ps1 -Record "labs.hufford.org" -Username your_name -Password your_password

 Copyright (c) Patrick Hufford. All rights reserved.
 THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
 OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true,
               Position=0,
               HelpMessage="The record being updated.")]
    [ValidateNotNull()]
    [string] $Record,

    [Parameter(Mandatory=$true,
               Position=1,
               HelpMessage="The username of your ZoneEdit account.")]
    [ValidateNotNull()]
    [string] $Username,

    [Parameter(Mandatory=$true,
               Position=2,
               HelpMessage="Your ZoneEdit password.")]
    [ValidateNotNull()]
    [string] $Password
)


if (! [System.Diagnostics.EventLog]::SourceExists("ZoneEdit Dynamic DNS Updater") ){
    New-Eventlog -LogName "Application" -Source "ZoneEdit Dynamic DNS Updater"
}

#DomainTools.com provides and easy XML response with basic information about the external IP your requests come from
$ext_ip_update_url = "https://wtfismyip.com/xml";

#Using Google Public DNS for lookup of the record
$dns_server = "8.8.8.8"

#Get the XML response and find the Internet-facing IP address this machine is using
try {
    $response_xml = [xml](Invoke-WebRequest $ext_ip_update_url).Content;
} catch {
    Write-EventLog -LogName Application -Source "ZoneEdit Dynamic DNS Updater" -EntryType Information -EventID 42 -Message "Couldn't reach $ext_ip_update_url to get the current IP. Please check your internet connection.";
    return 0;
}
$my_ip = ($response_xml.wtf).'your-fucking-ip-address';

#Validate the information we're using from the XML is an actual IP to avoid attacks and detect issues with the response
if (! ($my_ip -match "^(([1-9]?\d|1\d\d|25[0-5]|2[0-4]\d)\.){3}([1-9]?\d|1\d\d|25[0-5]|2[0-4]\d)$")) {
    Write-EventLog -LogName Application -Source "ZoneEdit Dynamic DNS Updater" -EntryType Information -EventID 42 -Message "Script ended early because the XML response from $ext_ip_update_url wasn't in the expected format.";
    return 0;
}

#Lookup the record against Google DNS servers
$current_ip = (Resolve-DnsName $Record -Server $dns_server).IP4Address;

#Compare the external IP against the record Google Public DNS provides, only update if there is a discrepancy
if ($current_ip -ne $my_ip) {
#update record
    Write-EventLog -LogName Application -Source "ZoneEdit Dynamic DNS Updater" -EntryType Information -EventID 42 -Message "$Record resolves to $current_ip, but current IP of this system is $my_ip. Updating DNS record...";
    $base_url = "http://dynamic.zoneedit.com/auth/dynamic.html";
    $full_url = $base_url + "?host=" + $Record + "&dnsto=" + $my_ip;
    $pwd = ConvertTo-SecureString $Password -AsPlainText -Force;
    $creds = New-Object System.Management.Automation.PSCredential ($username, $pwd);
    $response = Invoke-WebRequest $full_url -Credential $creds;
    Write-EventLog -LogName Application -Source "ZoneEdit Dynamic DNS Updater" -EntryType Information -EventID 42 -Message ($response.Content -replace "<.*?>");
} else {
#no update necessary
    Write-EventLog -LogName Application -Source "ZoneEdit Dynamic DNS Updater" -EntryType Information -EventID 42 -Message "$Record resolves to $current_ip, which is the same as $my_ip. No updates will be attempted.";
}
return 0;