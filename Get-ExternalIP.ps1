function Get-ExternalIP () {
	$ext_ip_update_url = "https://wtfismyip.com/xml";

	try {
		$response_xml = [xml](Invoke-WebRequest $ext_ip_update_url).Content;
	} catch {
		Write-Warning "Couldn't obtain response from web service."
		return $null;
	}

	return [IPAddress](($response_xml.wtf).'your-fucking-ip-address');
}

function Cycle-TapAdapter () {
	$adapter = Get-NetAdapter | ? {$_.InterfaceDescription -eq "TAP-Windows Adapter V9"};
	Disable-NetAdapter $adapter -Confirm:$false;
	Enable-NetAdapter $adapter;
	Sleep -Seconds 5;
	$adapter = Get-NetAdapter | ? {$_.InterfaceDescription -eq "TAP-Windows Adapter V9"};
	if ($adapter.Status -ne "Disabled") {
		return $true;
	} else {
		return $false;
	}
}

function Send-GoogleText () {
	param (
		[Parameter(Mandatory=$true)]
		[string]$UserName,
		[Parameter(Mandatory=$true)]
		[string]$Password,
		[Parameter(Mandatory=$true)]
		[string]$TextMessage
	)
	$PWord = ConvertTo-SecureString –String $Password –AsPlainText -Force;
	$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $UserName, $PWord;
	Send-MailMessage -To 4252933450@vtext.com -From "hufford@gmail.com" -Body $TextMessage -SmtpServer "smtp.gmail.com" -Subject "VPN Offline" -Credential $Credential -Port 587 -UseSsl;
}

$errors = @();
$my_ip = Get-ExternalIP;

if ($my_ip.Address -eq "50.181.148.214") {
	#Detected Comcast IP

	#Kill Transmission service
	Get-Process transmission-qt -ErrorAction:SilentlyContinue | Stop-Process -Force -ErrorAction:SilentlyContinue;

	#Kill PIA
	Get-Process pia-* -ErrorAction:SilentlyContinue | Stop-Process -Force -ErrorAction:SilentlyContinue;

	#Recycle the TAP adapter	
	if (! Cycle-TapAdapter ) {
		Write-Warning "TAP adapter recycle failed";
		$errors += "TAP adapter recycle failed.";
	}	

	#Restart PIA
	Start-Process "C:\Program Files\pia_manager\pia_manager.exe"
	#PIA should auto reconnect

	#Wait for 60 seconds for it to reconnect
	$vpn_status = (Get-NetAdapter | ? {$_.InterfaceDescription -eq "TAP-Windows Adapter V9"}).Status;
	$timeout = 0;
	while ($vpn_status -ne "Up" -and $timeout -lt 120) {
		Sleep -Seconds 5;
		$timeout += 5;
		$vpn_status = (Get-NetAdapter | ? {$_.InterfaceDescription -eq "TAP-Windows Adapter V9"}).Status;
	}
	if  ($vpn_status -ne "Up") {
		Write-Warning "VPN reconnection appears to have failed.";
		$errors += "VPN reconnection appears to have failed.";
	}
}

$my_ip = (Get-ExternalIP).IPAddressToString;

if ($my_ip -eq "50.181.148.214") {
	#Send notification via Gmail that the VPN is down and Tranmission-qt is offline
	Send-GoogleText -UserName "hufford@gmail.com" -Password "dtxtb64hg4!" -TextMessage "PIA VPN is offline";
} else {
	#We're connected properly again, restarting Transmission
	Start-Process "C:\Program Files\Transmission\transmission-qt.exe";
}

