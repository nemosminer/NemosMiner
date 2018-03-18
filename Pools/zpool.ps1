. .\Include.ps1

try {
    $Zpool_Request = Invoke-WebRequest "http://www.zpool.ca/api/status" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $Zpool_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$Zpool_Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | foreach {
    $Zpool_Host = "$_.mine.zpool.ca"
    $Zpool_Port = $Zpool_Request.$_.port
    $Zpool_Algorithm = Get-Algorithm $Zpool_Request.$_.name
    $Zpool_Coin = ""

    $Divisor = 1000000
	
    switch ($Zpool_Algorithm) {
        "equihash" {$Divisor /= 1000}
        "blake2s" {$Divisor *= 1000}
        "blakecoin" {$Divisor *= 1000}
        "decred" {$Divisor *= 1000}
        "keccak" {$Divisor *= 1000}
        "keccakc" {$Divisor *= 1000}
    }

    if ((Get-Stat -Name "$($Name)_$($Zpool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm)_Profit" -Value ([Double]$Zpool_Request.$_.estimate_last24h / $Divisor * (1 - ($Zpool_Request.$_.fees / 100)))}
    else {$Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm)_Profit" -Value ([Double]$Zpool_Request.$_.estimate_current / $Divisor * (1 - ($Zpool_Request.$_.fees / 100)))}

    $ConfName = if ($Config.PoolsConfig.$Name -ne $Null) {$Name}else {"default"}
	
    if ($Config.PoolsConfig.default.Wallet) {
        [PSCustomObject]@{
            Algorithm     = $Zpool_Algorithm
            Info          = $Zpool
            Price         = $Stat.Live * $Config.PoolsConfig.$ConfName.PricePenaltyFactor
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $Zpool_Host
            Port          = $Zpool_Port
            User          = $Config.PoolsConfig.$ConfName.Wallet
            Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$($Config.Passwordcurrency)"
            Location      = $Location
            SSL           = $false
        }
    }
}
