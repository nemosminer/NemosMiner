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
    $Divisor = 1000000000

    $User = "$($PoolConfig.UserName).$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.return | Where-Object profit | ForEach-Object { 
        $Current = $_
        $Algorithm = $_.algo -replace "-"
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Coin = (Get-Culture).TextInfo.ToTitleCase($_.coin_name -replace "-" -replace " ")
        $Fee = [Decimal]($_.Fee / 100)

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)-$($_.symbol)_Profit" -Value ([Decimal]$_.profit / $Divisor)

        If ($Current.host -eq "hub.miningpoolhub.com") { 
            $PoolRegions = @("US")
            $Current.host_list = $Current.host
        }
        Else { 
            # Temp fix for Ethash https://bitcointalk.org/index.php?topic=472510.msg55320676# msg55320676
            If ($Algorithm_Norm -in @("EtcHash", "Ethash", "KawPoW")) { 
                $PoolRegions = @("Asia", "US")
            }
            Else {
                $PoolRegions = @("Asia", "EU", "US")
            }
        }

        ForEach ($Region in $PoolRegions) { 
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
                Host               = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                Port               = [UInt16]$Current.port
                User               = [String]$User
                Pass               = "x"
                Region             = [String]$Region_Norm
                SSL                = [Bool]$false
                Fee                = $Fee
                EstimateFactor     = [Decimal]1
            }

            # [PSCustomObject]@{ 
            #     Algorithm          = [String]$Algorithm_Norm
            #     CoinName           = [String]$Coin
            #     Currency           = [String]$Current.symbol
            #     Price              = [Double]$Stat.Live
            #     StablePrice        = [Double]$Stat.Week
            #     MarginOfError      = [Double]$Stat.Week_Fluctuation
            #     PricePenaltyfactor = [Double]$PoolConfig.PricePenaltyfactor
            #     Host               = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
            #     Port               = [UInt16]$Current.port
            #     User               = [String]$User
            #     Pass               = "x"
            #     Region             = [String]$Region_Norm
            #     SSL                = [Bool]$true
            #     Fee                = $Fee
            #     EstimateFactor     = [Decimal]1
            # }
        }
    }
}
