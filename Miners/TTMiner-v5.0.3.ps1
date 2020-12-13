using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong"; MinMemGB = 2; Command = " -algo EAGLESONG" }
    [PSCustomObject]@{ Algorithm = "Ethash";    MinMemGB = 4; Command = " -algo ETHASH -intensity 15" } #PhoenixMiner-v5.3b is fastest but has 0.65% fee
#   [PSCustomObject]@{ Algorithm = "KawPow";    MinMemGB = 2; Command = " -algo KAWPOW" } #Create new DAG for epoch -1 error
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";  MinMemGB = 2; Command = " -algo LYRA2V3" }
#   [PSCustomObject]@{ Algorithm = "MTP";       MinMemGB = 2; Command = " -algo MTP -intensity 21" } #CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";   MinMemGB = 2; Command = " -algo PROGPOW" } #Zano, Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";   MinMemGB = 2; Command = " -algo UBQHASH -intensity 15" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                If ($Pools.($_.Algorithm).EthashEpoch -gt 384) { Return }

                $MinMemGB = $_.MinMemGB

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
                        Arguments       = ("$($_.Command) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User) -work-timeout 500000$User -pass $($Pools.($_.Algorithm).Pass)$Coin -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "EthMiner"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
