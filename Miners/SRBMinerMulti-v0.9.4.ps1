<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.1.1
Version date:   2023/10/06
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $_.Architecture -eq "Other" })) { Return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.9.4/SRBMiner-Multi-0-9-4-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "0x10";              Fee = @(0.0085); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu -algorithm 0x10" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Fee = @(0.0085); MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu -algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";        Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu -algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu -algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu -algorithm argon2id_chukwa2" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Fee = @(0.02; ); MinMemGiB = 1.24; Minerset = 0; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm autolykos2" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Fee = @(0);    ; MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm blake2b" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Blake2s";           Fee = @(0);    ; MinMemGiB = 1;    Minerset = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm blake2s" } # ASIC
    [PSCustomObject]@{ Algorithm = "Blake3";            Fee = @(0.01); ; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Fee = @(00085;); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Fee = @(0.0085); MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(60, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Fee = @(0);    ; MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(60, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.3 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm cryptonight_xhv" }
#   [PSCustomObject]@{ Algorithm = "DynamoCoin";        Fee = @(0.01); ; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    [PSCustomObject]@{ Algorithm = "EtcHash";           Fee = @(0.0065); MinMemGiB = 1.24; Minerset = 0; WarmupTimes = @(90, 75); ExcludePools = @(); Arguments = " --disable-cpu -algorithm etchash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";            Fee = @(0.0065); MinMemGiB = 1.24; Minerset = 0; WarmupTimes = @(90, 75); ExcludePools = @(); Arguments = " --disable-cpu -algorithm ethash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "FiroPow";           Fee = @(0.0085); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(60, 75); ExcludePools = @(); Arguments = " --disable-cpu -algorithm firopow --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Fee = @(0.01); ; MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm heavyhash" } # FPGA
#   [PSCustomObject]@{ Algorithm = "K12";               Fee = @(0.0085); MinMemGiB = 1;    Minerset = 3; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm k12" } # ASIC
    [PSCustomObject]@{ Algorithm = "KawPow";            Fee = @(0.0085); MinMemGiB = 1.24; Minerset = 1; WarmupTimes = @(90, 75); ExcludePools = @(); Arguments = " --disable-cpu -algorithm kawpow --gpu-boost 50" }
#   [PSCustomObject]@{ Algorithm = "Keccak";            Fee = @(0);    ; MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm keccak" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Fee = @(0.0085); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";       Fee = @(0.0065); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";       Fee = @(0.0065); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";       Fee = @(0.0065); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock";  Fee = @(0.0065); MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithm = "ProgPowanoZ";       Fee = @(0.0065); MinMemGiB = 1.24; Minerset = 0; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithm = "SHA3d";             Fee = @(0.0085); MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm sha3d" } # FPGU
#   [PSCustomObject]@{ Algorithm = "VerusHash";         Fee = @(0.0085); MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Fee = @(0.0125); MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm verthash --verthash-dat-path ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Fee = @(0.0085); MinMemGiB = 1;    Minerset = 0; WarmupTimes = @(90, 30); ExcludePools = @(); Arguments = " --disable-cpu -algorithm yescrypt" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $Pool.DAGSizeGiB
    }

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools)) { 

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -gt $_.MinMemGiB) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    $Arguments += Switch ($Pool.Protocol) { 
                        "ethproxy"     { " --esm 0" }
                        "ethstratum1"  { " --esm 1" }
                        "ethstratum2"  { " --esm 2" }
                        "ethstratumnh" { " --esm 2" }
                        "minerproxy"   { " --esm 1" }
                        Default        { "" }
                    }
                    $Arguments += " --pool $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User)"
                    If ($Pool.WorkerName) { " --worker $($Pool.WorkerName)" }
                    $Arguments += " --password $($Pool.Pass)"
                    If ($Pool.PoolPorts[1]) { $Arguments += " --tls true" }

                    If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                    Else { 
                        $PrerequisitePath = ""
                        $PrerequisiteURI = ""
                    }

                    [PSCustomObject]@{ 
                        Algorithms       = @($_.Algorithm)
                        API              = "SRBMiner"
                        Arguments        = "$Arguments --disable-workers-ramp-up --api-rig-name $($Config.WorkerName) --api-enable --api-port $MinerAPIPort --gpu-auto-tune 2 --gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                        DeviceNames      = $AvailableMiner_Devices.Name
                        Fee              = $_.Fee # Dev fee
                        MinerSet         = $_.MinerSet
                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                        Name             = $Miner_Name
                        Path             = $Path
                        Port             = $MinerAPIPort
                        PrerequisitePath = $PrerequisitePath
                        PrerequisiteURI  = $PrerequisiteURI
                        Type             = "AMD"
                        URI              = $Uri
                        WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers          = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}