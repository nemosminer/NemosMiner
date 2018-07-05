if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

try {
    $blockmasters_Request = Invoke-WebRequest "http://blockmasters.co/api/status" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $blockmasters_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$blockmasters_Request | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
	$blockmasters_Host = "blockmasters.co"
	$blockmasters_Port = $blockmasters_Request.$_.port
	$blockmasters_Algorithm = Get-Algorithm $blockmasters_Request.$_.name
	$blockmasters_Coin = ""

	$Divisor = 1000000 * [Double]$BlockMasters_Request.$_.mbtc_mh_factor

	if ((Get-Stat -Name "$($Name)_$($blockmasters_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($blockmasters_Algorithm)_Profit" -Value ([Double]$blockmasters_Request.$_.estimate_last24h / $Divisor)}
	else {$Stat = Set-Stat -Name "$($Name)_$($blockmasters_Algorithm)_Profit" -Value ([Double]$blockmasters_Request.$_.estimate_current / $Divisor * (1 - ($blockmasters_Request.$_.fees / 100)))}

	$ConfName = if ($Config.PoolsConfig.$Name -ne $Null) {$Name}else {"default"}
	$PwdCurr = if ($Config.PoolsConfig.$ConfName.PwdCurrency) {$Config.PoolsConfig.$ConfName.PwdCurrency}else {$Config.Passwordcurrency}

	if ($Config.PoolsConfig.default.Wallet) {
		[PSCustomObject]@{
			Algorithm     = $blockmasters_Algorithm
			Info          = $blockmasters
			Price         = $Stat.Live * $Config.PoolsConfig.$ConfName.PricePenaltyFactor
			StablePrice   = $Stat.Week
			MarginOfError = $Stat.Fluctuation
			Protocol      = "stratum+tcp"
			Host          = $blockmasters_Host
			Port          = $blockmasters_Port
			User          = $Config.PoolsConfig.$ConfName.Wallet
			Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$($PwdCurr)"
			Location      = $Location
			SSL           = $false
		}
	}
}

