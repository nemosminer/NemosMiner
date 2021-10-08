using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong";    MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -algo EAGLESONG" }
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.7b may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 20); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.7b may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPoW";       MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 20); Arguments = " -algo KAWPOW" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";     MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -algo LYRA2V3" }
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -algo PROGPOW" } # Zano, Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " -algo UBQHASH -intensity 15" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                If ($Pools.($_.Algorithm).Epoch -gt 384) { Return }

                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { $MinMemGB = ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Coin = ""
                    If ($Pools.($_.Algorithm).Currency -in @("CKB", "CLO", "EPIC", "ERE", "ETC", "ETH", "ETP", "EXP", "HANA", "MUSIC", "PIRL", "SERO", "TCR", "UBQ", "VTC", "ZANO", "ZCOIN")) { 
                        $Coin = " -coin $($Pools.($_.Algorithm).Currency)"
                    }
                    ElseIf ($_.Algorithm -eq "ProgPoW") { # No coin
                        Return
                    }

                    $Pass = " -pass $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name -replace " "
                        DeviceName  = $Miner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User)$Pass -work-timeout 500000$Coin -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
