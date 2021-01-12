using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v0.2.0/xmrig-upx-v0.2.0-win64.zip"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "CryptonightUpx"; MinerSet = 0; Arguments = "-a cryptonight-upx/2" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        If ($Pools.($_.Algorithm).Name -eq "NiceHash") { $_.MinerSet = 2; Arguments = "$($_.Arguments) --nicehash" }

        $AlgorithmDefinitions | ForEach-Object { 

            # Get commands for active miner devices
            # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "CPU"
                Path       = $Path
                Arguments  = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --keepalive --api-port=$($MinerAPIPort) --donate-level 0").trim()
                Algorithm  = $_.Algorithm
                API        = "XmRig"
                Port       = $MinerAPIPort
                URI        = $Uri
            }
        }
    }
}
