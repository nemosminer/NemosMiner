using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object Type -eq "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v1.8y4rc2_win-x64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BeamV3";       MinMemGB = 4.0; Fee = 0.02;   MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --par=beam3 --pers=Beam-PoW --ocX" } # NBMiner-v39.5 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1254"; MinMemGB = 3.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=125,4 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1445"; MinMemGB = 2.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=144,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1505"; MinMemGB = 2.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=150,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1927"; MinMemGB = 2.3; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=192,7 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash2109"; MinMemGB = 2.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=210,9 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash965";  MinMemGB = 2.0; Fee = 0.02;   MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --par=96,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";  MinMemGB = 3.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=144,5 --pers BgoldPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";  MinMemGB = 3.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=192,7 --pers ZcashPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4.0; Fee = 0.0075; MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --par=Ethash --ocX" }
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 2.0; Fee = 0.0075; MinerSet = 1; WarmupTimes = @(20, 15); Arguments = " --par=Ethash --ocX" } # TTMiner-v5.0.3 is fastest (disabled; https://bitcointalk.org/index.php?topic=4767892.msg57522310#msg57522310)
    [PSCustomObject]@{ Algorithm = "EtcHash";      MinMemGB = 5.0; Fee = 0.0075; MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --par=EtcHash --ocX" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(45, 35); Arguments = " --par=Kawpow --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "Veil";         MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=ProgPow --pers=veil --ocX" }
    [PSCustomObject]@{ Algorithm = "Veriblock";    MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=ProgPowZ --pers=zano --ocX" }
    [PSCustomObject]@{ Algorithm = "Zano";         MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --par=vProgPow --pers=VeriBlock --ocX" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("par", "pers", "ocX") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Pass = " --pass $($Pools.($_.Algorithm).Pass)"
                If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                If ($Config.UseMinerTweaks -eq $true) { 
                    $_.Arguments += " --oc1"
                }

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceName      = $AvailableMiner_Devices.Name
                    Type            = "NVIDIA"
                    Path            = $Path
                    Arguments       = ("$($_.Arguments) --url $(If ($Pools.($_.Algorithm).SSL) { "ssl://" } )$($Pools.($_.Algorithm).User)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)$Pass --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 10 --latency --all-shares --extra --tempunits C --show-pers --fee-time=60 --telemetry $($MinerAPIPort) --cuda-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
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
