 Param(
	 [Parameter(Mandatory=$True,Position=1)]
	 [string]$webProxy
 )

# Set proxy				
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxySettingsPerUser /t REG_DWORD /d 0 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyEnable /t REG_DWORD /d 1 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyServer /t REG_SZ /d $webProxy /f
netsh winhttp set proxy $webProxy
