. .\Include.ps1

$PlusPath = ((split-path -parent (get-item $script:MyInvocation.MyCommand.Path).Directory) + "\BrainPlus\zergpoolplus\zergpoolplus.json")
Try {
    $zergpool_Request = get-content $PlusPath | ConvertFrom-Json 
}
catch { return }

if (-not $zergpool_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Locations = "US", "Europe"

$Locations | ForEach {
    $Location = $_

	$zergpool_Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | foreach {
	    # $zergpool_Host = If ($Location -eq "Europe"){$Location + ".mine.zergpool.com"}else{"$_.mine.zergpool.com"}
	    $zergpool_Host = "$_.mine.zergpool.com"
	    $zergpool_Port = $zergpool_Request.$_.port
	    $zergpool_Algorithm = Get-Algorithm $zergpool_Request.$_.name
	    $zergpool_Coin = ""

	    $Divisor = 1000000000

	    switch ($zergpool_Algorithm) {
		"equihash" {$Divisor /= 1000}
		"blake2s" {$Divisor *= 1000}
		"blakecoin" {$Divisor *= 1000}
		"decred" {$Divisor *= 1000}
		"keccak" {$Divisor *= 1000}
		"keccakc" {$Divisor *= 1000}
	    }

	    if ((Get-Stat -Name "$($Name)_$($zergpool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($zergpool_Algorithm)_Profit" -Value ([Double]$zergpool_Request.$_.actual_last24h / $Divisor)}
	    else {$Stat = Set-Stat -Name "$($Name)_$($zergpool_Algorithm)_Profit" -Value ([Double]$zergpool_Request.$_.actual_last24h / $Divisor)}

		$ConfName = if ($Config.PoolsConfig.$Name -ne $Null){$Name}else{"default"}
	
	    if ($Config.PoolsConfig.default.Wallet) {
		[PSCustomObject]@{
		    Algorithm     = $zergpool_Algorithm
		    Info          = $zergpool
            Price         = $Stat.Live*$Config.PoolsConfig.$ConfName.PricePenaltyFactor
		    StablePrice   = $Stat.Week
		    MarginOfError = $Stat.Fluctuation
		    Protocol      = "stratum+tcp"
		    Host          = $zergpool_Host
		    Port          = $zergpool_Port
            User          = $Config.PoolsConfig.$ConfName.Wallet
		    Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$($Config.Passwordcurrency)"
		    Location      = $Location
		    SSL           = $false
		}
	    }
	}
}
