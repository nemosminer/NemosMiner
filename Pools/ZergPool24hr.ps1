using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "http://api.zergpool.com:8080/api/status" -Headers @{"Cache-Control" = "no-cache" }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $HostSuffix = "mine.zergpool.com"
    $PriceField = "actual_last24h"
    # $PriceField = "estimate_current"
    $DivisorMultiplier = 1000000000

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.actual_last24h) -gt 0 } | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolHost = "$($HostSuffix)"
        $PoolPort = $Request.$_.port

        $Fee = [Decimal]($Request.$_.Fees / 100)
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor)

        Try { $EstimateFactor = [Decimal](($Request.$_.actual_last24h / 1000) / $Request.$_.estimate_last24h) }
        Catch { $EstimateFactor = [Decimal]1 }

        [PSCustomObject]@{ 
            Algorithm          = [String]$Algorithm_Norm
            Price              = [Double]$Stat.Live
            StablePrice        = [Double]$Stat.Week
            MarginOfError      = [Double]$Stat.Week_Fluctuation
            PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
            Host               = [String]$PoolHost
            Port               = [UInt16]$PoolPort
            User               = [String]$PoolConfig.Wallet
            Pass               = "$($PoolConfig.WorkerName),c=$($PoolConfig.PayoutCurrency)"
            Region             = "N/A (Anycast)"
            SSL                = [Bool]$false
            Fee                = $Fee
            EstimateFactor     = $EstimateFactor
        }
    }
}
