using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/TT-Miner/TT-Miner-v6.1.0.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong"; Fee = 0.01; MinMemGB = 2; Command = " -algo EAGLESONG" }
#   [PSCustomObject]@{ Algorithm = "EtcHash";   Fee = 0.01; MinMemGB = 4; Command = " -algo ETHASH -coin ETC -intensity 15" } #PhoenixMiner-v5.3b is fastest
#   [PSCustomObject]@{ Algorithm = "Ethash";    Fee = 0.01; MinMemGB = 4; Command = " -algo ETHASH -intensity 15" } #PhoenixMiner-v5.3b is fastest
    [PSCustomObject]@{ Algorithm = "KawPow";    Fee = 0.01; MinMemGB = 2; Command = " -algo KAWPOW" }
#   [PSCustomObject]@{ Algorithm = "MTP";       Fee = 0.01; MinMemGB = 2; Command = " -algo MTP -intensity 21" } #CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";   Fee = 0.01; MinMemGB = 2; Command = " -algo PROGPOW" } #Zano, Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";   Fee = 0.01; MinMemGB = 2; Command = " -algo UBQHASH -intensity 15" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -eq "ProgPoW") { 
                        If ($Pools.($_.Algorithm).Currency -in @("EPIC", "ETHERCORE", "SERO", "RAVEN", "ZANO")) { 
                            $Coin = " -coin $($Pools.($_.Algorithm).Currency)"
                        }
                        Else { 
                            $Coin = ""
                            Return
                        }
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Command) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -work-timeout 500000 -user $($Pools.($_.Algorithm).User) -pass $($Pools.($_.Algorithm).Pass)$Coin -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "EthMiner"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        WarmupTime      = 90 #seconds
                        Fee             = $_.Fee
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
