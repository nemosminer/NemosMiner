using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -eq "AMD")) { Return }
If ($Devices.Model -match "^Radeon RX [56]\d\d\d" -and $Devices.Model -notmatch "^Radeon RX [56]\d\d\d") { Return } # Current code cannot auto handle both navi and pre-navi cards (https://github.com/fancyIX/sgminer-phi2-branch/issues/251)

$Uri = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.9.2-0/sgminer-fancyIX-win64-0.9.2.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\sgminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "0x10";          MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 0); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel chainox" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 0); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 23 --kernel heavyhash" }
    [PSCustomObject]@{ Algorithm = "NeoscryptXaya"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 0); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt-xaya" }
    # [PSCustomObject]@{ Algorithm = "YescryptR16";   MinMemGB = 2; MinerSet = 0; WarmupTimes = @(60, 0); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 20 --pool-nfactor 100 --kernel yescryptr16" } # High number of bad shares
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices.Model -match "^Radeon RX [56]\d\d\d") { $_.Arguments += "_navi" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url $(If ($Pools.($_.Algorithm).SSL) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --api-listen --api-port $MinerAPIPort --gpu-platform $($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Xgminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
