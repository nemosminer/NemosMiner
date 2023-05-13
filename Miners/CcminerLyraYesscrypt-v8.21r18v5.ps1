If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/ccminer/releases/download/8.21-r18-v5/ccmineryescryptrV5.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";    MinMemGiB = 3; Minerset = 2; WarmupTimes = @(30, 0); ExcludePool = @();        Arguments = " --algo lyra2v3 --intensity 24" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGiB = 3; Minerset = 2; WarmupTimes = @(30, 0); ExcludePool = @();        Arguments = " --algo lyra2z330 --intensity 13.2" } # Algorithm is dead
#   [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludePool = @();        Arguments = " --algo yescrypt" } # bad shares, CcminerLyra2z330-v8.21r9 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePool = @("Zpool"); Arguments = " --algo yescryptr16 --intensity 13.2" } # ZPool: Too many stale shares
#   [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludePool = @();        Arguments = " --algo yescryptr32" } # Cuda error in func 'yescrypt_setTarget' at line 1296 : invalid device symbol.
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludePool = @();        Arguments = " --algo yescryptr8 --intensity 13.2" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($_.Algorithm -eq "Yescrypt" -and $MinerPools[0].($_.Algorithm).Currency -ne "BSTY") { Return } # Temp fix

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