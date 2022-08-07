using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v1.8z3_win-x64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "AMD"; Fee = @(0.02);   MinMemGB = 4.0;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=beam3 --pers=Beam-PoW" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 3.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA");         Arguments = " --amd --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA");         Arguments = " --amd --par=144,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA");         Arguments = " --amd --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.3;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=192,7 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA");         Arguments = " --amd --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";      Type = "AMD"; Fee = @(0.02);   MinMemGB = 3.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA");         Arguments = " --amd --par=144,5 --pers BgoldPoW" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";      Type = "AMD"; Fee = @(0.02);   MinMemGB = 3.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=192,7 --pers ZcashPoW" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=EtcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=Ethash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EthashLowMem";     Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=Ethash --dag-fix" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";          Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."FiroPoW".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --pers=firo" }
    [PSCustomObject]@{ Algorithm = "KawPoW";           Type = "AMD"; Fee = @(0.01);   MinMemGB = $MinerPools[0]."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --par=Kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";      Type = "AMD"; Fee = @(0.01);   MinMemGB = 8.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";      Type = "AMD"; Fee = @(0.01);   MinMemGB = 8.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock"; Type = "AMD"; Fee = @(0.01);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";      Type = "AMD"; Fee = @(0.01);   MinMemGB = 8.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA"); Arguments = " --amd --pers=zano" }

    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 4.0;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=beam3 --pers=Beam-PoW --ocX" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 3.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=125,4 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=144,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=150,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.3;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=192,7 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=210,9 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=96,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 3.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=144,5 --pers BgoldPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 3.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --par=192,7 --pers ZcashPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=EtcHash --dag-fix  --ocX" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=Ethash --dag-fix --ocX" }
    [PSCustomObject]@{ Algorithm = "EthashLowMem";     Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=Ethash --dag-fix --ocX" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0]."FiroPoW".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(55, 45); Arguments = " --nvidia --pers=firo --ocX" }
    [PSCustomObject]@{ Algorithm = "KawPoW";           Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = $MinerPools[0]."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 35); Arguments = " --nvidia --par=Kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=sero --ocX" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=veil --ocX" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock"; Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 2.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=VeriBlock --ocX" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=zano --ocX" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB) | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("par", "pers", "ocX") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --url $(If ($MinerPools[0].($_.Algorithm).SSL) { "ssl://" } )$($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" })@$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).Port)"
                $_.Arguments += " --pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $_.Arguments += " --worker $($MinerPools[0].($_.Algorithm).WorkerName)" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceNames    = $AvailableMiner_Devices.Name
                    Type            = $AvailableMiner_Devices.Type
                    Path            = $Path
                    Arguments       = ("$($_.Arguments) --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 10 --latency --all-shares --extra --tempunits C --show-pers --fee-time=60 --telemetry $MinerAPIPort -cd $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithms      = @($_.Algorithm)
                    API             = "MiniZ"
                    Port            = $MinerAPIPort
                    URI             = $Uri
                    Fee             = $_.Fee # Dev fee
                    MinerUri        = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes     = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
