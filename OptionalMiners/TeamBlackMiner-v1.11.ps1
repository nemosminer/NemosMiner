using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TBMiner.exe"
$Uri = "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.0b/TeamBlackMiner_1_11_cuda_11_4.7z"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$DeviceEnumerator = @{ AMD = "ID"; NVIDIA = "Type_Vendor_Index" }
$DeviceSelector = @{ AMD = "--cl-devices"; NVIDIA = "--cuda-devices" }

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.005; MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo etchash" } # PhoenixMiner-v5.7b may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.005; MinMemGB = 5.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo ethash" } # PhoenixMiner-v5.7b may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.005; MinMemGB = 2.0; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 20); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "VertHash";     Fee = 0.01;  MinMemGB = 4.0; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo vertcoin" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.005; MinMemGB = 3.0; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo etchash" } # PhoenixMiner-v5.7b may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.005; MinMemGB = 5.0; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo ethash" } # PhoenixMiner-v5.7b may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.005; MinMemGB = 2.0; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(0, 20); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "VertHash";     Fee = 0.01;  MinMemGB = 4.0; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo vertcoin" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model | Where-Object { $_.Type -ne "AMD" -or $_.OpenCL.ClVersion -ge "OpenCL C 1.2" })) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { $MinMemGB = ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum }

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Arguments += " --hostname $($Pools.($_.Algorithm).Host) --port $($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User) --worker_name $($Config.Workername) --server_passwd $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { $Arguments += ",l=$((($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                    If ($Pools.($_.Algorithm).SSL) { $Arguments += " --ssl" }
                    $LogFile = ".\Logs\$($Miner_Name).Log"

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name -replace " "
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments --api --api-port $MinerAPIPort $($DeviceSelector.($_.Type)) [$(($Miner_Devices | Sort-Object $($DeviceEnumerator.($_.Type)) -Unique | ForEach-Object { '{0:x}' -f $_.$($DeviceEnumerator.($_.Type)) }) -join ',')]" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "TeamBlackMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)/threads"
                        LogFile     = $LogFile
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
