using module ..\Includes\Include.psm1

Try { 
    $Request = Get-Content ((Split-Path -Parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\blazepool\blazepool.json") | ConvertFrom-Json 
}
Catch { Return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".mine.blazepool.com"
$PriceField = "Plus_Price"
# $PriceField = "actual_last24h"
# $PriceField = "estimate_current"
$DivisorMultiplier = 1000000

$PoolRegions = "US"

# Placed here for Perf (Disk reads)
$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "Default" }
$PoolConf = $PoolsConfig.$ConfName

If ($PoolConf.Wallet) { 
    $PasswordCurrency = If ($PoolConf.PasswordCurrency) { $PoolConf.PasswordCurrency } Else { $PoolConf."Default".PasswordCurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.actual_last24h) -gt 0 } | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolHost = "$($_)$($HostSuffix)"
        $PoolPort = $Request.$_.port

        $Fee = [Decimal]($Request.$_.Fees / 100)
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $true

        Try { $EstimateCorrection = [Decimal](($Request.$_.actual_last24h / 1000) / $Request.$_.estimate_last24h) }
        Catch { $EstimateCorrection = [Decimal]1 }

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
                User               = $PoolConf.Wallet
                Pass               = "$($WorkerName),c=$($PasswordCurrency)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateCorrection = $(If ($PoolConf.PricePenaltyfactor -eq $true) { $EstimateCorrection } Else { [Decimal]1 } )
            }
        }
    }
}