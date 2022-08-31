using module ..\Includes\Include.psm1

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/RickillerZ/cpuminer-RKZ/releases/download/V4.2b/cpuminer-RKZ.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$()$Name)\cpuminer.exe"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "CpuPower"; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo cpupower" } # SRBMinerMulti-v1.0.2 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Power2b";  MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo power2b" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        # Get arguments for available miner devices
        # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_ .Command -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name        = $Miner_Name
            DeviceNames = $AvailableMiner_Devices.Name
            Type        = $AvailableMiner_Devices.Type
            Path        = $Path
            Arguments   = ("$($_.Arguments) --url $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            Algorithms  = @($_.Algorithm)
            API         = "Ccminer"
            Port        = $MinerAPIPort
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
        }
    }
}
