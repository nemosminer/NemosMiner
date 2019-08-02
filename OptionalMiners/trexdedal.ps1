if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-trex011dedal\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.11.0/t-rex-0.11.0-win-cuda10.0.zip"

$Commands = [PSCustomObject]@{
    "dedal"      = " -a dedal -i 23" #Dedal
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
     $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--no-watchdog --no-nvml --gpu-report-interval 25 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) --quiet -R 1 -T 50000 --cpu-priority 4"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99 } # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
