. .\Include.ps1

$PlusPath = ((split-path -parent (get-item $script:MyInvocation.MyCommand.Path).Directory) + "\BrainPlus\ahashpoolplus\ahashpoolplus.json")
Try {
    $ahashpool_Request = get-content $PlusPath | ConvertFrom-Json 
}
catch { return }

if (-not $ahashpool_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$ahashpool_Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $ahashpool_Host = "$_.mine.ahashpool.com"
    $ahashpool_Port = $ahashpool_Request.$_.port
    $ahashpool_Algorithm = Get-Algorithm $ahashpool_Request.$_.name
    $ahashpool_Coin = ""

    $Divisor = 1000000000
	
    switch ($ahashpool_Algorithm) {

        "sha256" {$Divisor *= 1000000}
        "sha256t" {$Divisor *= 1000000}
        "blake" {$Divisor *= 1000}
        "blake2s" {$Divisor *= 1000}
        "blakecoin" {$Divisor *= 1000}
        "decred" {$Divisor *= 1000}
        "vanilla" {$Divisor *= 1000}
        "x11" {$Divisor *= 1000}
        "equihash" {$Divisor /= 1000}
        "yescrypt" {$Divisor /= 1000}
    }

    if ((Get-Stat -Name "$($Name)_$($ahashpool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($ahashpool_Algorithm)_Profit" -Value ([Double]$ahashpool_Request.$_.actual_last24h / $Divisor * (1 - ($ahashpool_Request.$_.fees / 100)))}
    else {$Stat = Set-Stat -Name "$($Name)_$($ahashpool_Algorithm)_Profit" -Value ([Double]$ahashpool_Request.$_.actual_last24h / $Divisor * (1 - ($ahashpool_Request.$_.fees / 100)))}
	
    if ($Wallet) {
        [PSCustomObject]@{
            Algorithm     = $ahashpool_Algorithm
            Info          = $ahashpool_Coin
            Price         = $Stat.Live
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Week_Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $ahashpool_Host
            Port          = $ahashpool_Port
            User          = $Wallet
            Pass          = "$WorkerName,c=BTC"
            Location      = $Location
            SSL           = $false
        }
    }
}
