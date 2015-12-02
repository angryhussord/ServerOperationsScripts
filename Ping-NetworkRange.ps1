$ip = "192.168.1."
$num = 1;
$results = @{};
while ($num -lt 255) {
	$ping = $ip + $num;
	$results.Add($ping,((ping $ping -l 113 -n 1)[2] -match "bytes=113"));
	$num++;
}
$results;