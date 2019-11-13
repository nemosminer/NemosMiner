if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-Opt4023a\cpuminer-sse42.exe" #Intel
#$Path = ".\Bin\CPU-Opt4023a\cpuminer-ryzen.exe" #AMD
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/4.0.23a/cpuminer-rplant-4.0.23a-win.7z"

$Commands = [PSCustomObject]@{
    "yescryptr8"  = " -a yescryptr8" #YescryptR8 
    "yescryptr8g" = " -a yescryptr8g" #YescryptR8g     
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {

    $ThreadCount = $Variables.ProcessorCount - 2 

    If ($Algo -eq "yescryptr8" -and $Pools.$Algo.Host -like "*nlpool*") { return }
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -o $($Pools.$Algo.Protocol)://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
