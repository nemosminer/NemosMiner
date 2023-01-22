If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -eq "AMD")) { Return }

$Uri = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.9.4/sgminer-fancyIX-win64-0.9.4.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\sgminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "0x10";          MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 0); ExcludePool = @();             Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel chainox" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinMemGiB = 2; Minerset = 1; WarmupTimes = @(60, 0); ExcludePool = @();             Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 23 --kernel heavyhash" } # FPGA
    [PSCustomObject]@{ Algorithm = "Neoscrypt";     MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePool = @("ProHashing"); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt" } # FPGA
    [PSCustomObject]@{ Algorithm = "NeoscryptXaya"; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePool = @();             Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt-xaya" }
#   [PSCustomObject]@{ Algorithm = "YescryptR16";   MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePool = @();             Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 20 --pool-nfactor 100 --kernel yescryptr16" } # Invalid hash rate
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Xgminer"
                    Arguments   = ("$($Arguments) --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --api-listen --api-port $MinerAPIPort --gpu-platform $($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
