using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/ccminer/releases/download/8.21-r18-v5/ccmineryescryptrV5.zip"
$Path = ".\Bin\NVIDIA-CcmineryescryptrV5\ccminer.exe"
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";    MinMemGB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePool = @("MiningPoolHub"); Arguments = " --algo lyra2v3 --intensity 24" }
    # [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePool = @();                Arguments = " --algo lyra2z330 --intensity 13.2" } #only runs on single gpu's
    # [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGB = 2; MinerSet = 1; WarmupTimes = @(30, 0); ExcludePool = @();                Arguments = " --algo yescrypt" } # bad shares, CcminerLyra2z330-v8.21r9 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePool = @();                Arguments = " --algo yescryptr16 --intensity 13.2" }
    # [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePool = @();                Arguments = " --algo yescryptr32 --intensity 12.23" } # Out of memory even with 6GB
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePool = @();                Arguments = " --algo yescryptr8 --intensity 13.2" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $Pools.($_.Algorithm).BaseName -notin $_.ExcludePool } | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($_.Algorithm -eq "Yescrypt" -and $Pools.($_.Algorithm).Currency -ne "BSTY") { Return } # Temp fix

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "timeout") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --statsavg 5 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = $_.Algorithm
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
