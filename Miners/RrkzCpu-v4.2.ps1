If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/RickillerZ/cpuminer-RKZ/releases/download/V4.2b/cpuminer-RKZ.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$()$Name)\cpuminer.exe"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "CpuPower"; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo cpupower" } # ASIC SRBMinerMulti-v2.2.7 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Power2b";  Minerset = 2; WarmupTimes = @(30, 0);  Arguments = " --algo power2b" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

    $Algorithms | ForEach-Object { 

        $Arguments = $_Arguments

        # Get arguments for available miner devices
        # $Arguments = Get-ArgumentsPerDevice -Arguments $_ .Command -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Algorithms  = @($_.Algorithm)
            API         = "Ccminer"
            Arguments   = ("$($Arguments) --url $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            DeviceNames = $AvailableMiner_Devices.Name
            MinerSet    = $_.MinerSet
            Name        = $Miner_Name
            Path        = $Path
            Port        = $MinerAPIPort
            Type        = "CPU"
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
        }
    }
}