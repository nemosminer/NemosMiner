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
Version:        5.0.2.1
Version date:   2023/12/09
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

If ($AvailableMiner_Devices.CpuFeatures -contains "avx2") { $URI = "https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_win64_avx2.zip" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -contains "avx") { $URI = "https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_win64_avx.zip" }
Else { $URI = "https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_win64.zip"}

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\hellminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "VerusHash"; Fee = @(0.01); Minerset = 0; WarmupTimes = @(45, 90); ExcludePools = @(); Arguments = "" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1
    $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

    $Algorithms.ForEach(
        { 
            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools }) | Select-Object -Last 1)) { 

                [PSCustomObject]@{ 
                    API         = "HellMiner"
                    Arguments   = " --pool=stratum+$(If ($Pool.PoolPorts[1]) { "ssl" } Else { "tcp" } )://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user=$($Pool.User) --pass=$($Pool.Pass) --api-port=$MinerAPIPort"
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee # Dev fee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers     = @(@{ Pool = $Pool })
                }
            }
        }
    )
}