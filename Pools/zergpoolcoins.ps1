using module ..\Includes\Include.psm1

Try { 
    $Request = Get-Content ((Split-Path -Parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\zergpoolcoins\zergpoolcoins.json") | ConvertFrom-Json
    $CoinsRequest = Invoke-WebRequest "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
}
Catch { return }

If ((-not $Request) -or (-not $CoinsRequest)) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zergpool.com"

$PriceField = "Plus_Price"
#$PriceField = "actual_last24h"
#$PriceField = "estimate_current"
$DivisorMultiplier = 1000000
$PoolRegions = "US"

$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $PoolsConfig.$ConfName

$AllMiningCoins = @()
($CoinsRequest | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | ForEach-Object { $CoinsRequest.$_ | Add-Member -Force @{Symbol = If ($CoinsRequest.$_.Symbol) { $CoinsRequest.$_.Symbol } Else { $_ } } ; $AllMiningCoins += $CoinsRequest.$_ }

#Uses BrainPlus calculated price
$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolHost = "$($_).$($HostSuffix)"
    $PoolPort = $Request.$_.port
    $Algorithm_Norm = Get-Algorithm $Request.$_.name
    # Find best coin for algo
    $TopCoin = $AllMiningCoins | Where-Object { ($_.noautotrade -eq 0) -and ($_.hashrate -gt 0) -and ((Get-Algorithm $_.algo) -eq $Algorithm_Norm) } | Sort-Object -Property @{Expression = { $_.estimate / ($DivisorMultiplier * [Double]$_.mbtc_mh_factor) } } -Descending | select -first 1

    If ($TopCoin.Symbol) { 
        $Fee = [Decimal]($Request.$_.Fees / 100)
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        $Stat_Name = "$($Name)_$($Algorithm_Norm, $TopCoin.Symbol -join '-')_Profit"
        If ((Get-Stat -Name $Stat_Name) -eq $null) { $Stat = Set-Stat -Name $Stat_Name -Value ([Double]($Request.$_.$PriceField / $Divisor)) }
        Else { $Stat = Set-Stat -Name $Stat_Name -Value ([Double]($Request.$_.$PriceField / $Divisor)) }

        $PwdCurr = If ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency } Else { $Passwordcurrency }
        $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            If ($PoolConf.Wallet) { 
                [PSCustomObject]@{ 
                    Algorithm          = [String]$Algorithm_Norm
                    CoinName           = [String]$TopCoin.Name
                    Currency           = [String]$TopCoin.Symbol
                    Price              = [Double]$Stat.Live
                    StablePrice        = [Double]$Stat.Week
                    MarginOfError      = [Double]$Stat.Week_Fluctuation
                    EstimateCorrection = [Double]$PoolConf.EstimateCorrection
                    Protocol           = "stratum+tcp"
                    Host               = [String]$PoolHost
                    Port               = [UInt16]$PoolPort
                    User               = $PoolConf.Wallet
                    Pass               = If ($TopCoin.Symbol) { "$($WorkerName),c=$($PwdCurr),mc=$($TopCoin.Symbol)" } Else { "$($WorkerName),c=$($PwdCurr)" }
                    Region             = [String]$Region_Norm
                    SSL                = [Bool]$false
                    Fee                = $Fee
                }
            }
        }
    }
}
