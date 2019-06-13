if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

Try {
    $Request = get-content ((split-path -parent (get-item $script:MyInvocation.MyCommand.Path).Directory) + "\BrainPlus\zpoolplus\zpoolplus.json") | ConvertFrom-Json 
}
catch { return }

if (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".mine.zpool.ca"
$PriceField = "Plus_Price"
# $PriceField = "actual_last24h"
# $PriceField = "estimate_current"
$DivisorMultiplier = 1000000

# Placed here for Perf (Disk reads)
$ConfName = if ($Config.PoolsConfig.$Name -ne $Null) { $Name }else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName
 

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = $_
    $PoolPort = $Request.$_.port
    $PoolAlgorithm = Get-Algorithm $Request.$_.name

    $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

    $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100)))

    $PwdCurr = if ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency }else { $Config.Passwordcurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } else { "ID=$($PoolConf.WorkerName)" }

    $Locations = "eu", "na", "sea"
    $Locations | ForEach-Object {
        $Pool_Location = $_
        switch ($Pool_Location) {
            "eu" { $Location = "EU" }
            "na" { $Location = "US" }
            "sea" { $Location = "JP" }
            default { $Location = "US" }
        }
        $PoolHost = "$($Algo).$($Pool_Location)$($HostSuffix)"
    
        if ($PoolConf.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $PoolAlgorithm
                Info          = "$ahashpool_Coin $ahashpool_Coinname"
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $PoolHost
                Port          = $PoolPort
                User          = $PoolConf.Wallet
                Pass          = "$($WorkerName),c=$($PwdCurr)"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
