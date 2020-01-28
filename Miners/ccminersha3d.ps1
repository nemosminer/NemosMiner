if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") } 
$Path = ".\Bin\NVIDIA-ccminersha3d1.0\ccminer.exe"
$Uri = "https://github.com/brian112358/ccminer-bsha3/releases/download/v1.0/ccminer-bsha3-v1.0-win64.zip"
$Commands = [PSCustomObject]@{ 
    "sha3d" = " -i 27 -d $($Config.SelGPUCC)" #sha3d
} 
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -R 1 -b $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -a keccak -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day } 
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    } 
} 
