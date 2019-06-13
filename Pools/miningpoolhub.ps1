if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

try { $Request = Invoke-WebRequest "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $Request.success) {
    return
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Locations = 'EU', 'US', 'Asia'
# Placed here for Perf (Disk reads)
	$ConfName = if ($Config.PoolsConfig.$Name -ne $Null){$Name}else{"default"}
    $PoolConf = $Config.PoolsConfig.$ConfName


    $Request.return | ForEach-Object {
		$Current = $_
        $Algorithm = $_.algo -replace "-"
        $Coin = (Get-Culture).TextInfo.ToTitleCase(($_.current_mining_coin -replace "-", " ")) -replace " "

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm)_Profit" -Value ([decimal]$_.profit / 1000000000)
        $Price = (($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1))) + ($Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1))))

$Locations | ForEach-Object {
    $Location = $_
	
        [PSCustomObject]@{
            Algorithm   = $Algorithm
            Info        = $Coin
            Price       = $Stat.Live*$PoolConf.PricePenaltyFactor
            StablePrice = $Stat.Week
            Protocol    = 'stratum+tcp'
            Host        = $Current.all_host_list.split(";") | Sort-Object -Descending {$Current -ilike "$Location*"} | Select-Object -First 1
            Port        = $Current.algo_switch_port
            User        = "$($PoolConf.UserName).$($PoolConf.WorkerName.replace('ID=',''))"
            Pass        = 'x'
            Location    = $Location
            SSL         = $false
        }
        
        [PSCustomObject]@{
            Algorithm   = $Algorithm
            Info        = $Coin
            Price       = $Stat.Live*$PoolConf.PricePenaltyFactor
            StablePrice = $Stat.Week
            Protocol    = 'stratum+ssl'
            Host        = $Current.all_host_list.split(";") | Sort-Object -Descending {$Current -ilike "$Location*"} | Select-Object -First 1
            Port        = $Current.algo_switch_port
            User        = "$($PoolConf.UserName).$($PoolConf.WorkerName.replace('ID=',''))"
            Pass        = 'x'
            Location    = $Location
            SSL         = $true
        }
    }
}


