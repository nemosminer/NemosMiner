using module ..\Includes\Include.psm1

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.5.4/SRBMiner-Multi-0-5-4-win64.zip"
$SelectedDevices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"

#Algorithm names are case sensitive!
$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        MinMemGB = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";          MinMemGB = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Blake2b";             MinMemGb = 1; Fee = 0;      Type = "AMD"; Command = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";             MinMemGb = 1; Fee = 0;      Type = "AMD"; Command = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "CryptonightBbc";      MinMemGb = 1; Fee = 0.02;   Type = "AMD"; Command = " --algorithm cryptonight_bbc" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";    MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCatalans"; MinMemGb = 1; Fee = 0;      Type = "AMD"; Command = " --algorithm cryptonight_catalans" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";      MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm cryptonight_gpu" }
#   [PSCustomObject]@{ Algorithm = "CryptonightUpx";      MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm cryptonight_upx" } #TeamRed-v0.7.13 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm cryptonight_heavyx" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";           MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm eaglesong" }
#   [PSCustomObject]@{ Algorithm = "Ethash";              MinMemGb = 4; Fee = 0.0085; Type = "AMD"; Command = " --algorithm ethash" } #Bminer-v16.3.1 & PhoenixMiner-v5.1c are faster
    [PSCustomObject]@{ Algorithm = "Handshake";           MinMemGb = 1; Fee = 0;      Type = "AMD"; Command = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";          MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";              MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";              MinMemGb = 1; Fee = 0;      Type = "AMD"; Command = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "RainforestV2";        MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm rainforestv2" }
    [PSCustomObject]@{ Algorithm = "Tellor";              MinMemGb = 1; Fee = 0;      Type = "AMD"; Command = " --algorithm tellor" }
    [PSCustomObject]@{ Algorithm = "UbqHash";             MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm ubqhash" }
    [PSCustomObject]@{ Algorithm = "VerusHash";           MinMemGb = 1; Fee = 0.0085; Type = "AMC"; Command = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";            MinMemGb = 1; Fee = 0.0085; Type = "AMD"; Command = " --algorithm yescrypt" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Fee = 0.0085; Type = "CPU"; Command = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";          Fee = 0;      Type = "CPU"; Command = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Blake2b";             Fee = 0;      Type = "CPU"; Command = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";             Fee = 0;      Type = "CPU"; Command = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Fee = 0;      Type = "CPU"; Command = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "CpuPower";            Fee = 0.0085; Type = "CPU"; Command = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "CryptonightBbc";      Fee = 0.02;   Type = "CPU"; Command = " --algorithm cryptonight_bbc" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";    Fee = 0.0085; Type = "CPU"; Command = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCatalans"; Fee = 0;      Type = "CPU"; Command = " --algorithm cryptonight_catalans" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";      Fee = 0.0085; Type = "CPU"; Command = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Fee = 0.0085; Type = "CPU"; Command = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Fee = 0.0085; Type = "CPU"; Command = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";      Fee = 0.0085; Type = "CPU"; Command = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Fee = 0.0085; Type = "CPU"; Command = " --algorithm cryptonight_heavyx" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";           Fee = 0.0085; Type = "CPU"; Command = " --algorithm eaglesong" }
    [PSCustomObject]@{ Algorithm = "Ethash";              Fee = 0.0085; Type = "CPU"; Command = " --algorithm ethash" }
    [PSCustomObject]@{ Algorithm = "Handshake";           Fee = 0.85;   Type = "CPU"; Command = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";          Fee = 0.0085; Type = "CPU"; Command = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";              Fee = 0.0085; Type = "CPU"; Command = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";              Fee = 0;      Type = "CPU"; Command = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "RainforestV2";        Fee = 0.0085; Type = "CPU"; Command = " --algorithm rainforestv2" }
#   [PSCustomObject]@{ Algorithm = "Randomx";             Fee = 0.0085; Type = "CPU"; Command = " --algorithm randomx --randomx-use-1gb-pages" } #XmRig-v6.3.5 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxArq";          Fee = 0.0085; Type = "CPU"; Command = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";          Fee = 0.0085; Type = "CPU"; Command = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";          Fee = 0.0085; Type = "CPU"; Command = " --algorithm randomwow" }
    [PSCustomObject]@{ Algorithm = "VerusHash";           Fee = 0.0085; Type = "CPU"; Command = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";          Fee = 0.0085; Type = "CPU"; Command = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";         Fee = 0.0085; Type = "CPU"; Command = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";         Fee = 0.0085; Type = "CPU"; Command = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = "Yespower";            Fee = 0.0085; Type = "CPU"; Command = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";          Fee = 0.0085; Type = "CPU"; Command = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";         Fee = 0     ; Type = "CPU"; Command = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithm = "Yespowerlitb";        Fee = 0.0085; Type = "CPU"; Command = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithm = "Yespowerltncg";       Fee = 0.0085; Type = "CPU"; Command = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";         Fee = 0.0085; Type = "CPU"; Command = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar";       Fee = 0.0085; Type = "CPU"; Command = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";         Fee = 0;      Type = "CPU"; Command = " --algorithm yespowerurx" }
    [PSCustomObject]@{ Algorithm = "Tellor";              Fee = 0;      Type = "CPU"; Command = " --algorithm tellor" }
    [PSCustomObject]@{ Algorithm = "UbqHash";             Fee = 0.85;   Type = "CPU"; Command = " --algorithm ubqhash" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";            Fee = 0.0085; Type = "CPU"; Command = " --algorithm yescrypt" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "CPU") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object {

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("algorithm") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^NiceHash*|^MPH*") { $Command += " --nicehash true" }

                    If (($Miner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                        $DeviceCommand = " --cpu-threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --miner-priority 2 --disable-gpu"
                    }
                    Else { 
                        $DeviceCommand = " --gpu-id $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',') --disable-cpu"
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($Command) --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User) --password $($Pools.($_.Algorithm).Pass) --worker $($Config.Workername) --api-enable --api-port $($MinerAPIPort)$(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash true" })$(If ($Pools.($_.Algorithm).SSL) { " --ssl true" })$DeviceCommand" -replace "\s+", " ").trim()
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
