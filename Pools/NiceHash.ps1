using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -TimeoutSec 15 -Headers @{"Cache-Control" = "no-cache" }
        $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -TimeoutSec 15 -Headers @{"Cache-Control" = "no-cache" }
        $Request.miningAlgorithms | ForEach-Object { $Algo = $_.Algorithm ; $_ | Add-Member -Force @{algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algo } } }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $PoolHost = "nicehash.com"

    $PoolRegions = "br", "eu", "hk", "in", "jp", "usa"

    If ($PoolConfig.NiceHashWalletIsInternal) { 
        $Fee = [Decimal]0.02
    }
    Else { 
        $Fee = [Decimal]0.05
    }

    $User = "$($PoolConfig.Wallet).$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.miningAlgorithms | Where-Object speed -GT 0 | ForEach-Object { 
        $Algorithm = $_.Algorithm
        $PoolPort = $_.algodetails.port
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $DivisorMultiplier = 1000000000
        $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.marketFactor
        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor)

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]0
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Host               = [String]"$Algorithm.$Region.$PoolHost"
                Port               = [UInt16]$PoolPort
                User               = [String]$User
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Boolean]$false
                Fee                = [Decimal]$Fee
                EstimateFactor     = [Decimal]1
            }

            # If ($Algorithm_Norm -match "CryptonightR|Equihash1445|Randomx") { 
            #     [PSCustomObject]@{ 
            #         Algorithm          = [String]$Algorithm_Norm
            #         Price              = [Double]$Stat.Live
            #         StablePrice        = [Double]$Stat.Week
            #         MarginOfError      = [Double]0
            #         PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
            #         Host               = [String]"$Algorithm.$Region.$PoolHost"
            #         Port               = [UInt16]$PoolPort
            #         User               = [String]$User
            #         Pass               = "x"
            #         Region             = [String]$Region_Norm
            #         SSL                = [Boolean]$true
            #         Fee                = [Decimal]$Fee
            #         EstimateFactor     = [Decimal]1
            #     }
            # }
        }
    }
}
