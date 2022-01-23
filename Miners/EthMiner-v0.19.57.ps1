using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Minerx117/ethminer/releases/download/v0.19.0-r5.57/ethminer0190r57.7z"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ethminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001
# NVIDIA Enable Hardware-Accelerated GPU Scheduling

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4.0; Type = "AMD";    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 3.0; Type = "AMD";    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4.0; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v5.9d is fastest but has dev fee
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 4.0; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -eq $_.Type | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @() -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $Protocol = "--pool stratum2+tcp" }
                ElseIf ($Pools.($_.Algorithm).BaseName -eq "HiveON") { $Protocol = "--pool stratum1+tcp" }
                Else { $Protocol = "--pool stratum+tcp" }

                If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace "tcp", "ssl" }

                If ($Pools.($_.Algorithm).BaseName -eq "MiningPoolHub") { $_.WarmupTimes[0] += 30 }

                $Pass = $($Pools.($_.Algorithm).Pass)
                If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm).User)):$Pass@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --api-port -$MinerAPIPort $($_.Arguments) $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
