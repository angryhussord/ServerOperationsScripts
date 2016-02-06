#Makes the rest of the script run as admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#Config Tweaks
Powercfg -h off


#Remove Windows Store and Apps
Get-appxpackage -allusers *3dbuilder* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*3dbuilder*"} | remove-appxprovisionedpackage –online

Get-appxpackage -allusers *officehub* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*officehub*"} | remove-appxprovisionedpackage –online

Get-appxpackage -allusers *skypeapp* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*skypeapp*"} | remove-appxprovisionedpackage –online

Get-appxpackage -allusers *getstarted* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*getstarted*"} | remove-appxprovisionedpackage –online

Get-appxpackage -allusers *zunemusic* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*zunemusic*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *solitairecollection* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*solitairecollection*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *bingfinance* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*bingfinance*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *zunevideo* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*zunevideo*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *bingnews* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*bingnews*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *windowsphone* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*windowsphone*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *bingsports* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*bingsports*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *xboxapp* | remove-appxpackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*xboxapp*"} | remove-appxprovisionedpackage –online

Get-AppxPackage -AllUsers *Dell* | Remove-AppxPackage
Get-appxprovisionedpackage –online | where-object {$_.packagename –like "*Dell*"} | remove-appxprovisionedpackage –online

#Delete tracking services
Stop-Service DiagTrack -Force
sc delete DiagTrack
Stop-Service dmwappushservice -Force
sc delete dmwappushservice

echo "" > C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl

#Privacy and telemetry disabling tweaks

#disable using your machine for sending windows updates to others
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DownloadMode /t REG_DWORD /d 0 /f
#disable sending settings to cloud
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v DisableSettingSync /t REG_DWORD /d 2 /f
#disable synchronizing files to cloud
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v DisableSettingSyncUserOverride /t REG_DWORD /d 1 /f
#disable ad customization
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f
#disable data collection and sending to MS
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
#disable sending files to encrypted drives
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\EnhancedStorageDevices" /v TCGSecurityActivationDisabled /t REG_DWORD /d 0 /f
#disable sync files to one drive
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f
#disable certificate revocation check
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers" /v authenticodeenabled /t REG_DWORD /d 0 /f
#disable send additional info with error reports
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v DontSendAdditionalData /t REG_DWORD /d 1 /f
#disable cortana in windows search
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f
#disable web search in search bar
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f
#disable search web when searching pc
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f
#disable location based info in searches
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation /t REG_DWORD /d 0 /f
#disable language detection
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AlwaysUseAutoLangDetection /t REG_DWORD /d 0 /f

shutdown /r /t 15