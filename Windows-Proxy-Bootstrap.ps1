 Param(
	 [Parameter(Mandatory=$True,Position=1)]
	 [string]$webProxy,
	 [Parameter(Mandatory=$True,Position=2)]
	 [string]$dscFileURL,
	 [Parameter(Mandatory=$True,Position=3)]
	 [string]$dscFileTargetPath
 )

# Set proxy				
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxySettingsPerUser /t REG_DWORD /d 0 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyEnable /t REG_DWORD /d 1 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyServer /t REG_SZ /d $webProxy /f
netsh winhttp set proxy $webProxy

# Download DSC
$webClient = New-Object System.Net.WebClient
$webClient.Proxy = New-Object System.Net.WebProxy($webProxy, $true)
$webClient.DownloadFile($dscFileURL, $dscFileTargetPath)
