using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miniZ.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v1.6x_win-x64.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BeamV3";       MinMemGB = 4.0; MinerSet = 1; Arguments = " --par=beam3 --pers=Beam-PoW --ocX" } # NBMiner-v36.1 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1254"; MinMemGB = 3.0; MinerSet = 0; Arguments = " --par=125,4 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1445"; MinMemGB = 2.0; MinerSet = 0; Arguments = " --par=144,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1505"; MinMemGB = 2.0; MinerSet = 0; Arguments = " --par=150,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1927"; MinMemGB = 2.3; MinerSet = 0; Arguments = " --par=192,7 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash2109"; MinMemGB = 2.0; MinerSet = 0; Arguments = " --par=210,9 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash965";  MinMemGB = 2.0; MinerSet = 1; Arguments = " --par=96,5 --smart-pers --ocX" } # Insane high benchmark data (https://bitcointalk.org/index.php?topic=4767892.msg55832323)
    [PSCustomObject]@{ Algorithm = "EquihashBTG";  MinMemGB = 3.0; MinerSet = 0; Arguments = " --par=144,5 --pers BgoldPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";  MinMemGB = 2.0; MinerSet = 0; Arguments = " --par=192,7 --pers ZcashPoW --ocX" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("par", "pers", "ocX") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Arguments) --url $(If ($Pools.($_.Algorithm).SSL) { "ssl://" })$($Pools.($_.Algorithm).User)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --pass $($Pools.($_.Algorithm).Pass) --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 10 --latency --extra --tempunits C --show-pers --fee-time=60 --telemetry $($MinerAPIPort) --cuda-devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "MiniZ"
                        Port            = $MinerAPIPort
                        Wrap            = $false
                        URI             = $Uri
                        Fee             = 0.02 # Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)"
                        PowerUsageInAPI = $true
                        WarmupTime      = 30
                    }
                }
            }
        }
    }
}
