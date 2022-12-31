If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/patrykwnosuch/cpuminer-nosuch/releases/download/3.8.8.1-nosuch-m4/cpu-nosuch-m4-win64.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer-aes-sse2.exe"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BinariumV1"; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo binarium-v1" }
    [PSCustomObject]@{ Algorithm = "m7m";        MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo m7m" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    If ($AvailableMiner_Devices.CpuFeatures -match "sha")      { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx2") { $Path = ".\Bin\$($Name)\cpuminer-avx2.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-aes-sse2.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-sse2.exe" }
    Else { Return }

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        $Arguments = $_.Arguments

        # Get arguments for available miner devices
        # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name        = $Miner_Name
            DeviceNames = $AvailableMiner_Devices.Name
            Type        = ($AvailableMiner_Devices.Type | Select-Object -unique)
            Path        = $Path
            Arguments   = ("$($Arguments) --url $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            Algorithms  = @($_.Algorithm)
            API         = "Ccminer"
            Port        = $MinerAPIPort
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
        }
    }
}
