if (!(IsLoaded(".\Include.ps1"))) { . .\Include.ps1; RegisterLoaded(".\Include.ps1") }

Try {
    $Request = get-content ((split-path -parent (get-item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\zergpoolcoins\zergpoolcoins.json") | ConvertFrom-Json
    $CoinsRequest = Invoke-WebRequest "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
}
catch { return }

if ((-not $Request) -or (-not $CoinsRequest)) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".mine.zergpool.com"

$PriceField = "Plus_Price"
#$PriceField = "actual_last24h"
#$PriceField = "estimate_current"
$DivisorMultiplier = 1000000
$Location = "US"

$ConfName = if ($Config.PoolsConfig.$Name -ne $Null) { $Name }else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$AllMiningCoins = @()
($CoinsRequest | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | % { $CoinsRequest.$_ | Add-Member -Force @{Symbol = if ($CoinsRequest.$_.Symbol) { $CoinsRequest.$_.Symbol } else { $_ } } ; $AllMiningCoins += $CoinsRequest.$_ }

#Uses BrainPlus calculated price
$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $PoolHost = "$($_)$($HostSuffix)"
    $PoolPort = $Request.$_.port
    $PoolAlgorithm = Get-Algorithm $Request.$_.name
    # Find best coin for algo
    $TopCoin = $AllMiningCoins | where { ($_.noautotrade -eq 0) -and ($_.hashrate -gt 0) -and ((Get-Algorithm $_.algo) -eq $PoolAlgorithm) } | sort -Property @{Expression = { $_.estimate / ($DivisorMultiplier * [Double]$_.mbtc_mh_factor) } } -Descending | select -first 1

    $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

    if ((Get-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit") -eq $null) { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }
    else { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }

    $PwdCurr = if ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency }else { $Config.Passwordcurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } else { "ID=$($PoolConf.WorkerName)" }
    if ($PoolConf.Wallet) {
        [PSCustomObject]@{
            Algorithm     = $PoolAlgorithm
            Coin          = $TopCoin.Symbol
            Info          = $TopCoin.Name
            Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Week_Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $PoolHost
            Port          = $PoolPort
            User          = $PoolConf.Wallet
            Pass          = If ($TopCoin.Symbol) { "$($WorkerName),c=$($PwdCurr),mc=$($TopCoin.Symbol)" } else { "$($WorkerName),c=$($PwdCurr)" }
            Location      = $Location
            SSL           = $false
        }
    }
}