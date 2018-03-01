. .\Include.ps1

try { $MiningPoolHub_Request = Invoke-WebRequest "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $MiningPoolHub_Request.success) {
    return
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Locations = 'Europe', 'US', 'Asia'

$Locations | ForEach-Object {
    $Location = $_

    $MiningPoolHub_Request.return | ForEach-Object {
        $Algorithm = $_.algo -replace "-"
        $Coin = (Get-Culture).TextInfo.ToTitleCase(($_.current_mining_coin -replace "-", " ")) -replace " "

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm)_Profit" -Value ([decimal]$_.profit / 1000000000)
        $Price = (($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1))) + ($Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1))))
        
        [PSCustomObject]@{
            Algorithm   = $Algorithm
            Info        = $Coin
            Price       = $Price
            StablePrice = $Stat.Week
            Protocol    = 'stratum+tcp'
            Host        = $_.all_host_list.split(";") | Sort-Object -Descending {$_ -ilike "$Location*"} | Select-Object -First 1
            Port        = $_.algo_switch_port
            User        = '$UserName.$WorkerName'
            Pass        = 'x'
            Location    = $Location
            SSL         = $false
        }
        
        [PSCustomObject]@{
            Algorithm   = $Algorithm
            Info        = $Coin
            Price       = $Price
            StablePrice = $Stat.Week
            Protocol    = 'stratum+ssl'
            Host        = $_.all_host_list.split(";") | Sort-Object -Descending {$_ -ilike "$Location*"} | Select-Object -First 1
            Port        = $_.algo_switch_port
            User        = '$UserName.$WorkerName'
            Pass        = 'x'
            Location    = $Location
            SSL         = $true
        }
    }
}
