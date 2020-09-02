using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$PoolConfig,
    [Hashtable]$Variables
)

If ($PoolConfig.UserName) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -Headers @{"Cache-Control" = "no-cache" }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
    $PoolRegions = 'EU', 'US', 'Asia'
    $Fee = 0.0090
    $Divisor = 1000000000

    $User = "$($PoolConfig.UserName).$($($PoolConfig.WorkerName -replace "^ID="))"
    
    $Request.return | Where-Object profit | ForEach-Object { 
        $Current = $_
        $Algorithm = $_.algo -replace "-"
        $Algorithm_Norm = Get-Algorithm $Algorithm

        $Coin = (Get-Culture).TextInfo.ToTitleCase(($_.current_mining_coin -replace "-") -replace " ")

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm)_Profit" -Value ([Decimal]$_.profit / $Divisor)

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                CoinName           = [String]$Coin
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Protocol           = "stratum+tcp"
                Host               = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.algo_switch_port
                User               = $User
                Pass               = 'x'
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = [Decimal](0.9 / 100)
                EstimateFactor     = [Decimal]1
            }

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                CoinName           = [String]$Coin
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Protocol           = "stratum+ssl"
                Host               = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.algo_switch_port
                User               = $User
                Pass               = 'x'
                Region             = [String]$Region_Norm
                SSL                = [Bool]$true
                Fee                = [Decimal](0.9 / 100)
                EstimateFactor     = [Decimal]1
            }
        }
    }
}
