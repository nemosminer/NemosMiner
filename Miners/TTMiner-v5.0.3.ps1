using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Eaglesong"; MinMemGB = 2; MinerSet = 0; Arguments = " -algo EAGLESONG" }
    [PSCustomObject]@{ Algorithm = "Ethash";    MinMemGB = 4; MinerSet = 0; Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v5.5c is fastest but has 0.65% fee
    [PSCustomObject]@{ Algorithm = "KawPoW";    MinMemGB = 3; MinerSet = 0; Arguments = " -algo KAWPOW" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";  MinMemGB = 2; MinerSet = 0; Arguments = " -algo LYRA2V3" }
    [PSCustomObject]@{ Algorithm = "MTP";       MinMemGB = 3; MinerSet = 0; Arguments = " -algo MTP -intensity 21" } # CcminerMTP-v1.3.2 is faster
    [PSCustomObject]@{ Algorithm = "ProgPoW";   MinMemGB = 2; MinerSet = 0; Arguments = " -algo PROGPOW" } # Zano, Sero
    [PSCustomObject]@{ Algorithm = "UbqHash";   MinMemGB = 2; MinerSet = 0; Arguments = " -algo UBQHASH -intensity 15" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                If ($Pools.($_.Algorithm).Epoch -gt 384) { Return }

                $MinMemGB = $_.MinMemGB

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

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Arguments) -pool stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -user $($Pools.($_.Algorithm).User) -work-timeout 500000$User -pass $($Pools.($_.Algorithm).Pass)$Coin -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
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
