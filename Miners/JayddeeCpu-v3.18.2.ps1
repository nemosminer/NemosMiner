using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" # Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.19.1/cpuminer-opt-3.19.1-windows.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AvailableMiner_Devices = @($Devices | Where-Object Type -EQ "CPU")

If ($AvailableMiner_Devices.CpuFeatures -match "sha")        { $Path = ".\Bin\$($Name)\cpuminer-Avx512-sha.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx512") { $Path = ".\Bin\$($Name)\cpuminer-Avx512.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx2")   { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx")    { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "aes")    { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "sse2")   { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
Else { Return }

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Hmq1725";   MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo hmq1725" }
    [PSCustomObject]@{ Algorithm = "Lyra2z330"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo lyra2z330" }
    [PSCustomObject]@{ Algorithm = "m7m";       MinerSet = 2; WarmupTimes = @(0, 0);  Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "Sha3d";     MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo sha3d" }
    [PSCustomObject]@{ Algorithm = "ScryptN11"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo scrypt(N,1,1)" }
    [PSCustomObject]@{ Algorithm = "VertHash";  MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo verthash" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $AvailableMiner_Devices | Select-Object Model -Unique | ForEach-Object { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

        $AlgorithmDefinitions | ForEach-Object {

            # Get arguments for available miner devices
            # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $Devices.$DeviceEnumerator

            If ($_.Algorithm -eq "VertHash") { 
                If (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf) { 
                    $_.Arguments += " --data-file ..\..\Cache\VertHash.dat"
                }
                ElseIf (Test-Path -Path ".\VertHash.dat" -PathType Leaf) { 
                    New-Item -Path . -Name "Cache" -ItemType Directory -ErrorAction Ignore | Out-Null
                    Move-Item -Path ".\VertHash.dat" -Destination ".\Cache" -ErrorAction Ignore
                    $_.Arguments += " --data-file ..\..\Cache\VertHash.dat"
                }
                Else { 
                    $_.Arguments += " --verify"
                    $_.WarmupTimes[0] += 480; $_.WarmupTimes[1] += 480 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat}
                }
            }

            If ($Pools.($_.Algorithm).SSL) { $Protocol = "stratum+ssl" } Else { $Protocol = "stratum+tcp" }

            [PSCustomObject]@{ 
                Name        = $Miner_Name
                DeviceName  = $AvailableMiner_Devices.Name
                Type        = "CPU"
                Path        = $Path
                Arguments   = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --hash-meter --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                Algorithm   = $_.Algorithm
                API         = "Ccminer"
                Port        = $MinerAPIPort
                URI         = $Uri
                WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
            }
        }
    }
}
