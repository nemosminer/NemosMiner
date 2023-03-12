If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v2.0c4_win-x64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "AMD"; Fee = @(0.02);   MinMemGiB = 4.0;                                           Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=beam3 --pers=Beam-Pow" } # Lots of bad shares
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 3.0;                                           Minerset = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          Arguments = " --amd --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          Arguments = " --amd $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--par=144,5")" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 4.0;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          Arguments = " --amd --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.3;                                           MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1", "RDNA2"); Arguments = " --amd $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--par=192,7")" } #FPGA
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          Arguments = " --amd --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.80;      Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=EtcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.80;       Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=Ethash --dag-fix" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";     Type = "AMD"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.80; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=Ethash --dag-fix" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].FiroPow.DAGSizeGiB + 0.80;      Minerset = 2; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --pers=firo" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01);   MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.80;       Minerset = 2; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=Kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = $MinerPools[0].ProgPowSero.DAGSizeGiB + 0.80;  Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=progpow --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 8.0;                                           Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=progpow --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01);   MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=progpow --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = $MinerPools[0].ProgPowZano.DAGSizeGiB + 0.80;  Minerset = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("CGN1", "CGN2", "CGN3", "CGN4", "RDNA1");          Arguments = " --amd --par=progpow --pers=zano" }

    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;                                           Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=beam3 --pers=Beam-Pow" } # Lots of bad shares
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 3.0;                                           MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;                                           MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--par=144,5")" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;                                           MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.3;                                           MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--par=192,7")" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;                                           Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;                                           Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.80;      Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=EtcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.80;       Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=Ethash --dag-fix" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";     Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.80; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=Ethash --dag-fix" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = $MinerPools[0].FiroPow.DAGSizeB + 0.80;        Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --pers=firo" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.80;       Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --par=Kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = $MinerPools[0].ProgPowSero.DAGSizeGiB + 0.80;  Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 8.0;                                           Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 2.0;                                           Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = $MinerPools[0].ProgPowZano.DAGSizeGiB+ 0.80;   Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); Arguments = " --nvidia --pers=zano" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            # Temp fix https://bitcointalk.org/index.php?topic=4767892.msg61406193#msg61406193
            $MinMemGiB = If ($MinerPools[0].($_.Algorithm).DAGSizeGiB -and $MinerPools[0].($_.Algorithm).DAGSizeGiB_-lt 7) { 7 } Else { $_.MinMemGiB }

            If ($AvailableMiner_Devices = ($Miner_Devices | Where-Object MemoryGiB -ge $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture)) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("amd", "dag-fix", "nvidia", "ocX", "par", "pers", "smart-pers") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --url=$(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "ssl://" } )$($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" })@$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1)"
                $Arguments += " --pass=$($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " --worker=$($MinerPools[0].($_.Algorithm).WorkerName)" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms   = @($_.Algorithm)
                    API          = "MiniZ"
                    Arguments    = ("$($Arguments) --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int=10 --nohttpheaders --latency --all-shares --extra --tempunits=C --show-pers --fee-time=60 --telemetry $MinerAPIPort -cd $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d2}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    DeviceNames  = $AvailableMiner_Devices.Name
                    Fee          = $_.Fee # Dev fee
                    MinerSet     = $_.MinerSet
                    MinerUri     = "http://127.0.0.1:$($MinerAPIPort)"
                    Name         = $Miner_Name
                    Path         = $Path
                    Port         = $MinerAPIPort
                    Type         = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI          = $Uri
                    WarmupTimes  = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}

$Error.Clear()