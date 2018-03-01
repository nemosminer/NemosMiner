. .\Include.ps1

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

    $Divisor = 1000000
	
    switch ($blazepool_Algorithm) {
        "blake" {$Divisor *= 1000}
        "blake2s" {$Divisor *= 1000}
        "blakecoin" {$Divisor *= 1000}
        "decred" {$Divisor *= 1000}
        "keccak" {$Divisor *= 1000}
        "keccakc" {$Divisor *= 1000}
        "quark" {$Divisor *= 1000}
        "qubit" {$Divisor *= 1000}
        "vanilla" {$Divisor *= 1000}
        "scrypt" {$Divisor *= 1000}
        "x11" {$Divisor *= 1000}
        "equihash" {$Divisor /= 1000}
        "yescrypt" {$Divisor /= 1000}
    }

    if ((Get-Stat -Name "$($Name)_$($blazepool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_Profit" -Value ([Double]$blazepool_Request.$_.estimate_last24h / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))}
    else {$Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_Profit" -Value ([Double]$blazepool_Request.$_.estimate_current / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))}
	
    if ($Wallet) {
        [PSCustomObject]@{
            Algorithm     = $blazepool_Algorithm
            Info          = $blazepool_Coin
            Price         = $Stat.Live
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Week_Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $blazepool_Host
            Port          = $blazepool_Port
            User          = $Wallet
            Pass          = "$WorkerName,c=$Passwordcurrency"
            Location      = $Location
            SSL           = $false
        }
    }
}
