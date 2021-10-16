using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ninjarig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.0.3/ninjarig_v1.0.3.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Chukwa"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " -a argon2/chukwa" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) {

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($AvailableMiner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).Name -match "NiceHash*|MiningPoolHub*") { $AlgorithmDefinitions.$_ += " --nicehash" } 

                [PSCustomObject]@{ 
                    Name        = $Miner_Name -replace " "
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = "NVIDIA"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)$($AlgorithmDefinitions.$_) --keepalive --api-port=$MinerAPIPort --donate-level 0 -R 1 --use-gpu=CUDA -t $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "XmRig"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                }
            }
        }
    }
}
