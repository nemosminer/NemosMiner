using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong"; MinMemGB = 2; Command = " -algo EAGLESONG" }
#   [PSCustomObject]@{ Algorithm = "Ethash";    MinMemGB = 4; Command = " -algo ETHASH" } #PhoenixMiner-v5.1c is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";    MinMemGB = 2; Command = " -algo KAWPOW" }
#   [PSCustomObject]@{ Algorithm = "MTP";       MinMemGB = 2; Command = " -algo MTP -i 21" } #CcminerMTP-v1.3.2 is faster
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                # If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -like "ZergPool*") { Return }
                # If ($_.Algorithm -eq "KawPoW" -and $Pools.($_.Algorithm).Name -like "MPH*") { Return }

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -work-timeout 500000 -user $($Pools.($_.Algorithm).User) -pass $($Pools.($_.Algorithm).Pass) --api-bind 127.0.0.1:$($MinerAPIPort) -device $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "EthMiner"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        WarmupTime = 90 #seconds
                    }
                }
            }
        }
    }
}
