function Query-TransmissionRPC () {
	param (
		[string]$Server,
		[string[]]$Fields
	)

	# Query Transmission for Stats using an RPC JSON call
	$url = "http://$Server/transmission/rpc"

	# More fields and usage here: https://trac.transmissionbt.com/browser/branches/2.8x/extras/rpc-spec.txt
	#Working 
	# $command = "{ `"arguments`": {`"fields`": [`"$($Fields[0])`", `"$($Fields[1])`", `"$($Fields[2])`"], `"ids`": `"recently-active`"}, `"method`": `"torrent-get`", `"tag`": 39693}";
	[string]$command = $null;
	switch ($Fields.count) {
		0 { Write-Error "Number of fields given must be greater than 0."; Exit; }
		1 {$command = "{ `"arguments`": {`"fields`": [`"$($Fields[0])`"], `"ids`": `"recently-active`"}, `"method`": `"torrent-get`", `"tag`": 39693}";}
		default {
			$command = "{ `"arguments`": {`"fields`": [";
			foreach ($field in $Fields) {
				$command += "`"";
				$command += $field;
				if ($field -eq $Fields[$Fields.count-1]) {
					$command += "`"";
				} else {
					$command += "`", ";
				}
			}
			$command += "], `"ids`": `"recently-active`"}, `"method`": `"torrent-get`", `"tag`": 39693}";		
		}
	}
	

	# Clear the error variable to make dealing with the exception easier
	try	{
		# We expect this to fail with a 409 status code, but we still need to run it to grab the X-Transmission-Session-Id
		# out of the exception
		$response = Invoke-WebRequest $url;
	} catch {
		if ($Error[0].ErrorDetails.Message.Split(":")[0] -eq "409") {
			#409 returned as expected, set the session_id
			$session_id = $Error[0].ErrorDetails.Message.Split(":")[3].TrimStart();
		} else {
			Write-Error "RPC response from the endpoint $Server was unexpected."
			Write-Error $Error[0].ErrorDetails.Message;
			Exit;
		}		
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

	return $torrents;
}

Query-TransmissionRPC -Server 192.168.1.7:9091 -Fields @("name", "percentDone", "eta", "peersFrom") | Sort percentDone -Descending | ConvertTo-Html -Fragment | Out-File .\active-torrents.html