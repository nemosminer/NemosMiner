. .\Includes\Include.ps1

Try { 
    $Request = Invoke-WebRequest "https://www.ahashpool.com/api/status" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".mine.ahashpool.com"
$PriceField = "actual_last24h"
# $PriceField = "estimate_current"
$DivisorMultiplier = 1000000000

$Location = "US"

# Placed here for Perf (Disk reads)
$ConfName = If ($Config.PoolsConfig.$Name) { $Name }else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolHost = "$($_)$($HostSuffix)"
    $PoolPort = $Request.$_.port
    $PoolAlgorithm = Get-Algorithm $Request.$_.name

    $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

    If ((Get-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit") -eq $null) { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }
    Else { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }

    $PwdCurr = If ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency }else { $Config.Passwordcurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

    If ($PoolConf.Wallet) { 
        [PSCustomObject]@{ 
            Algorithm     = $PoolAlgorithm
            Info          = ""
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
