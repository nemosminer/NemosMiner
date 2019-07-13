if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

try {
    $Request = Invoke-WebRequest "https://api.nicehash.com/api?method=simplemultialgo.info" -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
}
catch { return }

if (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

# Placed here for Perf (Disk reads)
$ConfName = if ($Config.PoolsConfig.$Name -ne $Null) { $Name }else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName


$Request.result.simplemultialgo | ForEach-Object {
    $Algo = $_.Name
    $NiceHash_Port = $_.port
    $NiceHash_Algorithm = Get-Algorithm $_.name
    $NiceHash_Coin = ""

    $Divisor = 1000000000

    $Stat = Set-Stat -Name "$($Name)_$($NiceHash_Algorithm)_Profit" -Value ([Double]$_.paying / $Divisor)

    $Locations = "eu", "usa", "jp"
    $Locations | ForEach-Object {
        $NiceHash_Location = $_
        
        switch ($NiceHash_Location) {
            "eu" { $Location = "EU" }
            "usa" { $Location = "US" }
            "jp" { $Location = "JP" }
        }
        $NiceHash_Host = "$($Algo).$NiceHash_Location.nicehash.com"

        if ($PoolConf.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=',''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $false
            }

            [PSCustomObject]@{
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+ssl"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=',''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $true
            }
        }
    }
}
