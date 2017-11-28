 Param(
	 [Parameter(Mandatory=$True,Position=1)]
	 [string]$dscFileURL,
	 [Parameter(Mandatory=$True,Position=2)]
	 [string]$dscFileTargetPath
 )

# Download DSC
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($dscFileURL, $dscFileTargetPath)
