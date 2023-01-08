If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "12.0" } { "https://github.com/TrailingStop/TT-Miner-release/releases/download/2022.4.2/TT-Miner-2022.4.2.zip"; Break }
    { $_ -ge "11.0" } { "https://github.com/TrailingStop/TT-Miner-release/releases/download/2022.4.2/TT-Miner-2022.4.2.zip"; Break }
    Default           { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";          Fee = 0.01; MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;     MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo EtcHash -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Fee = 0.01; MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;      MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo Ethash -dag-2disk" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";     Fee = 0.01; MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB;MemReserveGB = 0.41; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo Ethash -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "EvrProPow";        Fee = 0.01; MinMemGB = $MinerPools[0].EvrProgPow.DAGSizeGB;  MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo EvrProgPow -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Fee = 0.01; MinMemGB = $MinerPools[0].FiroPow.DAGSizeGB;     MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo FiroPow -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Fee = 0.02; MinMemGB = 1;                                    MemReserveGB = 0;    Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("Other"); ExcludePool = @("ProHashing", "ZPool"); Arguments = " -algo Ghostrider" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Fee = 0.01; MinMemGB = $MinerPools[0].KawPow.DAGSizeGB;      MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @();        ExcludePool = @("ProHashing");          Arguments = " -algo KawPow -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "Mike";             Fee = 0.02; MinMemGB = 1;                                    MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePool = @();                      Arguments = " -algo Mike" }
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";      Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowEpic.DAGSizeGB; MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo ProgPow -coin EPIC -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowSero.DAGSizeGB; MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo ProgPow -coin SERO -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowVeil.DAGSizeGB; MemReserveGB = 0.42; Minerset = 2; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo ProgPow -coin VEIL -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowZano.DAGSizeGB; MemReserveGB = 0.42; Minerset = 1; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo ProgPowZ -coin ZANO -dag-2disk" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Fee = 0.01; MinMemGB = 1;                                    MemReserveGB = 0;    Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo vProgPow" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Fee = 0.01; MinMemGB = 1;                                    MemReserveGB = 0;    Minerset = 1; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo Sha512256D" }
    [PSCustomObject]@{ Algorithm = "UbqHash";          Fee = 0.01; MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;     MemReserveGB = 0.42; Minerset = 1; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @();        ExcludePool = @();                      Arguments = " -algo UbqHash -dag-2disk" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | ForEach-Object { 

            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB) | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $Arguments = $Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm -ne "PROGPOW" -and $MinerPools[0].($_.Algorithm).Currency -in @("ARL", "BBC", "BTRM", "BUT", "CLO", "ETC", "ETP", "EVOX", "EVR", "EXP", "FIRO", "FITA", "GSPC", "HVQ", "JGC", "KAW", "LAB", "MEOW", "NAPI", "NEOX", "PRCO", "REDE", "RTM", "RVN", "SATO", "THOON", "TTM", "UBQ", "VTE", "YERB", "VBK", "VKAX")) { 
                    $Arguments += " -coin $($MinerPools[0].($_.Algorithm).Currency)"
                }

                $Arguments += If ($MinerPools[0].($_.Algorithm).DAGSizeGB -and $MinerPools[0].($_.Algorithm).BaseName -notin @("MiningPoolHub", "NiceHash")) { " -pool stratum-1+tcp://" } Else { " -pool stratum+tcp://" }
                $Arguments += "$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) -user $($MinerPools[0].($_.Algorithm).User)"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -worker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " -pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("$($Arguments) -api-bind 127.0.0.1:$($MinerAPIPort) -devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
