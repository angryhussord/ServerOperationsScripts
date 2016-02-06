#Query Transmission for Stats using an RPC JSON call
$url = "http://192.168.1.7:9091/transmission/rpc"

#more fields and usage here: https://trac.transmissionbt.com/browser/branches/2.8x/extras/rpc-spec.txt
$command = '{ "arguments": {"fields": ["name", "percentDone", "eta"], "ids": "recently-active"}, "method": "torrent-get", "tag": 39693}';

#Clear the error variable to make dealing with the exception easier
try {
	#We expect this to fail with a 409 status code, but we still need to run it to grab the X-Transmission-Session-Id out of the exception
	$response = Invoke-WebRequest $url;
} catch {
	$session_id = $Error[0].ErrorDetails.Message.Split(":")[3].TrimStart();
}

$headers = @{};
$headers.Add("X-Transmission-Session-Id", $session_id);

$response = Invoke-WebRequest $url -Method POST -Body $command -Headers $headers;
$current = [datetime]($response.BaseResponse.LastModified);
$torrents = (ConvertFrom-Json $response.Content).arguments.torrents;

foreach($torrent in $torrents) {
	Add-Member -InputObject $torrent -MemberType NoteProperty -Name completionDate -Value "";
	switch ($torrent.eta) {
		"-1" {$torrent.completionDate = "Not Available";}
		"-2" {$torrent.completionDate = "Unknown";}
		default {$torrent.completionDate = $current.AddSeconds($torrent.eta).ToString();}
	}
	$torrent.percentDone *= 100;
}

#Write resulting $torrents array out to an HTML file
$torrents | Select-Object Name,percentDone,completionDate | Sort percentDone -Descending | ConvertTo-Html -Fragment | Out-File .\active-torrents.html