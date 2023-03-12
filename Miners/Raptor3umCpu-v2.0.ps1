If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/Raptor3um/cpuminer-opt/releases/download/v2.0/cpuminer-take2-windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" # Intel

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Ghostrider"; Minerset = 1; WarmupTimes = @(45, 30); Arguments = " --algo gr" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    If ($AvailableMiner_Devices.CpuFeatures -match "avx2")     { $Path = ".\Bin\$($Name)\cpuminer-avx2.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx")  { $Path = ".\Bin\$($Name)\cpuminer-avx.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-sse2.exe" }
    Else { Return }

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        $Arguments = $_.Arguments

        # Get arguments for available miner devices
        # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Algorithms  = @($_.Algorithm)
            API         = "Ccminer"
            Arguments   = ("$($Arguments) --url $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --hash-meter --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            DeviceNames = $AvailableMiner_Devices.Name
            MinerSet    = $_.MinerSet
            Name        = $Miner_Name
            Path        = $Path
            Port        = $MinerAPIPort
            Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
        }
    }
}

$Error.Clear()