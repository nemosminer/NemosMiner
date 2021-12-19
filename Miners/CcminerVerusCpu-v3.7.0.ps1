using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v3.7.0/ccminer_CPU_3.7.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VerusHash"; MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo verus" } # NheqMiner-v0.8.2 is faster, SRBMinerMulti-v0.8.7 is fastest, but has 0.85% miner fee
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    If ($AvailableMiner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

        $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

            # Get arguments for available miner devices
            # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name        = $Miner_Name
                DeviceName  = $AvailableMiner_Devices.Name
                Type        = "CPU"
                Path        = $Path
                Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --statsavg 1 --retry-pause 1 --api-bind $MinerAPIPort" -replace "\s+", " ").trim()
                Algorithm   = $_.Algorithm
                API         = "Ccminer"
                Port        = $MinerAPIPort
                URI         = $Uri
                WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
            }
        }
    }
}
