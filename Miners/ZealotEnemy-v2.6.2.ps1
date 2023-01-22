If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.1" } { Return } # Use 2.6.3
    { $_ -ge "10.1" } { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.1.zip"; Break }
    { $_ -ge "10.0" } { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.0.zip"; Break }
    { $_ -ge "9.2" }  { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda9.2.zip"; Break }
    { $_ -ge "9.1" }  { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda9.1.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\z-enemy.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Aergo";      MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo aergo --intensity 23 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "BCD";        MinMemGiB = 3;                                       Minerset = 3; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo bcd --statsavg 5" } # ASIC
    [PSCustomObject]@{ Algorithm = "Bitcore";    MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(90, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo bitcore --intensity 22 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "C11";        MinMemGiB = 3;                                       Minerset = 2; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo c11 --intensity 24 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Hex";        MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo hex --intensity 24 --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "KawPow";     MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.41; Minerset = 2; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo kawpow --statsavg 1 --diff-factor 5" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Phi";        MinMemGiB = 3;                                       Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo phi --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Phi2";       MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo phi2 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo poly --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";  MinMemGiB = 3;                                       Minerset = 3; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo skunk --statsavg 1" } # No hashrate in time for old cards
#   [PSCustomObject]@{ Algorithm = "Sonoa";      MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @(); Arguments = " --algo sonoa --statsavg 1" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Timetravel"; MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo timetravel --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Tribus";     MinMemGiB = 3;                                       MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @(); Arguments = " --algo tribus --statsavg 1" } # FPGA
    [PSCustomObject]@{ Algorithm = "X16r";       MinMemGiB = 3;                                       Minerset = 3; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @(); Arguments = " --algo x16r --statsavg 1" } # ASIC
    [PSCustomObject]@{ Algorithm = "X16rv2";     MinMemGiB = 3;                                       MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo x16rv2 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "X16s";       MinMemGiB = 3;                                       Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo x16s --statsavg 5" } # FPGA
    [PSCustomObject]@{ Algorithm = "X17";        MinMemGiB = 2;                                       MinerSet = 0; WarmupTimes = @(90, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo x17 --statsavg 1" }
#   [PSCustomObject]@{ Algorithm = "Xevan";      MinMemGiB = 2;                                       Minerset = 2; WarmupTimes = @(90, 0);  ExcludeGPUArchitecture = @(); Arguments = " --algo xevan --intensity 26 --diff-factor 1 --statsavg 1" } # No hashrate in time
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = ($Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture)) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Trex"
                    Arguments   = ("$($_.Arguments) $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "--no-cert-verify --url stratum+ssl" } Else { "--url stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = 0.01 # dev fee
                    Path        = $Path
                    Port        = $MinerAPIPort
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)" # Always offline
                    Name        = $Miner_Name
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI         = $Uri
                    WarmupTimes = @($_.WarmupTimes) # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
