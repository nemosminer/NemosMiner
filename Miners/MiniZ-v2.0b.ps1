If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v2.0b_win-x64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "AMD"; Fee = @(0.02);   MinMemGB = 4.0;                                          MinerSet = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --par=beam3 --pers=Beam-Pow" } # Lots of bad shares
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 3.0;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA1");         Arguments = " --amd --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA1");         Arguments = " --amd $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--par=144,5")" }
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA1");         Arguments = " --amd --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.3;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--par=192,7")" }
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("RDNA1");         Arguments = " --amd --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "AMD"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 1; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --par=EtcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --par=Ethash --dag-fix" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";     Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --par=Ethash --dag-fix" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.0075); MinMemGB = $MinerPools[0].FiroPow.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --pers=firo" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01);   MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;       MinerSet = 0; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --par=Kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01);   MinMemGB = $MinerPools[0].ProgPowSero.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01);   MinMemGB = 8.0;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01);   MinMemGB = 2.0;                                          MinerSet = 0; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "AMD"; Fee = @(0.01);   MinMemGB = $MinerPools[0].ProgPowZano.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("CGN4", "RDNA1"); Arguments = " --amd --pers=zano" }

#   [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 4.0;                                          MinerSet = 1; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=beam3 --pers=Beam-Pow" } # Lots of bad shares
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 3.0;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--par=144,5")" }
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.3;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--par=192,7")" }
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                          MinerSet = 1; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=EtcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=Ethash --dag-fix" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";     Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; MinerSet = 1; Tuning = " --ocX"; WarmupTimes = @(45, 15); Arguments = " --nvidia --par=Ethash --dag-fix" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGB = $MinerPools[0].FiroPow.DAGSizeB + 0.42;       MinerSet = 1; Tuning = " --ocX"; WarmupTimes = @(55, 45); Arguments = " --nvidia --pers=firo" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;       MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 35); Arguments = " --nvidia --par=Kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = $MinerPools[0].ProgPowSero.DAGSizeGB + 0.42;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 2.0;                                          MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(30, 15); Arguments = " --nvidia --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = $MinerPools[0].ProgPowZano.DAGSizeGB+ 0.42;   MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); Arguments = " --nvidia --pers=zano" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture

            # Temp fix https://bitcointalk.org/index.php?topic=4767892.msg61406193#msg61406193
            $MinMemGB = If ($MinerPools[0].($_.Algorithm).DAGSizeGB -and $MinerPools[0].($_.Algorithm).DAGSizeGB_-lt 7) { 7 } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $MinMemGB | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("amd", "dag-fix", "nvidia", "ocX", "par", "pers", "smart-pers") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --url=$(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "ssl://" } )$($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" })@$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1)"
                $Arguments += " --pass=$($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " --worker=$($MinerPools[0].($_.Algorithm).WorkerName)" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceNames    = $AvailableMiner_Devices.Name
                    Type            = ($AvailableMiner_Devices.Type | Select-Object -unique)
                    Path            = $Path
                    Arguments       = ("$($Arguments) --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int=10 --latency --all-shares --extra --tempunits=C --show-pers --fee-time=60 --telemetry $MinerAPIPort -cd $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d2}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithms      = @($_.Algorithm)
                    API             = "MiniZ"
                    Port            = $MinerAPIPort
                    URI             = $Uri
                    Fee             = $_.Fee # Dev fee
                    MinerUri        = "http://127.0.0.1:$($MinerAPIPort)"
                    WarmupTimes     = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
