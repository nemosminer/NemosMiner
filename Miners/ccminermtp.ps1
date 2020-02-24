If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-ccminermtp128\ccminer.exe"
$Uri = "https://github.com/tecracoin/ccminer/releases/download/1.2.8/ccminer.exe"
$Commands = [PSCustomObject]@{ 
     #"mtp" = " -d $($Config.SelGPUCC) -a mtp-classic -i 21" #mtp -i 19 -i 20 -i 21 -i 22
     #"mtptrc" = " -d $($Config.SelGPUCC) -a mtp-tcr -i 21" #mtptrc -i 19 -i 20 -i 21 -i 22
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "mtp" -and $Pools.$Algo.Host -like "*nicehash*") { return }
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-affinity 1 --cpu-priority 4 -R 1 -b $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) --no-donation -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    }
}
