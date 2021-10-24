using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\suprminer.exe"
$Uri = "https://github.com/ocminer/suprminer-releases/raw/main/suprminer-winx86_64_cuda11_1.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "HeavyHash"; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --algo obtc" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($AvailableMiner_Devices = @($Miner_Devices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "statsavg") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name -replace " "
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Ccminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = 0.01
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
