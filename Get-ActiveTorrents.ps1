function Get-ActiveTorrents () {
	param (
		[string]$Server,
		[string[]]$Fields = @("activityDate", "addedDate", "bandwidthPriority", "comment", "corruptEver", "creator", "dateCreated", "desiredAvailable", "doneDate", "downloadDir", "downloadedEver", "downloadLimit", "downloadLimited", "error", "errorString", "eta", "etaIdle", "files", "fileStats", "hashString", "haveUnchecked", "haveValid", "honorsSessionLimits", "id", "isFinished", "isPrivate", "isStalled", "leftUntilDone", "magnetLink", "manualAnnounceTime", "maxConnectedPeers", "metadataPercentComplete", "name", "peer-limit", "peers", "peersConnected", "peersFrom", "peersGettingFromUs", "peersSendingToUs", "percentDone", "pieces", "pieceCount", "pieceSize", "priorities", "queuePosition", "rateDownload (B/s)", "rateUpload (B/s)", "recheckProgress", "secondsDownloading", "secondsSeeding", "seedIdleLimit", "seedIdleMode", "seedRatioLimit", "seedRatioMode", "sizeWhenDone", "startDate", "status", "trackers", "trackerStats", "totalSize", "torrentFile", "uploadedEver", "uploadLimit", "uploadLimited", "uploadRatio", "wanted", "webseeds", "webseedsSendingToUs", "files", "fileStats", "peers", "peersFrom", "pieces", "priorities", "trackers", "trackerStats", "wanted", "webseeds")
	)

	# Query Transmission for Stats using an RPC JSON call
	$url = "http://$Server/transmission/rpc"

	# More fields and usage here: https://trac.transmissionbt.com/browser/branches/2.8x/extras/rpc-spec.txt
	[string]$command = $null;
	switch ($Fields.count) {
		0 { Write-Error "Number of fields given must be greater than 0."; Exit; }
		1 {$command = "{ `"arguments`": {`"fields`": [`"$($Fields)`"], `"ids`": `"recently-active`"}, `"method`": `"torrent-get`", `"tag`": 39693}";}
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
	return (ConvertFrom-Json $response.Content).arguments.torrents;
}

$current = Get-Date;
$torrents = Get-ActiveTorrents -Server 192.168.1.7:9091 -Fields @("name", "percentDone", "eta", "peersFrom");
foreach($torrent in $torrents) {
	Add-Member -InputObject $torrent -MemberType NoteProperty -Name completionDate -Value "";
	switch ($torrent.eta) {
		"-1" {$torrent.completionDate = "Not Available";}
		"-2" {$torrent.completionDate = "Unknown";}
		default {$torrent.completionDate = $current.AddSeconds($torrent.eta).ToString();}
	}
	$torrent.percentDone *= 100;
}

$torrents | Select-Object name,percentDone,completionDate | Sort percentDone -Descending | ConvertTo-Html -Fragment | Out-File .\active-torrents.html


