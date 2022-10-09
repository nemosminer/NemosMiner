using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.Type -eq"NVIDIA" })) { Return }

$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.75/gminer_2_75_windows64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Equihash1927"; Fee = 0.02; MinMemGB = 2.8; Type = "AMD"; Tuning = ""; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo equihash192_7 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--pers auto") --cuda 0 --opencl 1" } # lolMiner-v1.60 is fastest

    [PSCustomObject]@{ Algorithm = "Equihash1927"; Fee = 0.02; MinMemGB = 2.8; Type = "NVIDIA"; Tuning = ""; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo equihash192_7 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--pers auto") --cuda 0 --opencl 1" } # lolMiner-v1.60 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            # Windows 10 requires more memory on some algos
            If ($_.Algorithm -match "Cuckaroo.*|Cuckoo.*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --server $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" })"

                If ($MinerPools[0].($_.Algorithm).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --proto stratum" }
                If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { $_.Arguments += " --ssl 1" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $_.Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "Gminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
