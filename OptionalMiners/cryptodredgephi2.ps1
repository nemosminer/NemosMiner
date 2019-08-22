if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\NVIDIA-CryptoDredge021c10phi2\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.21.0/CryptoDredge_0.21.0_cuda_10.0_windows.zip"

$Commands = [PSCustomObject]@{
    "phi2" = ",mc=SPDR/AGM --intensity 8 -a phi2" #Phi2 
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    If ($Algo -eq "phi2" -and $Pools.($Algo).Host -notlike "*zergpool*") { return } #temp fix for LUX zergpool
    switch ($_) {
        "mtp" { $Fee = 0.02 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }

    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--timeout 60 --api-type ccminer-tcp --cpu-priority 4 --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
