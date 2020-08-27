using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig
)

If ($PoolConfig.Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://www.ahashpool.com/api/status" -Headers @{"Cache-Control" = "no-cache" }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $HostSuffix = "mine.ahashpool.com"
    $PriceField = "actual_last24h"
    # $PriceField = "estimate_current"
    $DivisorMultiplier = 1000000000

    $PoolRegions = "US"

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.actual_last24h) -gt 0.000000001 } | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolHost = "$($Algorithm).$($HostSuffix)"
        $PoolPort = $Request.$_.port

        $Fee = [Decimal]($Request.$_.Fees / 100)
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $true

        Try { $EstimateFactor = [Decimal](($Request.$_.actual_last24h / 1000) / $Request.$_.estimate_last24h) }
        Catch { $EstimateFactor = [Decimal]1 }

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Protocol           = "stratum+tcp"
                Host               = [String]$PoolHost
                Port               = [UInt16]$PoolPort
                User               = $PoolConfig.Wallet
                Pass               = "$($PoolConfig.WorkerName),c=$($PoolConfig.PayoutCurrency)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateFactor     = $EstimateFactor
            }
        }
    }
}
