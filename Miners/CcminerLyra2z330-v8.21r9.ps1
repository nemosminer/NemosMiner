If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/ccminer8.21r9-lyra2z330/releases/download/v3/ccminerlyra2z330v3.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo lyra2z330  --intensity 12.5" } # Algorithtm is dead
#   [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(75, 5); Arguments = " --algo yescrypt" } # Too many bad shares
    [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGiB = 3; Minerset = 1; WarmupTimes = @(30, 0); Arguments = " --algo yescryptr16 --intensity 13.3" } # CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(60, 0); Arguments = " --algo yescryptr32 --intensity 12.3" } # CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); Arguments = " --algo yescryptr8" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $Arguments = $Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "timeout") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Ccminer"
                    Arguments   = ("$($Arguments) --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --statsavg 5 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "NVIDIA"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}