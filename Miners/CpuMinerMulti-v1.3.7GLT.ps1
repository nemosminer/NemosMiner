using module ..\Includes\Include.psm1

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.3.7.1-GLT/CPUMiner-Multi.1.3.7.1-GLT.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer.exe" 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "ArcticHash"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo arctichash" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        # Get arguments for available miner devices
        # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name        = $Miner_Name
            DeviceName  = $AvailableMiner_Devices.Name
            Type        = $AvailableMiner_Devices.Type
            Path        = $Path
            Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --retry-pause 1 --api-bind $MinerAPIPort" -replace "\s+", " ").trim()
            Algorithm   = $_.Algorithm
            API         = "Ccminer"
            Port        = $MinerAPIPort
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
        }
    }
}
