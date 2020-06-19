using module ..\Includes\Include.psm1

Try { 
    $Request = get-content ((split-path -parent (get-item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\zpool\zpool.json") | ConvertFrom-Json 
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zpool.ca"
$PriceField = "Plus_Price"
# $PriceField = "actual_last24h"
# $PriceField = "estimate_current"
# Placed here for Perf (Disk reads)
$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $PoolsConfig.$ConfName
$PoolRegions = "eu", "jp", "na", "sea"

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $Algorithm = $_
    $Algorithm_Norm = Get-Algorithm $Algorithm
    $PoolPort = $Request.$_.port

    $Fee = [Decimal]($Request.$_.Fees / 100)
    $Divisor = 1000000 * [Double]$Request.$_.mbtc_mh_factor

    $Stat_Name = "$($Name)_$($Algorithm_Norm)_Profit"
    If ((Get-Stat -Name $Stat_Name) -eq $null) { $Stat = Set-Stat -Name $Stat_Name -Value ([Double]$Request.$_.$PriceField / $Divisor) }
    Else { $Stat = Set-Stat -Name $Stat_Name -Value ([Double]$Request.$_.$PriceField / $Divisor) }

    $PasswordCurrency = If ($PoolConf.PasswordCurrencyy) { $PoolConf.PasswordCurrencyy } Else { $PoolConf."Default".PasswordCurrency }
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
                Host               = "$($Algorithm).$($Region).$($HostSuffix)"
                Port               = [UInt16]$PoolPort
                User               = $PoolConf.Wallet
                Pass               = "$($WorkerName),c=$($PasswordCurrency)"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
            }
        }
    }
}
