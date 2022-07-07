using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -lt "26.20.15011.10003" })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/ClaymoreNeoscrypt/claymore_neoscrypt_1.2.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\NeoScryptMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGB = 2; ExcludeGPUArchitecture = @("RDNA"); MinerSet = 0; WarmupTimes = @(45, 0); Arguments = "" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = $Devices | Where-Object Model -EQ $_.Model) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

                $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    $Fee = If ($Pools.$_.Algorithm.SSL) { @(2.5) } Else { @(2) }

                    # Disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $_.Arguments += " --nofee 1"
                        $Fee = @(0)
                    }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceNames = $AvailableMiner_Devices.Name
                        Type        = $AvailableMiner_Devices.Type
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) -pool $(If ($Pools.($_.Algorithm).SSL) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -wal $($Pools.($_.Algorithm).User)$(If ($Pools.($_.Algorithm).Pass) { " --pass $($Pools.($_.Algorithm).Pass)" }) -mport -$MinerAPIPort -di $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                        Algorithms  = @($_.Algorithm)
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $Fee
                        WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    }
                }
            }
        }
    }
}
