using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.23/gminer_2_23_windows64.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = @("Blake2s");             MinMemGB = 4.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo blake2s --cuda 0 --opencl 1" } #SRBMminerMulti-v0.5.1 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc");       MinMemGB = 6.0; Fee = @(0.03);    Type = "AMD";    Command = " --algo bfc --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29S");         MinMemGB = 4.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo cuckaroo29s --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("Eaglesong");           MinMemGB = 0.8; Fee = @(0.02);    Type = "AMD";    Command = " --algo eaglesong --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("Equihash1445");        MinMemGB = 1.8; Fee = @(0.02);    Type = "AMD";    Command = " --algo equihash144_5 --pers auto --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("Equihash1927");        MinMemGB = 2.8; Fee = @(0.02);    Type = "AMD";    Command = " --algo equihash192_7 --pers auto --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("EquihashBTG");         MinMemGB = 3.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo 144_5 --pers BgoldPoW --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithm = @("BeamV3");              MinMemGB = 3.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo beamhashIII --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Blake2s");             MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo blake2s --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CryptonightBBC");      MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cryptonightbbc --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc");       MinMemGB = 6.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo bfc --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29B");         MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckaroo29b --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29S");         MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckaroo29s --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29");         MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckarood29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29V");        MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckarood29v --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");         MinMemGB = 4.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo cuckaroom29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CuckarooZ29");         MinMemGB = 4.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo cuckarooz29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX");       MinMemGB = 8.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo C30CTX --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");          MinMemGB = 7.4; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckatoo31 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");          MinMemGB = 7.4; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckatoo32 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");            MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckoo29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Eaglesong");           MinMemGB = 0.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo eaglesong --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Equihash965");         MinMemGB = 0.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash96_5 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("Equihash1254");        MinMemGB = 1.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash125_4 --cuda 1 --opencl 0" } #MiniZ-v1.6v6 is fastest
#   [PSCustomObject]@{ Algorithm = @("Equihash1445");        MinMemGB = 1.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash144_5 --pers auto --cuda 1 --opencl 0" } #MiniZ-v1.6v6 is fastest
#   [PSCustomObject]@{ Algorithm = @("Equihash1927");        MinMemGB = 2.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash192_7 --pers auto --cuda 1 --opencl 0" } #MiniZ-v1.6v6 is fastest
    [PSCustomObject]@{ Algorithm = @("Equihash2109");        MinMemGB = 1.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash210_9 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("EquihashBTG");         MinMemGB = 3.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo 144_5 --pers BgoldPoW --cuda 1 --opencl 0" } #MiniZ-v1.6v6 is fastest
#   [PSCustomObject]@{ Algorithm = @("Ethash");              MinMemGB = 4.0; Fee = @(0.0065);  Type = "NVIDIA"; Command = " --algo ethash --cuda 1 --opencl 0" } #PhoenixMiner-v5.1c is fastest
#   [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");   MinMemGB = 4.0; Fee = @(0.03, 0); Type = "NVIDIA"; Command = " --algo ethash+blake2s --cuda 1 --opencl 0" } #PhoenixMiner-v5.1c is fastest
#   [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); MinMemGB = 4.0; Fee = @(0.03, 0); Type = "NVIDIA"; Command = " --algo ethash+eaglesong --cuda 1 --opencl 0" } #NBMiner-v31.1 is fastest
    [PSCustomObject]@{ Algorithm = @("Handshake");           MinMemGB = 0.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo handshake --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("KawPoW");              MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo kawpow --cuda 1 --opencl 0" } #Trex-v0.16.1 is fastest
    [PSCustomObject]@{ Algorithm = @("Qitmeer");             MinMemGB = 6.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo qitmeer --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("Sero");                MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo sero --cuda 1 --opencl 0" } #Sero != ProgPoW on ZergPool
    [PSCustomObject]@{ Algorithm = @("Vollar");              MinMemGB = 4.0; Fee = @(0.03, 0); Type = "NVIDIA"; Command = " --algo vollar --cuda 1 --opencl 0" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 

                If ($_.Algorithm[0] -match "^Equihash*|^Cuckaroo29bfc" -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } #Dual mining not supported on Navi

                $MinMemGB = $_.MinMemGB

                #Windows 10 requires more memory on some algos
                If ($_.Algorithm[0] -match "Cuckaroo*|Cuckoo*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB += 1 }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1] | Select-Object)) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "pers", "proto") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $_.Command += " --server $($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) --user $($Pools.($_.Algorithm[0]).User) --pass $($Pools.($_.Algorithm[0]).Pass)"

                    # If ($Pools.($_.Algorithm[0]).SSL) { $_.Command += " --ssl true --ssl_verification false" }
                    If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^NiceHash*|^MPH*") { $_.Command += " --proto stratum" }

                    If ($_.Algorithm[1]) { 
                        #If ($Pools.($_.Algorithm[1]).SSL) { $_.Command += " --dssl true --dssl_verification false" }
                        $_.Command += " --dserver $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) --duser $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User):$($PoolsSecondaryAlgorithm.Algo2.Pass)"
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = $_.Type
                        Path            = $Path
                        Arguments       = ("$($_.Command) --api $($MinerAPIPort) --watchdog 0 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm       = ($_.Algorithm) | Select-Object
                        API             = "Gminer"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee
                        WarmupTime      = 45 #seconds
                        MinerUri        = "http://localhost:$($MinerAPIPort)"
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
