using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("NVIDIA"))) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v1.8z_win-x64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    # [PSCustomObject]@{ Algorithm = "BeamV3";       Type = "AMD"; MinMemGB = 4.0; Fee = 0.02;                                              MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --par=beam3 --pers=Beam-PoW --ocX" } # NBMiner-v40.1 is fastest
    # [PSCustomObject]@{ Algorithm = "Equihash1254"; Type = "AMD"; MinMemGB = 3.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=125,4 --smart-pers --ocX" }
    # [PSCustomObject]@{ Algorithm = "Equihash1445"; Type = "AMD"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=144,5 --smart-pers --ocX" }
    # [PSCustomObject]@{ Algorithm = "Equihash1505"; Type = "AMD"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=150,5 --smart-pers --ocX" }
    # [PSCustomObject]@{ Algorithm = "Equihash1927"; Type = "AMD"; MinMemGB = 2.3; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=192,7 --smart-pers --ocX" }
    # [PSCustomObject]@{ Algorithm = "Equihash2109"; Type = "AMD"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=210,9 --smart-pers --ocX" }
    # [PSCustomObject]@{ Algorithm = "Equihash965";  Type = "AMD"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --par=96,5 --smart-pers --ocX" }
    # [PSCustomObject]@{ Algorithm = "EquihashBTG";  Type = "AMD"; MinMemGB = 3.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=144,5 --pers BgoldPoW --ocX" }
    # [PSCustomObject]@{ Algorithm = "EquihashZCL";  Type = "AMD"; MinMemGB = 3.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=192,7 --pers ZcashPoW --ocX" }
    # [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; MinMemGB = ($Pools."EtcHash".DAGSize + 0.95GB) / 1GB; Fee = 0.0075;      MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --par=EtcHash --ocX" }
    # [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; MinMemGB = ($Pools."Ethash".DAGSize + 0.95GB) / 1GB; Fee = 0.0075;       MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --par=Ethash --ocX" }
    # [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; MinMemGB = ($Pools."EthashLowMem".DAGSize + 0.95GB) / 1GB; Fee = 0.0075; MinerSet = 1; WarmupTimes = @(45, 15); Arguments = " --par=Ethash --ocX" } # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "FiroPoW";      Type = "AMD"; MinMemGB = 5;                                                            MinerSet = 1; WarmupTimes = @(55, 45); Arguments = " --par=ProgPow --pers=firo --ocX" }
    # [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "AMD"; MinMemGB = ($Pools."KawPoW".DAGSize + 0.95GB) / 1GB; Fee = 0.01;         MinerSet = 0; WarmupTimes = @(45, 35); Arguments = " --par=Kawpow --pers=RAVENCOINKAWPOW" }
    # [PSCustomObject]@{ Algorithm = "Veil";         Type = "AMD"; MinMemGB = 8.0; Fee = 0.01;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=ProgPow --pers=veil --ocX" }
    # [PSCustomObject]@{ Algorithm = "Veriblock";    Type = "AMD"; MinMemGB = 8.0; Fee = 0.01;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=ProgPowZ --pers=zano --ocX" }
    # [PSCustomObject]@{ Algorithm = "Zano";         Type = "AMD"; MinMemGB = 2.0; Fee = 0.01;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=vProgPow --pers=VeriBlock --ocX" }

    [PSCustomObject]@{ Algorithm = "BeamV3";       Type = "NVIDIA"; MinMemGB = 4.0; Fee = 0.02;                                              MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --par=beam3 --pers=Beam-PoW --ocX" } # NBMiner-v40.1 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1254"; Type = "NVIDIA"; MinMemGB = 3.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=125,4 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1445"; Type = "NVIDIA"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=144,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1505"; Type = "NVIDIA"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=150,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1927"; Type = "NVIDIA"; MinMemGB = 2.3; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=192,7 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash2109"; Type = "NVIDIA"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=210,9 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash965";  Type = "NVIDIA"; MinMemGB = 2.0; Fee = 0.02;                                              MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --par=96,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";  Type = "NVIDIA"; MinMemGB = 3.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=144,5 --pers BgoldPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";  Type = "NVIDIA"; MinMemGB = 3.0; Fee = 0.02;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=192,7 --pers ZcashPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; MinMemGB = ($Pools."EtcHash".DAGSize + 0.95GB) / 1GB; Fee = 0.0075;      MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --par=EtcHash --ocX" }
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; MinMemGB = ($Pools."Ethash".DAGSize + 0.95GB) / 1GB; Fee = 0.0075;       MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --par=Ethash --ocX" }
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; MinMemGB = ($Pools."EthashLowMem".DAGSize + 0.95GB) / 1GB; Fee = 0.0075; MinerSet = 1; WarmupTimes = @(45, 15); Arguments = " --par=Ethash --ocX" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";      Type = "NVIDIA"; MinMemGB = 5;                                                            MinerSet = 1; WarmupTimes = @(55, 45); Arguments = " --par=ProgPow --pers=firo --ocX" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; MinMemGB = ($Pools."KawPoW".DAGSize + 0.95GB) / 1GB; Fee = 0.01;         MinerSet = 0; WarmupTimes = @(45, 35); Arguments = " --par=Kawpow --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "Veil";         Type = "NVIDIA"; MinMemGB = 8.0; Fee = 0.01;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=ProgPow --pers=veil --ocX" }
    [PSCustomObject]@{ Algorithm = "Veriblock";    Type = "NVIDIA"; MinMemGB = 8.0; Fee = 0.01;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=ProgPowZ --pers=zano --ocX" }
    [PSCustomObject]@{ Algorithm = "Zano";         Type = "NVIDIA"; MinMemGB = 2.0; Fee = 0.01;                                              MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=vProgPow --pers=VeriBlock --ocX" }
    )

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("par", "pers", "ocX") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --url $(If ($Pools.($_.Algorithm).SSL) { "ssl://" } )$($Pools.($_.Algorithm).User)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)"
                $_.Arguments += " --pass $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum - 0.95GB) / 1GB)" })"

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceName      = $AvailableMiner_Devices.Name
                    Type            = $AvailableMiner_Devices.Type
                    Path            = $Path
                    Arguments       = ("$($_.Arguments) --$($_.Type.ToLower()) --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 10 --latency --all-shares --extra --tempunits C --show-pers --fee-time=60 --telemetry $MinerAPIPort --cuda-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm       = $_.Algorithm
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
