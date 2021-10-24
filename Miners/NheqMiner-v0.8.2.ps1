using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nheqminer.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/0.8.2/nheqminer082.7z"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VerusHash"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " -v" } # CcminerVerusCpu-v3.7.0 is fastest
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) {

    If ($AvailableMiner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-'

        $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object {

            # Get arguments for available miner devices
            # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name        = $Miner_Name -replace " "
                DeviceName  = $AvailableMiner_Devices.Name
                Type        = "CPU"
                Path        = $Path
                Arguments   = ("$($_.Arguments) -l $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -u $($Pools.($_.Algorithm).User) -p $($Pools.($_.Algorithm).Pass) -t $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) -a $MinerAPIPort" -replace "\s+", " ").trim()
                Algorithm   = $_.Algorithm
                API         = "Nheq"
                Port        = $MinerAPIPort
                URI         = $Uri
                WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
            }
        }
    }
}
