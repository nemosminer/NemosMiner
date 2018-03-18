. .\Include.ps1

$PlusPath = ((split-path -parent (get-item $script:MyInvocation.MyCommand.Path).Directory) + "\BrainPlus\phiphipoolplus\phiphipoolplus.json")
Try {
    $phiphipool_Request = get-content $PlusPath | ConvertFrom-Json 
}
catch { return }
 
if (-not $phiphipool_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Locations = "US", "Europe"

$Locations | ForEach {
    $Location = $_

    $phiphipool_Request | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
        $phiphipool_Host = "pool1.phi-phi-pool.com"
        $phiphipool_Port = $phiphipool_Request.$_.port
        $phiphipool_Algorithm = Get-Algorithm $phiphipool_Request.$_.name
        $phiphipool_Coin = ""

        $Divisor = 1000000000

        switch ($phiphipool_Algorithm) {
            "equihash"{$Divisor /= 1000}
			"blake2s"{$Divisor *= 1000}
			"sha256"{$Divisor *= 1000}
			"sha256t"{$Divisor *= 1000}
			"blakecoin"{$Divisor *= 1000}
			"decred"{$Divisor *= 1000}
			"keccak"{$Divisor *= 1000}
			"keccakc"{$Divisor *= 1000}
			"vanilla"{$Divisor *= 1000}
			"x11"{$Divisor *= 1000}
			"scrypt"{$Divisor *= 1000}
			"qubit"{$Divisor *= 1000}
			"yescrypt"{$Divisor /= 1000}
        }

        if ((Get-Stat -Name "$($Name)_$($phiphipool_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_Profit" -Value ([Double]$phiphipool_Request.$_.actual_last24h / $Divisor)}
        else {$Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_Profit" -Value ([Double]$phiphipool_Request.$_.actual_last24h / $Divisor)}
		
        $ConfName = if ($Config.PoolsConfig.$Name -ne $Null) {$Name}else {"default"}
	
        if ($Config.PoolsConfig.default.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $phiphipool_Algorithm
                Info          = $phiphipool
                Price         = $Stat.Live * $Config.PoolsConfig.$ConfName.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $phiphipool_Host
                Port          = $phiphipool_Port
                User          = $Config.PoolsConfig.$ConfName.Wallet
                Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$Passwordcurrency"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}