using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.20/gminer_2_20_windows64.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Beam", $null);           MinMemGB = 0.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo beam --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("BFC", $null);            MinMemGB = 1.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo bfc --cuda 0 --opencl 1" }
#   [PSCustomObject]@{ Algorithm = @("Blake2s", $null);        MinMemGB = 4.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo blake2s --cuda 0 --opencl 1" } #Profit very small
#   [PSCustomObject]@{ Algorithm = @("Eaglesong", $null);      MinMemGB = 0.8; Fee = @(0.02);    Type = "AMD";    Command = " --algo eaglesong --cuda 0 --opencl 1" } #Profit very small
    [PSCustomObject]@{ Algorithm = @("Equihash1445", $null);   MinMemGB = 1.8; Fee = @(0.02);    Type = "AMD";    Command = " --algo equihash144_5 --pers auto --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("Equihash1927", $null);   MinMemGB = 2.8; Fee = @(0.02);    Type = "AMD";    Command = " --algo equihash192_7 --pers auto --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("EquihashBTG", $null);    MinMemGB = 3.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo 144_5 --pers BgoldPoW --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("EquihashZCL", $null);    MinMemGB = 1.0; Fee = @(0.02);    Type = "AMD";    Command = " --algo=192_7 --pers ZcashPoW --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithm = @("Beam", $null);           MinMemGB = 0.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo beam --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("BFC", $null);            MinMemGB = 1.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo bfc --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("Blake2s", $null);        MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo blake2s --cuda 1 --opencl 0" } #Profit very small
    [PSCustomObject]@{ Algorithm = @("CryptonightBBC", $null); MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cryptonightbbc --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29", $null);    MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckarood29 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooM29", $null);    MinMemGB = 4.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo cuckaroom29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("CuckarooZ29", $null);    MinMemGB = 4.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo cuckarooz29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX", $null);  MinMemGB = 8.0; Fee = @(0.03);    Type = "NVIDIA"; Command = " --algo C30CTX --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31", $null);     MinMemGB = 7.4; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckatoo31 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32", $null);     MinMemGB = 7.4; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckatoo32 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29", $null);       MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo cuckoo29 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("Eaglesong", $null);      MinMemGB = 0.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo eaglesong --cuda 1 --opencl 0" } #Profit very small
#   [PSCustomObject]@{ Algorithm = @("Equihash965", $null);    MinMemGB = 0.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash96_5 --cuda 1 --opencl 0" } #Profit very small
    [PSCustomObject]@{ Algorithm = @("Equihash1254", $null);   MinMemGB = 1.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash125_4 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Equihash1445", $null);   MinMemGB = 1.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash144_5 --pers auto --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Equihash1927", $null);   MinMemGB = 2.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash192_7 --pers auto --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Equihash2109", $null);   MinMemGB = 1.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("EquihashZCL", $null);    MinMemGB = 1.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo=192_7 --pers ZcashPoW --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("EquihashBTG", $null);    MinMemGB = 3.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo 144_5 --pers BgoldPoW --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Ethash", $null);         MinMemGB = 4.0; Fee = @(0.0065);  Type = "NVIDIA"; Command = " --algo ethash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");     MinMemGB = 4.0; Fee = @(0.03, 0); Type = "NVIDIA"; Command = " --algo ethash+blake2s --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong");   MinMemGB = 4.0; Fee = @(0.03, 0); Type = "NVIDIA"; Command = " --algo ethash+eaglesong --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = @("Handshake", $null);      MinMemGB = 0.8; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo handshake --cuda 1 --opencl 0" } #Profit very small
    [PSCustomObject]@{ Algorithm = @("KawPoW", $null);         MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo kawpow --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Qitmeer", $null);        MinMemGB = 6.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo qitmeer --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Sero", $null);           MinMemGB = 4.0; Fee = @(0.02);    Type = "NVIDIA"; Command = " --algo sero --cuda 1 --opencl 0" } #Sero != ProgPoW on ZergPool
    [PSCustomObject]@{ Algorithm = @("Vollar", $null);         MinMemGB = 4.0; Fee = @(0.03, 0); Type = "NVIDIA"; Command = " --algo vollar --cuda 1 --opencl 0" }
)

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { $Algo = $_.Algorithm | Select-Object -Index 0; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
            $MinMemGB = $_.MinMemGB

            #Windows 10 requires 1 GB extra
            If ($Algo -match "Cuckaroo*|Cuckoo*" -and [System.Version]$PSVersionTable.BuildVersion -ge "10.0.0.0") { $MinMemGB += 1 }

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ([math]::Round((10 * $_.OpenCL.GlobalMemSize / 1GB), 0) / 10) -ge $MinMemGB })) { 

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "pers", "proto") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                $_.Command += " --server $($Pools.$Algo.Host):$($Pools.$Algo.Port) --user $($Pools.$Algo.User) --pass $($Pools.$Algo.Pass)"

                # If ($Pools.$Algo.SSL) { $_.Command += " --ssl true --ssl_verification false" }
                If ($Algo -eq "Ethash" -and $Pools.$Algo.Name -match "NiceHash*|MPH*") { $_.Command += " --proto stratum" }

                If ($Algo2 = $_.Algorithm | Select-Object -Index 1) { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($Algo2)) -join '-'
                    #If ($Pools.$Algo2.SSL) { $_.Command += " --dssl true --dssl_verification false" }
                    $_.Command += " --dserver $($Pools.$Algo2.Host):$($Pools.$Algo2.Port) --duser $($Pools.$Algo2.User):$($Pools.Algo2.Pass)"
                }
                Else { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'
                }

                If ($null -eq ($_.Algorithm | Select-Object -Index 1) -or $Pools.$Algo2.Host) { 
                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Path       = $Path
                        Arguments  = ("$($_.Command) --api $($MinerAPIPort) --watchdog 0 --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.($DeviceEnumerator)) }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm) | Select-Object
                        API        = "Gminer"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = $_.Fee
                        WarmupTime = 45 #seconds
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
