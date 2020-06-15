using module ..\Includes\Include.psm1

Try { 
    $Request = Get-Content ((Split-Path -parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\zergpool\zergpool.json") | ConvertFrom-Json
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "103.249.70.7"
$PriceField = "Plus_Price"
# $PriceField = "actual_last24h"
# $PriceField = "estimate_current"
$DivisorMultiplier = 1000000

$PoolRegions = "US"

# Placed here for Perf (Disk reads)
$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $PoolsConfig.$ConfName

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolHost = "$($HostSuffix)"
    $PoolPort = $Request.$_.port
    $Pool = $Request.$_.port
    $Algorithm_Norm = Get-Algorithm $Request.$_.name

    $Fee = [Decimal]($Request.$_.Fees / 100)
    $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

    $Stat_Name = "$($Name)_$($Algorithm_Norm)_Profit"
    If ((Get-Stat -Name $Stat_Name) -eq $null) { $Stat = Set-Stat -Name $Stat_Name -Value ([Double]$Request.$_.$PriceField / $Divisor) }
    Else { $Stat = Set-Stat -Name $Stat_Name -Value ([Double]$Request.$_.$PriceField / $Divisor) }

    $PwdCurr = If ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency } Else { $PoolConf."Default".PasswordCurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

    $PoolRegions | ForEach-Object { 
        $Region = $_
        $Region_Norm = Get-Region $Region

        If ($PoolConf.Wallet) { 
            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                EstimateCorrection = [Double]$PoolConf.EstimateCorrection
                Protocol           = "stratum+tcp"
                Host               = [String]$PoolHost
                Port               = [UInt16]$PoolPort
                User               = $PoolConf.Wallet
                Pass               = "$($WorkerName),c=$($PwdCurr)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
            }
        }
    }
}
