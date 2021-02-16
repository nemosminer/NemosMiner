using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/TT-Miner/TT-Miner-v6.1.0.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";   Fee = 0.01; MinMemGB = 4; MinerSet = 1; Arguments = " -algo ETHASH -coin ETC -intensity 15" } # PhoenixMiner-v5.5c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";    Fee = 0.01; MinMemGB = 4; MinerSet = 1; Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.5c is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";    Fee = 0.01; MinMemGB = 2; MinerSet = 1; Arguments = " -algo KAWPOW" } # Trex-v0.19.11 is fastest
    [PSCustomObject]@{ Algorithm = "MTP";       Fee = 0.01; MinMemGB = 3; MinerSet = 1; Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";   Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " -algo PROGPOW" } # Sero
    [PSCustomObject]@{ Algorithm = "Zano";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " -algo PROGPOWZ" }
    [PSCustomObject]@{ Algorithm = "UbqHash";   Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " -algo UBQHASH -intensity 15" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Coin = ""
                    If ($_.Algorithm -eq "ProgPoW") { 
                        If ($Pools.($_.Algorithm).Currency -in @("EPIC", "ETHERCORE", "SERO", "RAVEN", "ZANO")) { 
                            $Coin = " -coin $($Pools.($_.Algorithm).Currency)"
                        }
                        Else { 
                            Return
                        }
                    }

                    If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                        $WaitForData = 45 # Seconds, max. wait time until first data sample
                        $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                    }
                    Else { 
                        $WaitForData = 15 # Seconds, max. wait time until first data sample
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Arguments) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User) -pass $($Pools.($_.Algorithm).Pass)$Coin -api-bind 127.0.0.1:$($MinerAPIPort) -poolinfo -work-timeout 500000 -device $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "EthMiner"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee
                        PowerUsageInAPI = $true
                        WaitForData     = $WaitForData
                    }
                }
            }
        }
    }
}
