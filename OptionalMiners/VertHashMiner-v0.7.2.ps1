using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\verthashminer.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/VertHashMiner/VertHashMiner_0.7.2.zip"

$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VertHash"; MinMemGB = 2; Type = "AMD";    MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --cl-devices" }
    [PSCustomObject]@{ Algorithm = "VertHash"; MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --cu-devices" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model | Where-Object { $_.Type -ne "AMD" -or $_.OpenCL.ClVersion -ge "OpenCL C 1.2" })) { 

            $MinerAPIPort = 0 # Mienr has no API Port

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 
                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                $WarmupTimes = $_.WarmupTimes.PsObject.Copy()

                If ($_.Algorithm -eq "VertHash") { 
                    If (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf) { 
                        $Arguments = "--verthash-data ..\..\Cache\VertHash.dat $Arguments"
                    }
                    Else { 
                        If (-not (Test-Path -Path "..\..\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory -ErrorAction Ignore | Out-Null }
                        $Arguments = "--gen-verthash-data ..\..\Cache\VertHash.dat $Arguments"
                        $WarmupTimes[0] += 600; $WarmupTimes[1] += 600 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                    }
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } )) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',') --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "NoAPI"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = 0.01
                        WarmupTimes = $WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates, second value: extra time (in seconds) until miner must send first valid sample
                    }
                }
            }
        }
    }
}
