using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $_.Architecture -eq "Other" })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.9.4/SRBMiner-Multi-0-9-4-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Miner_Devices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = "0x10";              Fee = 0.085;  MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm 0x10" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2id_chukwa2" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Fee = 0.02;   MinMemGB = $Pools."Autolykos2".DAGSizeGB;   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algorithm autolykos2" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Blake3";            Fee = 0.01;   MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Fee = 00085;  MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_upx" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_xhv" }
    # [PSCustomObject]@{ Algorithm = "DynamoCoin";      Fee = 0.01;   MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    [PSCustomObject]@{ Algorithm = "EtcHash";           Fee = 0.0065; MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm etchash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";            Fee = 0.0065; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm ethash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";      Fee = 0.0065; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm ethash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "FiroPoW";           Fee = 0.0085; MinMemGB = $Pools."FiroPoW".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(90, 75); Arguments = " --algorithm firopow --gpu-boost 50 --gpu-auto-tune 2" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Fee = 0.01;   MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";        Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "KawPoW";            Fee = 0.085;  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(90, 75); Arguments = " --algorithm kawpow --gpu-boost 50 --gpu-auto-tune 2" }
    [PSCustomObject]@{ Algorithm = "Keccak";            Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = "ProgPoWEpic";       Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";       Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";       Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock";  Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";       Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithm = "SHA3d";             Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm sha3d" }
    [PSCustomObject]@{ Algorithm = "VerusHash";         Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Fee = 0.0125; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescrypt" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.MemoryGB -gt $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User)"
                If ($Pools.($_.Algorithm).WorkerName) { " --worker $($Pools.($_.Algorithm).WorkerName)" }
                $_.Arguments += " --password $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl true" }
                If ($Pools.($_.Algorithm).DAGsizeGB -ne $null -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                If ($Pools.($_.Algorithm).DAGsizeGB -ne $null -and $Pools.($_.Algorithm).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }
                $_.Arguments += " --gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',') --disable-cpu"

                $PrerequisitePath = ""
                $PrerequisiteURI = ""
                If ($_.Algorithm -eq "VertHash") { 
                    If ((Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -eq 1283457024) { 
                        New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath -ErrorAction Ignore | Out-Null
                    }
                    Else { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                }

                [PSCustomObject]@{ 
                    Name             = $Miner_Name
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Type             = $AvailableMiner_Devices.Type
                    Path             = $Path
                    Arguments        = ("$($_.Arguments) --disable-workers-ramp-up --api-enable --api-port $MinerAPIPort" -replace "\s+", " ").trim()
                    Algorithms       = $_.Algorithm
                    API              = "SRBMiner"
                    Port             = $MinerAPIPort
                    URI              = $Uri
                    Fee              = $_.Fee # Dev fee
                    MinerUri         = "http://localhost:$($MinerAPIPort)/stats"
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
