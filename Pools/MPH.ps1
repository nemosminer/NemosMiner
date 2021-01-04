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
    $Fee = [Decimal]0.009
    $Divisor = 1000000000

    $User = "$($PoolConfig.UserName).$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.return | Where-Object profit | ForEach-Object { 
        $Current = $_
        $Algorithm = $_.algo -replace "-"
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Coin = (Get-Culture).TextInfo.ToTitleCase($_.current_mining_coin -replace "-" -replace " ")

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Decimal]$_.profit / $Divisor)

        If ($Current.all_host -eq "hub.miningpoolhub.com") { 
            $PoolRegions = @("US")
            $Current.all_host_list = $Current.all_host
        }
        Else { 
            # Temp fix for Ethash https://bitcointalk.org/index.php?topic=472510.msg55320676# msg55320676
            If ($Algorithm_Norm -in @("EtcHash", "Ethash", "KawPow")) { 
                $PoolRegions = @("Asia", "US")
            }
            Else {
                $PoolRegions = @("Asia", "EU", "US")
            }
        }

        $PoolRegions | ForEach-Object { 
            $Region = $_
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                CoinName           = [String]$Coin
                Currency           = [String]$Current.current_mining_coin_symbol
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Host               = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.algo_switch_port
                User               = [String]$User
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = [Decimal]$Fee
                EstimateFactor     = [Decimal]1
            }

            [PSCustomObject]@{ 
                Algorithm          = [String]$Algorithm_Norm
                CoinName           = [String]$Coin
                Currency           = [String]$Current.current_mining_coin_symbol
                Price              = [Double]$Stat.Live
                StablePrice        = [Double]$Stat.Week
                MarginOfError      = [Double]$Stat.Week_Fluctuation
                PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
                Host               = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.algo_switch_port
                User               = [String]$User
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$true
                Fee                = [Decimal]$Fee
                EstimateFactor     = [Decimal]1
            }
        }
    }
}
