If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -lt "26.20.15011.10003" })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/ClaymoreNeoscrypt/claymore_neoscrypt_1.2.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\NeoScryptMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGiB = 2; ExcludeGPUArchitecture = @("RDNA1", "RDNA2", "RDNA3"); Minerset = 2; WarmupTimes = @(45, 0); Arguments = "" } # FPGA
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = $Devices | Where-Object Model -EQ $_.Model) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Algorithms | ForEach-Object { 

                If ($AvailableMiner_Devices = ($Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture)) { 

                    $Arguments = $_.Arguments
                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                    # Get arguments for available miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    $Fee = If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { @(2.5) } Else { @(2) }

                    # Disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $Arguments += " --nofee 1"
                        $Fee = @(0)
                    }

                    [PSCustomObject]@{ 
                        Algorithms  = @($_.Algorithm)
                        API         = "EthMiner"
                        Arguments   = ("$($Arguments) -pool $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) -wal $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).Pass) { " -psw $($MinerPools[0].($_.Algorithm).Pass)" }) -mport -$MinerAPIPort -di $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                        DeviceNames = $AvailableMiner_Devices.Name
                        Fee         = $Fee
                        MinerSet    = $_.MinerSet
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    }
                }
            }
        }
    }
}
