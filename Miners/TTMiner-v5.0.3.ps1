using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -lt 8.6 <# No response in API with RTX cards #>})) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong";    MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo EAGLESONG" }
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPoW";       MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(40, 30); Arguments = " -algo KAWPOW" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";     MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo LYRA2V3" }
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";      MinMemGB = $Pools."ProgPoW".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " -algo PROGPOW" } # Zano, Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";      MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " -algo UBQHASH -intensity 15" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($Pools.($_.Algorithm).Epoch -gt 384) { Return }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $_.Arguments = $_.Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).Currency -in @("CLO", "ETC", "ETH", "EPIC", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "SERO", "TCR", "UBQ", "VBK", "VEIL", "ZANO", "ZCOIN", "ZELS")) { 
                    $_.Arguments += " -coin $($Pools.($_.Algorithm).Currency)"
                }
                ElseIf ($_.Algorithm -eq "ProgPoW") { # No coin
                    Return
                }

                $_.Arguments += " -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User)"
                $_.Arguments += " -pass $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$(((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB) * 1GB / 1000000000)" })"

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
