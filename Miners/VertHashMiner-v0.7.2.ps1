using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or ($_.Type -eq "NVIDIA" -and $_.OpenCl.ComputeCapability -ge "3.0") })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/VertHashMiner/VertHashMiner_0.7.2.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\verthashminer.exe"

$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VertHash"; MinMemGB = 2; Type = "AMD";    MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --cl-devices" }
    [PSCustomObject]@{ Algorithm = "VertHash"; MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --cu-devices" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($Algorithms.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = 0 # Miner has no API

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                $_.Arguments += " $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm -eq "VertHash") { 
                    If (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf) { 
                        $_.Arguments += " --verthash-data ..\..\Cache\VertHash.dat"
                    }
                    Else { 
                        $_.Arguments += " --gen-verthash-data ..\..\Cache\VertHash.dat"
                        $_.WarmupTimes[0] += 600; $_.WarmupTimes[0] += 600 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                    }
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "NoAPI"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = 0.01
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
