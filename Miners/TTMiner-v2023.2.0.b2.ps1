If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.0" } { "https://github.com/TrailingStop/TT-Miner-beta/releases/download/2023.2.0-beta2/TT-Miner-2023.2.0.b2.zip"; Break }
    Default           { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";          Fee = 0.01; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.82;      Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo EtcHash" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Fee = 0.01; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB - 1.00;       Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo Ethash" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";     Fee = 0.01; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.81; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo Ethash" }
    [PSCustomObject]@{ Algorithm = "EvrProPow";        Fee = 0.01; MinMemGiB = $MinerPools[0].EvrProgPow.DAGSizeGiB + 0.82;   Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo EvrProgPow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Fee = 0.01; MinMemGiB = $MinerPools[0].FiroPow.DAGSizeGiB + 1.24;      Minerset = 2; WarmupTimes = @(90, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo FiroPow" }
    [PSCustomObject]@{ Algorithm = "FiroPowSCC";       Fee = 0.01; MinMemGiB = $MinerPools[0].FiroPowSCC.DAGSizeGiB + 0.82;   Minerset = 2; WarmupTimes = @(90, 0);   ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -coin SCC" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Fee = 0.01; MinMemGiB = 1;                                             Minerset = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo Ghostrider" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Fee = 0.01; MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.82;       Minerset = 2; WarmupTimes = @(90, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @("HashCryptos"); Arguments = " -algo KawPow" }
    [PSCustomObject]@{ Algorithm = "Mike";             Fee = 0.01; MinMemGiB = 1;                                             MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo Mike" }
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";      Fee = 0.02; MinMemGiB = $MinerPools[0].ProgPowEpic.DAGSizeGiB + 0.82;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -coin EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Fee = 0.01; MinMemGiB = $MinerPools[0].ProgPowSero.DAGSizeGiB + 0.82;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -coin SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Fee = 0.01; MinMemGiB = $MinerPools[0].ProgPowVeil.DAGSizeGiB + 0.82;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -coin VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Fee = 0.01; MinMemGiB = $MinerPools[0].ProgPowZano.DAGSizeGiB +0.82;   Minerset = 1; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -coin ZANO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Fee = 0.01; MinMemGiB = 1;                                             Minerset = 2; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo vProgPow" }
    [PSCustomObject]@{ Algorithm = "SHA256dt";         Fee = 0.01; MinMemGiB = 1;                                             Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo Sha256dt" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Fee = 0.01; MinMemGiB = 1;                                             Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo Sha512256D" }
    [PSCustomObject]@{ Algorithm = "UbqHash";          Fee = 0.01; MinMemGiB = $MinerPools[0].UbqHash.DAGSizeGiB + 0.82;      Minerset = 1; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePool = @();              Arguments = " -algo UbqHash" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $Arguments = $Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($MinerPools[0].($_.Algorithm).Currency -in @("ARL", "BBC", "BTRM", "BUT", "CLO", "ETC", "ETP", "EVOX", "EVR", "EXP", "FIRO", "FITA", "GSPC", "HVQ", "JGC", "KAW", "LAB", "MEOW", "NAPI", "NEOX", "PRCO", "REDE", "RTM", "RVN", "SATO", "THOON", "TTM", "UBQ", "VTE", "YERB", "VBK", "Mike")) { 
                    $Arguments += " -coin $($MinerPools[0].($_.Algorithm).Currency)"
                }
                $Arguments += If ($MinerPools[0].($_.Algorithm).Protocol -eq "ethproxy" -or $_.Algorithm -eq "ProgPowZano") { " -pool stratum1+tcp://" } ElseIf ($_.Algorithm -eq "Ghostrider") { " -pool stratum3+tcp://" } Else { " -pool stratum+tcp://" }
                $Arguments += "$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) -user $($MinerPools[0].($_.Algorithm).User)"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -worker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " -pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })"
                If (-not $MinerPools[0].($_.Algorithm).SendHashrate) { $Arguments += " -no-hashrate" }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("$($Arguments) -api-bind 127.0.0.1:$($MinerAPIPort) -devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "NVIDIA"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}