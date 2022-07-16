using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.1" } { "https://github.com/Minerx117/miners/releases/download/Z-Enemy/z-enemy-2.6.3-win-cuda11.1.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\z-enemy.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Aergo";      MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo aergo --intensity 23 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "BCD";        MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo bcd --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Bitcore";    MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo bitcore --intensity 22 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "C11";        MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algo c11 --intensity 24 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Hex";        MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo hex --intensity 24 --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "KawPoW";     MinMemGB = $Pools."KawPoW".DAGSizeGB; MemReserveGB = 0.41; MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algo kawpow --statsavg 1 --diff-factor 5" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Phi";        MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo phi --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Phi2";       MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo phi2 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo poly --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "SkunkHash";  MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo skunk --statsavg 1" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Sonoa";      MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo sonoa --statsavg 1" }
    [PSCustomObject]@{ Algorithm = "Timetravel"; MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo timetravel --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Tribus";     MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo tribus --statsavg 1" }
    [PSCustomObject]@{ Algorithm = "X16r";       MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x16r --statsavg 1" }
    [PSCustomObject]@{ Algorithm = "X16rv2";     MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo x16rv2 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "X16s";       MinMemGB = 3;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo x16s --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "X17";        MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algo x17 --statsavg 1" }
    [PSCustomObject]@{ Algorithm = "Xevan";      MinMemGB = 2;                         MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algo xevan --intensity 26 --diff-factor 1 --statsavg 1" }
    )

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User)$(If ($Pools.($_.Algorithm).WorkerName) { ".$($Pools.($_.Algorithm).WorkerName)" }) --pass $($Pools.($_.Algorithm).Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "Trex"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = 0.01 # dev fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = @($_.WarmupTimes) # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
