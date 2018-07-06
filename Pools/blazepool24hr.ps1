if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

try {
    $blazepool_Request = Invoke-WebRequest "http://api.blazepool.com/status" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $blazepool_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$blazepool_Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $blazepool_Host = "$_.mine.blazepool.com"
    $blazepool_Port = $blazepool_Request.$_.port
    $blazepool_Algorithm = Get-Algorithm $blazepool_Request.$_.name
    $blazepool_Coin = ""

    $Divisor = 1000000000 * [Double]$BlazePool_Request.$_.mbtc_mh_factor

    if ((Get-Stat -Name "$($Name)_$($blazepool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_Profit" -Value ([Double]$blazepool_Request.$_.actual_last24h / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))}
    else {$Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_Profit" -Value ([Double]$blazepool_Request.$_.actual_last24h / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))}

	$ConfName = if ($Config.PoolsConfig.$Name -ne $Null){$Name}else{"default"}
	
    if ($Config.PoolsConfig.default.Wallet) {
        [PSCustomObject]@{
            Algorithm     = $blazepool_Algorithm
            Info          = $blazepool_Coin
            Price         = $Stat.Live*$Config.PoolsConfig.$ConfName.PricePenaltyFactor
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Week_Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $blazepool_Host
            Port          = $blazepool_Port
            User          = $Config.PoolsConfig.$ConfName.Wallet
		    Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$($Config.Passwordcurrency)"
            Location      = $Location
            SSL           = $false
        }
    }
}
