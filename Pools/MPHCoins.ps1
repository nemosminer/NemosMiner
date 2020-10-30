using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.UserName) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics" -Headers @{"Cache-Control" = "no-cache" }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $PoolRegions = 'Asia', 'EU', 'US'
    $Fee = 0.009
    $Divisor = 1000000000

    $User = "$($PoolConfig.UserName).$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.return | Where-Object profit | ForEach-Object { 
        $Current = $_
        $Algorithm = $_.algo -replace "-"
        $Algorithm_Norm = Get-Algorithm $Algorithm

        $Block = $null
        If ($Algorithm_Norm -eq "Ethash") { 
            Try { 
                $Block = (Invoke-RestMethod "http://$($_.coin_name).miningpoolhub.com/index.php?page=api&action=public" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop).last_block #correct
            }
            Catch { }
            If ($Topcoin.symbol -eq "ETC" -and (Get-EthashEpoch $Block) -ge 390) { $Algorithm_Norm = "EtcHash" }
        }

        $Coin = (Get-Culture).TextInfo.ToTitleCase($_.coin_name -replace "-" -replace " ")

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm)-$($_.symbol)_Profit" -Value ([Decimal]$_.profit / $Divisor)

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                CoinName           = [String]$Coin
                Currency           = [String]$Current.symbol
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Protocol           = "stratum+tcp"
                Host               = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.port
                User               = $User
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = [Decimal]$Fee
                EstimateFactor     = [Decimal]1
                EthashBlockHeight  = [Int64]$Block
            }

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                CoinName           = [String]$Coin
                Currency           = [String]$Current.symbol
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Protocol           = "stratum+ssl"
                Host               = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.port
                User               = $User
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$true
                Fee                = [Decimal]$Fee
                EstimateFactor     = [Decimal]1
                EthashBlockHeight  = [Int64]$Block
            }
        }
    }
}
