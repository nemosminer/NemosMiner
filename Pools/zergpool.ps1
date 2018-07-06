if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

try {
    $zergpool_Request = Invoke-WebRequest "http://api.zergpool.com:8080/api/status" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
    $zergpoolCoins_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
}
catch { return }

if (-not $zergpool_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$zergpool_Request | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
	$zergpool_Host = "$_.mine.zergpool.com"
	$zergpool_Port = $zergpool_Request.$_.port
	$zergpool_Algorithm = Get-Algorithm $zergpool_Request.$_.name
	$zergpool_Coin = $zergpool_Request.$_.coins
        $zergpool_Coinname = $zergpoolCoins_Request.$_.name

        $Divisor = 1000000 * [Double]$ZergPool_Request.$_.mbtc_mh_factor

	if ((Get-Stat -Name "$($Name)_$($zergpool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($zergpool_Algorithm)_Profit" -Value ([Double]$zergpool_Request.$_.estimate_last24h / $Divisor)}
	else {$Stat = Set-Stat -Name "$($Name)_$($zergpool_Algorithm)_Profit" -Value ([Double]$zergpool_Request.$_.estimate_current / $Divisor * (1 - ($zergpool_Request.$_.fees / 100)))}

	$ConfName = if ($Config.PoolsConfig.$Name -ne $Null) {$Name}else {"default"}
	$PwdCurr = if ($Config.PoolsConfig.$ConfName.PwdCurrency) {$Config.PoolsConfig.$ConfName.PwdCurrency}else {$Config.Passwordcurrency}

	if ($Config.PoolsConfig.default.Wallet) {
		[PSCustomObject]@{
			Algorithm     = $zergpool_Algorithm
			Info          = "$zergpool_Coin $zergpool_Coinname"
			Price         = $Stat.Live * $Config.PoolsConfig.$ConfName.PricePenaltyFactor
			StablePrice   = $Stat.Week
			MarginOfError = $Stat.Fluctuation
			Protocol      = "stratum+tcp"
			Host          = $zergpool_Host
			Port          = $zergpool_Port
			User          = $Config.PoolsConfig.$ConfName.Wallet
			Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$($PwdCurr)"
			Location      = $Location
			SSL           = $false
		}
	}
}

