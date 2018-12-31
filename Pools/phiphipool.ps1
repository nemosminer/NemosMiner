if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

try { 
    $Request = Invoke-RestMethod "http://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
} 
catch { return }
 
if (-not $Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".phi-phi-pool.com"
$PriceField = "estimate_current"
$DivisorMultiplier = 1000000
 
$Locations = "asia", "eu", "us"
$Locations | ForEach-Object {
    $PhiPhiPool_Location = $_
        
    switch ($PhiPhiPool_Location) {
        "eu" {$Location = "eu"} #Europe
        "asia" {$Location = "asia"} #Asia [Thailand]
        "us" {$Location = "us"} #USA
        default {$Location = "asia"}
    }
    
    # Placed here for Perf (Disk reads)
    $ConfName = if ($Config.PoolsConfig.$Name -ne $Null) {$Name}else {"default"}
    $PoolConf = $Config.PoolsConfig.$ConfName

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $PoolHost = "$($Location)$($HostSuffix)"
        $PoolPort = $Request.$_.port
        $PoolAlgorithm = Get-Algorithm $Request.$_.name

        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

        if ((Get-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100)))}
        else {$Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100)))}

        $PwdCurr = if ($PoolConf.PwdCurrency) {$PoolConf.PwdCurrency}else {$Config.Passwordcurrency}
        $WorkerName = If ($PoolConf.WorkerName -like "ID=*") {$PoolConf.WorkerName} else {"ID=$($PoolConf.WorkerName)"}

        if ($PoolConf.Wallet) {
            [PSCustomObject]@{
                Algorithm     = $PoolAlgorithm
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $PoolHost
                Port          = $PoolPort
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName)"
                Pass          = "c=$($PwdCurr)"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
