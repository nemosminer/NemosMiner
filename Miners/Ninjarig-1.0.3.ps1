<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        4.3.6.2
Version date:   2023/08/25
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://github.com/Minerx117/miner-binaries/releases/download/v1.0.3/ninjarig_v1.0.3.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ninjarig.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Chukwa"; Minerset = 2; WarmupTimes = @(30, 0); Arguments = " -a argon2/chukwa" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $AvailableMiner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)

        $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

        $Algorithms | ForEach-Object { 

            If ($AllMinerPools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $Arguments += " --nicehash" } 
            If ($AllMinerPools.($_.Algorithm).PoolPorts[1]) { $Arguments += " --tls" }

            [PSCustomObject]@{ 
                Algorithms  = @($_.Algorithm)
                API         = "XmRig"
                Arguments   = ("$($_.Arguments) --url stratum+tcp://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --keepalive --api-port=$MinerAPIPort --donate-level 0 -R 1 --use-gpu=CUDA -t $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                DeviceNames = $AvailableMiner_Devices.Name
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