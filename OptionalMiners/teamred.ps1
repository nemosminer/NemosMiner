if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\AMD-teamred0718\teamredminer.exe"
$Uri = "https://github.com/todxx/teamredminer/releases/download/0.7.18/teamredminer-v0.7.18-win.zip"

$Commands = [PSCustomObject]@{
    "ethash" = " --algo ethash" #ethash
    "etchash"= " --algo etchash" #etchash
    "kawpow" = " --algo kawpow" #kawpow
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type      = "AMD"
        Path      = $Path
        Arguments = "--temp_limit=90 --eth_stratum_mode=nicehash --pool_no_ensub --disable_colors --api_listen=127.0.0.1:$($Variables.AMDMinerAPITCPPort) --url=stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) --user=$($Pools.$Algo.User) --pass=$($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99 } # substract 1% devfee
        API       = "teamred"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
