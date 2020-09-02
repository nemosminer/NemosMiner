using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nheqminer.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/0.8.2/nheqminer082.7z"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VerusHash"; Command = " -v" } #Does not work
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) {

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | ForEach-Object {

            #Get commands for active miner devices
            #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "CPU"
                Path       = $Path
                Arguments  = ("$($_.Command) -l $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -u $($Pools.($_.Algorithm).User) -p $($Pools.($_.Algorithm).Pass) -t $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) -a $MinerAPIPort" -replace "\s+", " ").trim()
                Algorithm  = $_.Algorithm
                API        = "Nheq"
                Port       = $MinerAPIPort
                URI        = $Uri
                WarmupTime = 120
            }
        }
    }
}
