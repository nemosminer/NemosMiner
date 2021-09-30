using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/TT-Miner/TT-Miner-v6.2.0.7z"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

If ($Config.MinerInstancePerDeviceModel) { Return } # Error 'No cuda shared libraries found' if more than one active instance

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.01; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo ETHASH -coin ETC -intensity 15" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.01; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo KAWPOW" } # Trex-v0.23.2 is fastest
    [PSCustomObject]@{ Algorithm = "MTP";          Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";      Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo PROGPOW" } # Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";      Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " -algo UBQHASH -intensity 15" }
    [PSCustomObject]@{ Algorithm = "Zano";         Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " -algo PROGPOWZ" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { $MinMemGB = ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    If ($Miner_Devices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -le 2 }) { $_.Arguments = $_.Arguments -replace " -intensity [0-9\.]+" }

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Coin = ""
                    If ($Pools.($_.Algorithm).Currency -in @("CLO", "ETC", "ETH", "EPIC", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "SERO", "TCR", "UBQ", "VBK", "VEIL", "ZANO", "ZCOIN", "ZELS")) { 
                        $Coin = " -coin $($Pools.($_.Algorithm).Currency)"
                    }
                    ElseIf ($_.Algorithm -eq "ProgPoW") { # No coin
                        Return
                    }

                    $Pass = " -pass $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
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
