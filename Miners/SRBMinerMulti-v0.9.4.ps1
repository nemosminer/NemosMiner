If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $_.Architecture -eq "Other" })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.9.4/SRBMiner-Multi-0-9-4-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = "0x10";              Fee = @(0.0085); MinMemGB = 2;                                            MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm 0x10" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";        Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2id_chukwa2" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Fee = @(0.02; ); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 1.24;   MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm autolykos2" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Fee = @(0);    ; MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm blake2b" }
#   [PSCustomObject]@{ Algorithm = "Blake2s";           Fee = @(0);    ; MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm blake2s" } # ASIC
    [PSCustomObject]@{ Algorithm = "Blake3";            Fee = @(0.01); ; MinMemGB = 2;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Fee = @(00085;); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(60, 30); Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Fee = @(0);    ; MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(60, 30); Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 1; WarmupTimes = @(30, 30); Arguments = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 1; WarmupTimes = @(30, 30); Arguments = " --algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.3 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm cryptonight_xhv" }
#   [PSCustomObject]@{ Algorithm = "DynamoCoin";        Fee = @(0.01); ; MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    [PSCustomObject]@{ Algorithm = "EtcHash";           Fee = @(0.0065); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 1.24;      MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm etchash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";            Fee = @(0.0065); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 1.24;       MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm ethash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";      Fee = @(0.0065); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 1.24; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm ethash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "FiroPow";           Fee = @(0.0085); MinMemGB = $MinerPools[0].FiroPow.DAGSizeGB + 1.24;      MinerSet = 0; WarmupTimes = @(60, 75); Arguments = " --algorithm firopow --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Fee = @(0.01); ; MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";        Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "KawPow";            Fee = @(0.0085); MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 1.24;       MinerSet = 0; WarmupTimes = @(90, 75); Arguments = " --algorithm kawpow --gpu-boost 50" }
#   [PSCustomObject]@{ Algorithm = "Keccak";            Fee = @(0);    ; MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm keccak" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";       Fee = @(0.0065); MinMemGB = 2;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";       Fee = @(0.0065); MinMemGB = $MinerPools[0].ProgPowSero.DAGSizeGB + 1.24;  MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";       Fee = @(0.0065); MinMemGB = 2;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock";  Fee = @(0.0065); MinMemGB = 2;                                            MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithm = "ProgPowanoZ";       Fee = @(0.0065); MinMemGB = $MinerPools[0].ProgPowZano.DAGSizeGB + 1.24;  MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithm = "SHA3d";             Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm sha3d" }
    [PSCustomObject]@{ Algorithm = "VerusHash";         Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Fee = @(0.0125); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algorithm verthash --verthash-dat-path ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Fee = @(0.0085); MinMemGB = 1;                                            MinerSet = 0; WarmupTimes = @(90, 30); Arguments = " --algorithm yescrypt" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 


            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -gt $_.MinMemGB) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --pool $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithm).User)"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { " --worker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " --password $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"
                If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { $Arguments += " --tls true" }
                If ($MinerPools[0].($_.Algorithm).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $Arguments += " --nicehash true" }
                If ($MinerPools[0].($_.Algorithm).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing") { $Arguments += " --esm 1" }
                $Arguments += " --gpu-auto-tune 2--gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',') --disable-cpu"

                If ($_.Type -eq "CPU" -and -not $Variables.UseMinerTweaks) { 
                    $Arguments += " --force-msr-tweaks"
                }

                If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath).length -ne 1283457024) { 
                    $PrerequisitePath = $Variables.VerthashDatPath
                    $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                }
                Else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI = ""
                }

                [PSCustomObject]@{ 
                    Name             = $Miner_Name
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Type             = ($AvailableMiner_Devices.Type | Select-Object -unique)
                    Path             = $Path
                    Arguments        = ("$($Arguments) --disable-workers-ramp-up --api-rig-name $($Config.WorkerName) --api-enable --api-port $MinerAPIPort" -replace "\s+", " ").trim()
                    Algorithms       = @($_.Algorithm)
                    API              = "SRBMiner"
                    Port             = $MinerAPIPort
                    URI              = $Uri
                    Fee              = $_.Fee # Dev fee
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
