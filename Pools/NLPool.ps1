using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.Wallet) { 
    Try { 
        $Request = Get-Content ((Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Brains\nlpool\nlpool.json") | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $HostSuffix = "mine.nlpool.nl"
    $PriceField = "Plus_Price"
    # $PriceField = "actual_last24h"
    # $PriceField = "estimate_current"
    
    $PoolRegions = "US"

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Request.$_.workers -ge $PoolConfig.MinWorker } | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolHost = $HostSuffix
        $PoolPort = $Request.$_.port
        $Updated = $Request.$_.Updated

        $Fee = [Decimal]($Request.$_.Fees / 100)
        $Divisor = 1000000 * [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor)

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
                Host               = [String]$PoolHost
                Port               = [UInt16]$PoolPort
                User               = [String]$PoolConfig.Wallet
                Pass               = "$($PoolConfig.WorkerName),c=$($PoolConfig.PayoutCurrency)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = [Decimal]$Fee
                EstimateFactor     = [Decimal]$EstimateFactor
                Updated            = [DateTime]$Updated
            }
        }
    }
}
