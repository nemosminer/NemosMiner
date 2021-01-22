using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.6.3/SRBMiner-Multi-0-6-3-win64.zip"
$SelectedDevices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

# Algorithm names are case sensitive!
$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; Arguments = " --algorithm argon2id_chukwa" }
#   [PSCustomObject]@{ Algorithm = "Argon2dDyn";          Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 1; Arguments = " --algorithm argon2d_dynamic" } # Does not start mining
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";       Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; Arguments = " --algorithm argon2id_ninja" }
    [PSCustomObject]@{ Algorithm = "Blake2b";             Type = "AMD"; Fee = 0;      MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";             Type = "AMD"; Fee = 0;      MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "CircCash";            Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";    Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";      Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 1; Arguments = " --algorithm cryptonight_upx" } # TeamRed-v0.8.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm cryptonight_heavyx" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";           Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm eaglesong" }
    [PSCustomObject]@{ Algorithm = "EtcHash";             Type = "AMD"; Fee = 0.0065; MinMemGb = 4; MinerSet = 1; Arguments = " --algorithm etchash" } # PhoenixMiner-v5.4c is faster
    [PSCustomObject]@{ Algorithm = "Ethash";              Type = "AMD"; Fee = 0.0065; MinMemGb = 4; MinerSet = 1; Arguments = " --algorithm ethash" } # BMiner-v16.3.7 & PhoenixMiner-v5.4c are faster
    [PSCustomObject]@{ Algorithm = "Handshake";           Type = "AMD"; Fee = 0;      MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";          Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";              Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";              Type = "AMD"; Fee = 0;      MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "UbqHash";             Type = "AMD"; Fee = 0.0065; MinMemGb = 2; MinerSet = 1; Arguments = " --algorithm ubqhash" } # PhoenixMiner-v5.4c is fastest
    [PSCustomObject]@{ Algorithm = "Phi5";                Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm phi5" }
    [PSCustomObject]@{ Algorithm = "VerusHash";           Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";            Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "Zentoshi";            Type = "AMD"; Fee = 0.0085; MinMemGb = 1; MinerSet = 0; Arguments = " --algorithm balloon_zentoshi" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";          Type = "CPU"; Fee = 0.0085; MinerSet = 1; Arguments = " --algorithm argon2d_dynamic" } # Does not start mining
    [PSCustomObject]@{ Algorithm = "Blake2b";             Type = "CPU"; Fee = 0;      MinerSet = 0; Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm argon2id_ninja" }
    [PSCustomObject]@{ Algorithm = "Blake2s";             Type = "CPU"; Fee = 0;      MinerSet = 0; Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";        Type = "CPU"; Fee = 0;      MinerSet = 0; Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "CircCash";            Type = "AMD"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CpuPower";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm cryptonight_heavyx" }
    [PSCustomObject]@{ Algorithm = "CurveHash";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm curvehash" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm eaglesong" }
    [PSCustomObject]@{ Algorithm = "EtcHash";             Type = "CPU"; Fee = 0.0065; MinerSet = 1; Arguments = " --algorithm etchash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "Ethash";              Type = "CPU"; Fee = 0.0065; MinerSet = 1; Arguments = " --algorithm ethash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "Handshake";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";              Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";              Type = "CPU"; Fee = 0;      MinerSet = 0; Arguments = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "Phi5";                Type = "COU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm phi5" }
    [PSCustomObject]@{ Algorithm = "Randomx";             Type = "CPU"; Fee = 0.0085; MinerSet = 1; Arguments = " --algorithm randomx --randomx-use-1gb-pages" } # XmRig-v6.7.0 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxArq";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxHash2";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm randomwow --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "ScryptN2";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm scryptn2" }
    [PSCustomObject]@{ Algorithm = "UbqHash";             Type = "CPU"; Fee = 0.0065; MinerSet = 1; Arguments = " --algorithm ubqhash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "VerusHash";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = "Yespower";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";         Type = "CPU"; Fee = 0     ; MinerSet = 0; Arguments = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithm = "YespowerTide";        Type = "CPU"; Fee = 0;      MinerSet = 1; Arguments = " --algorithm yespowertide" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";         Type = "CPU"; Fee = 0;      MinerSet = 1; Arguments = " --algorithm yespowerurx" }
    [PSCustomObject]@{ Algorithm = "Zentoshi";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; Arguments = " --algorithm balloon_zentoshi" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "CPU") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object {

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash", "KawPoW")) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get commands for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("algorithm") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If (($Miner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                        $DeviceArguments = " --cpu-threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                    }
                    Else { 
                        $DeviceArguments = " --gpu-id $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',') --disable-cpu"
                    }

                    $Arguments += " --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)"
                    If ($Pools.($_.Algorithm).SSL) { $Arguments += " --ssl true" }
                    If ($_.Algorithm -in @("EtcHash", "Ethash", "UbqHash") -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MPH(|Coins)$") { $Arguments += " --nicehash true" }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$Arguments --wallet $($Pools.($_.Algorithm).User) --password $($Pools.($_.Algorithm).Pass) --worker $($Config.Workername) --disable-workers-ramp-up --api-enable --api-port $($MinerAPIPort)$DeviceArguments" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "SRBMiner"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = $_.Fee # Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)/stats"
                    }
                }
            }
        }
    }
}
