using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.UserName) { 
    Try {
        $Request = (Invoke-RestMethod -Uri "https://prohashing.com/api/v1/status" -Headers @{"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"}).data
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $PoolHost = "prohashing.com"
    # $PriceField = "actual_last24h"
    $PriceField = "actual_last24h"
    $PoolRegions = "US"
    
    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.hashrate_last24h) -gt 0 } | ForEach-Object {
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolPort = $Request.$_.port

        $Fee = [Decimal]$Request.$_.pps_fee
        $Divisor = [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $true

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
                User               = "$($PoolConfig.UserName)"
                Pass               = "a=$($Algorithm_Norm),n=$($PoolConfig.WorkerName)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateFactor     = [Decimal]1
            }
        }
    }
}
