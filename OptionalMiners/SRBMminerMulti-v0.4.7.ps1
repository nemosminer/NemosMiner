using module ..\Includes\Include.psm1

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.4.7/SRBMiner-Multi-0-4-7-win64.zip"
$SelectedDevices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"

#Algorithm names are case sensitive!
$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Blake2b";      MinMemGb = 1; Fee = 0;      Type = @("AMD"); Command = " --algorithm blake2b" } #Bad shares
#   [PSCustomObject]@{ Algorithm = "Blake2s";      MinMemGb = 1; Fee = 0;      Type = @("AMD"); Command = " --algorithm blake2s" } #Profit very small
    [PSCustomObject]@{ Algorithm = "Kangaroo12";   MinMemGb = 1; Fee = 0.0085; Type = @("AMD"); Command = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Keccak";       MinMemGb = 1; Fee = 0;      Type = @("AMD"); Command = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGb = 1; Fee = 0;      Type = @("AMD"); Command = " --algorithm mtp" }
#   [PSCustomObject]@{ Algorithm = "Rainforestv2"; MinMemGb = 1; Fee = 0.0085; Type = @("AMD"); Command = " --algorithm rainforestv2" } #No pool
    [PSCustomObject]@{ Algorithm = "Yescrypt";     MinMemGb = 1; Fee = 0.0085; Type = @("AMD"); Command = " --algorithm yescrypt" }

#   [PSCustomObject]@{ Algorithm = "Blake2b";       Fee = 0;      Type = @("CPU"); Command = " --algorithm blake2b" } #Bad shares
#   [PSCustomObject]@{ Algorithm = "Blake2s";       Fee = 0;      Type = @("CPU"); Command = " --algorithm blake2s" } #Profit very small
    [PSCustomObject]@{ Algorithm = "CpuPower";      Fee = 0.0085; Type = @("CPU"); Command = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";     Fee = 0.0085; Type = @("CPU"); Command = " --algorithm eaglesong" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";    Fee = 0.0085; Type = @("CPU"); Command = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Keccak";        Fee = 0;      Type = @("CPU"); Command = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "MTP";           Fee = 0;      Type = @("CPU"); Command = " --algorithm mtp" }
#   [PSCustomObject]@{ Algorithm = "Rainforestv2";  Fee = 0.0085; Type = @("CPU"); Command = " --algorithm rainforestv2" } #No pool
#   [PSCustomObject]@{ Algorithm = "Randomx";       Fee = 0.0085; Type = @("CPU"); Command = " --algorithm randomx --randomx-use-1gb-pages" } #XmRigCpu-v6.3.1 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxArq";    Fee = 0.0085; Type = @("CPU"); Command = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";    Fee = 0.0085; Type = @("CPU"); Command = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";    Fee = 0.0085; Type = @("CPU"); Command = " --algorithm randomwow" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";      Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";    Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";   Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";   Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = "Yespower";      Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yespower" }
#   [PSCustomObject]@{ Algorithm = "Yespower2b";    Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yespower2b" } #No pool
#   [PSCustomObject]@{ Algorithm = "YespowerItc";   Fee = 0     ; Type = @("CPU"); Command = " --algorithm yespoweritc" } #No pool
#   [PSCustomObject]@{ Algorithm = "Yespowerlitb";  Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yespowerlitb" } #No pool
#   [PSCustomObject]@{ Algorithm = "Yespowerltncg"; Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yespowerltncg" } #No pool
    [PSCustomObject]@{ Algorithm = "YespowerR16";   Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yespowerr16" }
#   [PSCustomObject]@{ Algorithm = "YespowerSugar"; Fee = 0.0085; Type = @("CPU"); Command = " --algorithm yespowersugar" } #No pool
#   [PSCustomObject]@{ Algorithm = "YespowerUrx";   Fee = 0;      Type = @("CPU"); Command = " --algorithm yespowerurx" } #No pool
)

$Devices | Where-Object Type -in @("AMD", "CPU") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object {

            If ($_.Algorithm -eq "Blake2b" -and $Pools.($_.Algorithm).Name -like "AHashPool*") { Return } 

            $MinMemGB = $_.MinMemGB
            If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ([math]::Round((10 * $_.Memory / 1GB), 0) / 10) -ge $MinMemGB })) {
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algorithm") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                If (($Miner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                    $DeviceCommand = " --cpu-priority 2 --cpu-threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                }
                Else { 
                    $DeviceCommand = " --gpu-id $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',') --disable-cpu"
                }

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = $_.Type
                    Path       = $Path
                    Arguments  = ("$($_.Command) --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User) --password $($Pools.($_.Algorithm).Pass) --worker $($Config.Workername) --api-enable --api-port $($MinerAPIPort)$(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash true" })$(If ($Pools.($_.Algorithm).SSL) { " --ssl true" })$DeviceCommand" -replace "\s+", " ").trim()
                    Algorithm  = $_.Algorithm
                    API        = "SRBMiner"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                    Fee        = $_.Fee #Dev fee
                    MinerUri   = "http://localhost:$($MinerAPIPort)/stats"
                }
            }
        }
    }
}
