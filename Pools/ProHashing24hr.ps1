using module ..\Includes\Include.psm1

Try {
    $Request = (Invoke-RestMethod -Uri "https://prohashing.com/api/v1/status" -Headers @{"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"}).data
}
Catch { Return }

If (-not $Request) { Return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$PoolHost = "prohashing.com"
# $PriceField = "actual_last24h"
$PriceField = "actual_last24h"
$PoolRegions = "US"

# + 2.9% supplementary fee for conversion
# Makes 2 + 2.9 = 4.9%
# There is 0.00015 BTC fee on withdraw as well (Estimation 0.00015/0.0025 = 6%) Using 0.0025 as most pools do use this Payout threshold
# Makes 2 + 2.9 + 6 = 10.9% !!!
# Taking 1.5 here considering withdraw at 0.01BTC
# $Request.$_.fees = $Request.$_.fees + 2.9 + 1.5
 

# Placed here for Perf (Disk reads)
$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $PoolsConfig.$ConfName

If ($PoolConf.UserName) { 
    $PasswordCurrency = If ($PoolConf.PasswordCurrency) { $PoolConf.PasswordCurrency } Else { $PoolConf."Default".PasswordCurrency }
    $WorkerName = $PoolConf.WorkerName -Replace '^ID='

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.hashrate_last24h) -gt 0 } | ForEach-Object {
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolPort = $Request.$_.port

        $Fee = [Decimal]$Request.$_.pps_fee
        $Divisor = [Double]$Request.$_.mbtc_mh_factor

        Try { $EstimateCorrection = [Decimal]($Request.$_.actual_last24h / $Request.$_.estimate_current) }
        Catch { $EstimateCorrection = [Decimal]1 }

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $true

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConf.PricePenaltyfactor
                Protocol           = "stratum+tcp"
                Host               = [String]$PoolHost
                Port               = [UInt16]$PoolPort
                User               = "$($PoolConf.UserName)"
                Pass               = "a=$($Algorithm_Norm),n=$($WorkerName)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateCorrection = $(If ($PoolConf.PricePenaltyfactor -eq $true) { $EstimateCorrection } Else { [Decimal]1 } )
            }
        }
    }
}
