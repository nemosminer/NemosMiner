using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\NVIDIA-miniZ160v5\miniZ.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/1.6v5/miniZ_v1.6v5_cuda10_win-x64.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
#    [PSCustomObject]@{ Algorithm = "Beam";        MinMemGB = 2.0; Command = " --par=-par=150,5 --pers auto --ocX" }
#    [PSCustomObject]@{ Algorithm = "BeamV2";       MinMemGB = 4.0; Command = " --par=beam --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "BeamV3";       MinMemGB = 4.0; Command = " --par=beam3 --pers=Beam-PoW --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash965";  MinMemGB = 2.0; Command = " --par=96,5 --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1254"; MinMemGB = 3.0; Command = " --par=125,4 --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1445"; MinMemGB = 2.0; Command = " --par=144,5 --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1505"; MinMemGB = 2.0; Command = " --par=150,5 --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1927"; MinMemGB = 3.0; Command = " --par=192,7 --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash2109"; MinMemGB = 1.0; Command = " --par=210,9 --pers auto --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";  MinMemGB = 3.0; Command = " --par=144,5 --pers BgoldPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";  MinMemGB = 1.0; Command = " --par=192,7 --pers ZcashPoW --ocX" }
)

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object {
            $MinMemGB = $_.MinMemGB
            If ($Miner_Devices = @($SelectedDevices | Where-Object { ([math]::Round((10 * $_.OpenCL.GlobalMemSize / 1GB), 0) / 10) -ge $MinMemGB })) { 
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("par", "pers", "ocX") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Path       = $Path
                    Arguments  = ("$($_.Command) --url $($Pools.($_.Algorithm).User)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --pass $($Pools.($_.Algorithm).Pass) --cleanjobs --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 10 --latency --extra --tempunits C --show-pers --fee-time=60 --telemetry $($MinerAPIPort) --cuda-devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')").trim() #--oc1 --oc2 --f11=0
                    Algorithm  = $_.Algorithm
                    API        = "MiniZ"
                    Port       = $MinerAPIPort
                    Wrap       = $false
                    URI        = $Uri
                    Fee        = 0.02 #Dev fee
                    MinerUri   = "http://localhost:$($MinerAPIPort)"
                }
            }
        }
    }
}
