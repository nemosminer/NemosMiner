using module ..\Includes\Include.psm1

Try { 
    $Request = Invoke-WebRequest "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
}
Catch { return }

If (-not $Request.success) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$PoolRegions = 'EU', 'US', 'Asia'
$Fee = 0.0090

# Placed here for Perf (Disk reads)
$ConfName = If ($PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $PoolsConfig.$ConfName
$Divisor = 1000000000

$Request.return | ForEach-Object { 
    $Current = $_
    $Algorithm = $_.algo -replace "-"
    $Algorithm_Norm = Get-Algorithm $Algorithm
    $Coin = (Get-Culture).TextInfo.ToTitleCase(($_.current_mining_coin -replace "-") -replace " ")

    $Stat = Set-Stat -Name "$($Name)_$($Algorithm)_Profit" -Value ([decimal]$_.profit / $Divisor * (1 - $Fee))
    $Price = (($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1))) + ($Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1))))

    $PoolRegions | ForEach-Object { 
        $Region = $_
        $Region_Norm = Get-Region $Region

        [PSCustomObject]@{ 
            Algorithm          = [String]$Algorithm_Norm
            CoinName           = [String]$Coin
            Price              = [Double]$PoolConf.EstimateCorrection
            StablePrice        = [Double]$Stat.Week
            EstimateCorrection = [Double]$PoolConf.EstimateCorrection
            Protocol           = "stratum+tcp"
            Host               = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
            Port               = [UInt16]$Current.algo_switch_port
            User               = "$($PoolConf.UserName).$($PoolConf.WorkerName.replace('ID=', ''))"
            Pass               = 'x'
            Region             = [String]$Region_Norm
            SSL                = [Bool]$false
            Fee                = [Decimal](0.9 / 100)
        }

        [PSCustomObject]@{ 
            Algorithm          = [String]$Algorithm_Norm
            CoinName           = [String]$Coin
            Price              = [Double]$Stat.Live
            StablePrice        = [Double]$Stat.Week
            EstimateCorrection = [Double]$PoolConf.EstimateCorrection
            Protocol           = "stratum+ssl"
            Host               = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
            Port               = [UInt16]$Current.algo_switch_port
            User               = "$($PoolConf.UserName).$($PoolConf.WorkerName.replace('ID=', ''))"
            Pass               = 'x'
            Region             = [String]$Region_Norm
            SSL                = [Bool]$true
            Fee                = [Decimal](0.9 / 100)
        }
    }
}
