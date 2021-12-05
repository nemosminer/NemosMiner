using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\kawpowminer.exe"
$Uri = "https://github.com/RavenCommunity/kawpowminer/releases/download/1.2.3/kawpowminer-windows-1.2.3.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
   [PSCustomObject]@{ Algorithm = "KawPoW"; MinMemGB = 3; MinerSet = 2; WarmupTimes = @(0, 15); Arguments = "" } # XmRig-v6.16.2 is faster
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($AvailableMiner_Devices = @($Miner_Devices | Where-Object { [Uint]($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("--pool stratum$(If ($Pools.($_.Algorithm).SSL) { "s" } )+tcp://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm).User)):$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm).Pass))@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-port -$($MinerAPIPort) --cuda --cuda-devices $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
