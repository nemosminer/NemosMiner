using module ..\Includes\Include.psm1

Try { 
    $Request = Invoke-RestMethod -Uri "http://www.nlpool.nl/api/status" -Headers @{"Cache-Control" = "no-cache" }
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.nlpool.nl"
$PriceField = "actual_last24h"
# $PriceField = "estimate_current"

$PoolRegions = "US"

# Placed here for Perf (Disk reads)
$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "Default" }
$PoolConf = $PoolsConfig.$ConfName

$PasswordCurrency = If ($PoolConf.PasswordCurrency) { $PoolConf.PasswordCurrency } Else { $PoolConf."Default".PasswordCurrency }
$WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolHost = $HostSuffix
    $PoolPort = $Request.$_.port
    $Algorithm = $Request.$_.name
    $Algorithm_Norm = Get-Algorithm $Algorithm

    $Fee = [Decimal]($Request.$_.Fees / 100)
    $Divisor = 1000000000 * [Double]$Request.$_.mbtc_mh_factor

    $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $true

    Try { $EstimateCorrection = [Decimal]($Request.$_.$PriceField / $Request.$_.estimate_last24h) }
    Catch { $EstimateCorrection = [Decimal]1 }

    $PoolRegions | ForEach-Object { 
        $Region = $_
        $Region_Norm = Get-Region $Region

        If ($PoolConf.Wallet) { 
            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConf.PricePenaltyfactor
                Protocol           = "stratum+tcp"
                Host               = [String]$PoolHost
                Port               = [UInt16]$PoolPort
                User               = $PoolConf.Wallet
                Pass               = "$($WorkerName),c=$($PasswordCurrency)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateCorrection = $EstimateCorrection
            }
        }
    }
}
