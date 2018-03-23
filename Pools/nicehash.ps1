. .\Include.ps1

try {
    $NiceHash_Request = Invoke-WebRequest "https://api.nicehash.com/api?method=simplemultialgo.info" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $NiceHash_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Locations = "eu", "usa", "hk", "jp", "in", "br"

$Locations | ForEach-Object {
    $NiceHash_Location = $_
    
    switch ($NiceHash_Location) {
        "eu" {$Location = "Europe"}
        "usa" {$Location = "US"}
        "jp" {$Location = "JP"}
        default {$Location = "Asia"}
    }
    
    $NiceHash_Request.result.simplemultialgo | ForEach-Object {
        $NiceHash_Host = "$($_.name).$NiceHash_Location.nicehash.com"
        $NiceHash_Port = $_.port
        $NiceHash_Algorithm = Get-Algorithm $_.name
        $NiceHash_Coin = ""

        $Divisor = 1000000000

        $Stat = Set-Stat -Name "$($Name)_$($NiceHash_Algorithm)_Profit" -Value ([Double]$_.paying / $Divisor)

		$ConfName = if ($Config.PoolsConfig.$Name -ne $Null){$Name}else{"default"}
	
        if ($Config.PoolsConfig.default.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat.Live*$Config.PoolsConfig.$ConfName.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($Config.PoolsConfig.$ConfName.Wallet).$($Config.PoolsConfig.$ConfName.WorkerName.Replace('ID=',''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $false
            }

            [PSCustomObject]@{
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat.Live*$Config.PoolsConfig.$ConfName.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+ssl"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($Config.PoolsConfig.$ConfName.Wallet).$($Config.PoolsConfig.$ConfName.WorkerName.Replace('ID=',''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $true
            }
        }
    }
}
