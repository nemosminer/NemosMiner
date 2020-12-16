using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.5.9/SRBMiner-Multi-0-5-9-win64.zip"
$SelectedDevices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

#Algorithm names are case sensitive!
$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1; Command = " --algorithm argon2id_chukwa" }
#   [PSCustomObject]@{ Algorithm = "Argon2dDyn";          Type = "AMD"; Fee = 0.0085; MinMemGB = 1; Command = " --algorithm argon2d_dynamic" } #Does not start mining
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";       Type = "AMD"; Fee = 0.0085; MinMemGB = 1; Command = " --algorithm argon2id_ninja" }
    [PSCustomObject]@{ Algorithm = "Blake2b";             Type = "AMD"; Fee = 0;      MinMemGb = 1; Command = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";             Type = "AMD"; Fee = 0;      MinMemGb = 1; Command = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";    Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm cryptonight_gpu" }
#   [PSCustomObject]@{ Algorithm = "CryptonightUpx";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm cryptonight_upx" } #TeamRed-v0.7.20 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm cryptonight_heavyx" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";           Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm eaglesong" }
#   [PSCustomObject]@{ Algorithm = "EtcHash";             Type = "AMD"; Fee = 0.0065; MinMemGb = 4; Command = " --algorithm etchash" } #PhoenixMiner-v5.4b is faster
#   [PSCustomObject]@{ Algorithm = "Ethash";              Type = "AMD"; Fee = 0.0065; MinMemGb = 4; Command = " --algorithm ethash" } #BMiner-v16.3.7 & PhoenixMiner-v5.4b are faster
    [PSCustomObject]@{ Algorithm = "Handshake";           Type = "AMD"; Fee = 0;      MinMemGb = 1; Command = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";          Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";              Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";              Type = "AMD"; Fee = 0;      MinMemGb = 1; Command = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "RainforestV2";        Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm rainforestv2" }
    [PSCustomObject]@{ Algorithm = "Tellor";              Type = "AMD"; Fee = 0;      MinMemGb = 1; Command = " --algorithm tellor" }
    [PSCustomObject]@{ Algorithm = "UbqHash";             Type = "AMD"; Fee = 0.0065; MinMemGb = 1; Command = " --algorithm ubqhash" }
    [PSCustomObject]@{ Algorithm = "VerusHash";           Type = "AMC"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";            Type = "AMD"; Fee = 0.0085; MinMemGb = 1; Command = " --algorithm yescrypt" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Type = "CPU"; Fee = 0.0085; Command = " --algorithm argon2id_chukwa" }
#   [PSCustomObject]@{ Algorithm = "Argon2dDyn";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm argon2d_dynamic" } #Does not start mining
    [PSCustomObject]@{ Algorithm = "Blake2b";             Type = "CPU"; Fee = 0;      Command = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";       Type = "CPU"; Fee = 0.0085; Command = " --algorithm argon2id_ninja" }
    [PSCustomObject]@{ Algorithm = "Blake2s";             Type = "CPU"; Fee = 0;      Command = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Type = "CPU"; Fee = 0;      Command = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "CpuPower";            Type = "CPU"; Fee = 0.0085; Command = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";    Type = "CPU"; Fee = 0.0085; Command = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";      Type = "CPU"; Fee = 0.0085; Command = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Type = "CPU"; Fee = 0.0085; Command = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "CPU"; Fee = 0.0085; Command = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";      Type = "CPU"; Fee = 0.0085; Command = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "CPU"; Fee = 0.0085; Command = " --algorithm cryptonight_heavyx" }
    [PSCustomObject]@{ Algorithm = "CurveHash";           Type = "CPU"; Fee = 0.0085; Command = " --algorithm curvehash" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";           Type = "CPU"; Fee = 0.0085; Command = " --algorithm eaglesong" }
#   [PSCustomObject]@{ Algorithm = "Etchash";             Type = "CPU"; Fee = 0.0065; Command = " --algorithm etchash" } #Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "Ethash";              Type = "CPU"; Fee = 0.0065; Command = " --algorithm ethash" } #Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "Handshake";           Type = "CPU"; Fee = 0.0085; Command = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";              Type = "CPU"; Fee = 0.0085; Command = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";              Type = "CPU"; Fee = 0;      Command = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "RainforestV2";        Type = "CPU"; Fee = 0.0085; Command = " --algorithm rainforestv2" }
#   [PSCustomObject]@{ Algorithm = "Randomx";             Type = "CPU"; Fee = 0.0085; Command = " --algorithm randomx --randomx-use-1gb-pages" } #XmRig-v6.5.0 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxArq";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxHash2";        Type = "CPU"; Fee = 0.0085; Command = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm randomwow --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "ScryptN2";            Type = "CPU"; Fee = 0.0085; Command = " --algorithm scryptn2" }
    [PSCustomObject]@{ Algorithm = "Tellor";              Type = "CPU"; Fee = 0;      Command = " --algorithm tellor" }
    [PSCustomObject]@{ Algorithm = "UbqHash";             Type = "CPU"; Fee = 0.0065; Command = " --algorithm ubqhash" }
    [PSCustomObject]@{ Algorithm = "VerusHash";           Type = "CPU"; Fee = 0.0085; Command = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";            Type = "CPU"; Fee = 0.0085; Command = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";         Type = "CPU"; Fee = 0.0085; Command = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";         Type = "CPU"; Fee = 0.0085; Command = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = "Yespower";            Type = "CPU"; Fee = 0.0085; Command = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";          Type = "CPU"; Fee = 0.0085; Command = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";         Type = "CPU"; Fee = 0     ; Command = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithm = "Yespowerlitb";        Type = "CPU"; Fee = 0.0085; Command = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithm = "Yespowerltncg";       Type = "CPU"; Fee = 0.0085; Command = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";         Type = "CPU"; Fee = 0.0085; Command = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar";       Type = "CPU"; Fee = 0.0085; Command = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";         Type = "CPU"; Fee = 0;      Command = " --algorithm yespowerurx" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "CPU") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object {

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("algorithm") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If (($Miner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                        $DeviceCommand = " --cpu-threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --miner-priority 2 --disable-gpu"
                    }
                    Else { 
                        $DeviceCommand = " --gpu-id $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',') --disable-cpu"
                    }

                    If ($Pools.($_.Algorithm).SSL) { $Command += " --ssl true" }
                    If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MPH(|Coins)$") { $Command += " --nicehash true" }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($Command) --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User) --password $($Pools.($_.Algorithm).Pass) --worker $($Config.Workername) --api-enable --api-port $($MinerAPIPort)$DeviceCommand" -replace "\s+", " ").trim()
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
}
