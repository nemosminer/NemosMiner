using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\sgminer.exe"
$Uri = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.7.5-0/sgminer-fancyIX-win64-0.7.5.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "NeoscryptXaya"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt-xaya" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "AMD" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object { 

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" })) { 

                    If ($Miner_Devices.Model -match "^RadeonRX[56]\d\d\d") { $_.Arguments += "_navi" }

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Protocol = "stratum+tcp"
                    If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace "tcp", "ssl" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = "AMD"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --api-listen --api-port $MinerAPIPort --gpu-platform $($Miner_Devices.PlatformId | Sort-Object -Unique) --device $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Xgminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
