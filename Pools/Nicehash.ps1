using module ..\Includes\Include.psm1

Try { 
    $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -TimeoutSec 15 -Headers @{"Cache-Control" = "no-cache" }
    $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -TimeoutSec 15 -Headers @{"Cache-Control" = "no-cache" }
    $Request.miningAlgorithms | ForEach-Object { $Algo = $_.Algorithm ; $_ | Add-Member -force @{algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algo } } }
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $PoolsConfig.$ConfName

$PoolRegions = "eu", "jp", "usa"
$PoolHost = "nicehash.com"

If ($PoolsConfig.$ConfName.IsInternal) { 
    $Fee = 0.02
}
Else { 
    $Fee = 0.05
}

$Request.miningAlgorithms | Where-Object { $_.speed -gt 0 } | ForEach-Object { 
    $Algorithm = $_.Algorithm
    $PoolPort = $_.algodetails.port
    $Algorithm_Norm = Get-Algorithm $Algorithm
    $DivisorMultiplier = 1000000000
    $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.marketFactor
    $Divisor = 100000000

    $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor * (1 - $Fee))

    $PoolRegions | ForEach-Object { 
        $Region = $_
        $Region_Norm = Get-Region $Region

        If ($PoolConf.Wallet) { 
            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]0
                Protocol           = "stratum+tcp"
                Host               = [String]"$Algorithm.$Region.$PoolHost"
                Port               = [UInt16]$PoolPort
                User               = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=', ''))"
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Boolean]$false
                Fee                = $Fee
                EstimateCorrection = [Decimal]1
            }

            If ($Algorithm_Norm -match "CryptonightR|Equihash1445|Randomx") { 
                [PSCustomObject]@{ 
                    Algorithm          = [String]$Algorithm_Norm
                    Price              = [Double]$Stat.Live
                    StablePrice        = [Double]$Stat.Week
                    MarginOfError      = [Double]0
                    PricePenaltyfactor = [Double]$PoolConf.PricePenaltyfactor
                    Protocol           = "stratum+ssl"
                    Host               = [String]"$Algorithm.$Region.$PoolHost"
                    Port               = [UInt16]$PoolPort
                    User               = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=', ''))"
                    Pass               = "x"
                    Region             = [String]$Region_Norm
                    SSL                = [Boolean]$true
                    Fee                = $Fee
                    EstimateCorrection = [Decimal]1
                }
            }
        }
    }
}
