using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-aes-sse2.exe"
$Uri = "https://github.com/patrykwnosuch/cpuminer-nosuch/releases/download/3.8.8.1-nosuch-m4/cpu-nosuch-m4-win64.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BinariumV1"; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo binarium-v1" }
    [PSCustomObject]@{ Algorithm = "m7m";        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo m7m" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($AvailableMiner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        If ($AvailableMiner_Devices.CpuFeatures -match "sha")      { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha.exe" }
        ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx2") { $Path = ".\Bin\$($Name)\cpuminer-avx2.exe" }
        ElseIf ($AvailableMiner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-aes-sse2.exe" }
        ElseIf ($AvailableMiner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-sse2.exe" }
        Else { Return }

        $AvailableMiner_Devices | Select-Object Model -Unique | ForEach-Object { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-'

            $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).SSL) { $Protocol = "stratum+ssl" } Else { $Protocol = "stratum+tcp" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name -replace " "
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = "CPU"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                }
            }
        }
    }
}
