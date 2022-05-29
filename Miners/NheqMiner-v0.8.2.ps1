using module ..\Includes\Include.psm1

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -eq "CPU")) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/0.8.2/nheqminer082.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nheqminer.exe"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VerusHash"; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " -v" } # CcminerVerusCpu-v3.7.0 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        # Get arguments for available miner devices
        # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name        = $Miner_Name
            DeviceNames= $AvailableMiner_Devices.Name
            Type        = $AvailableMiner_Devices.Type
            Path        = $Path
            Arguments   = ("$($_.Arguments) -l $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -u $($Pools.($_.Algorithm).User) -p $($Pools.($_.Algorithm).Pass) -t $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) -a $MinerAPIPort" -replace "\s+", " ").trim()
            Algorithm   = $_.Algorithm
            API         = "Nheq"
            Port        = $MinerAPIPort
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
        }
    }
}
