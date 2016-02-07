#Create the new service using srvany.exe as the control program
cmd.exe "C:\Program Files (x86)\Windows Resource Kits\tools\Instsrv.exe" SpamAssassin "C:\Program Files (x86)\Windows Resource Kits\tools\Srvany.exe"
#Edit the registry for this new service to set the service description
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SpamAssassin"
New-ItemProperty -path $RegPath -Name Description -PropertyType String -Value "SpamAssassin daemon for Windows"
#Add the parameters key and set the path to the application
New-Item -Path $RegPath -Name "Parameters"
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SpamAssassin\Parameters"
New-ItemProperty -path $RegPath -Name Application -PropertyType String -Value "C:\Program Files (x86)\JAM Software\SpamAssassin for Windows\spamd.exe"
#Start the SpamAssassin service
Start-Service SpamAssassin