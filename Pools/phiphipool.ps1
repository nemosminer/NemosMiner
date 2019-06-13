if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

try { 
    $Request = Invoke-RestMethod "http://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
} 
catch { return }
 
if (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".phi-phi-pool.com"
# $PriceField = "actual_last24h"
$PriceField = "estimate_current"
$DivisorMultiplier = 1000000
    
# Placed here for Perf (Disk reads)
$ConfName = if ($Config.PoolsConfig.$Name -ne $Null) { $Name }else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$Locations = "asia", "eu"
$Locations | ForEach-Object {
    $Pool_Location = $_
        
    switch ($Pool_Location) {
        "eu" { $Location = "EU" } #Europe
        "asia" { $Location = "JP" } #Asia [Thailand]
        default { $Location = "JP" }
    }

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $PoolHost = "$($Pool_Location)$($HostSuffix)"
        $PoolPort = $Request.$_.port
        $PoolAlgorithm = Get-Algorithm $Request.$_.name

        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        if ((Get-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit") -eq $null) { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }
        else { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }

        $PwdCurr = if ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency }else { $Config.Passwordcurrency }
        $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } else { "ID=$($PoolConf.WorkerName)" }

        if ($PoolConf.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $PoolAlgorithm
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
