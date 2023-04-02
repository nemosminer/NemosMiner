If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.ComputeCapability -lt 8.6})) { Return }

$Uri = "https://github.com/fireice-uk/xmr-stak/releases/download/2.10.8/xmr-stak-win64-2.10.8.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\xmr-stak.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; MinMemGiB = 4; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGiB = 3; Type = "AMD"; Minerset = 1; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" } # SRBMinerMulti-v2.2.4 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     MinMemGiB = 1; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   MinMemGiB = 1; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; MinMemGiB = 1; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    MinMemGiB = 1; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.18.1 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv"; MinMemGiB = 4; Type = "AMD"; Minerset = 1; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" } # SRBMinerMulti-v2.2.4 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      MinMemGiB = 2; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";        MinMemGiB = 2; Type = "AMD"; Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGiB = 2; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.18.1 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      MinMemGiB = 2; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       MinMemGiB = 2; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       MinMemGiB = 2; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      MinMemGiB = 2; Type = "AMD"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noCPU --noNVIDIA --amd" }

    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 20); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" } # XmRig-v6.18.1 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv"; Type = "CPU"; Minerset = 1; WarmupTimes = @(45, 20); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";        Type = "CPU"; Minerset = 3; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }

    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; MinMemGiB = 4; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGiB = 3; Type = "NVIDIA"; Minerset = 1; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     MinMemGiB = 1; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   MinMemGiB = 1; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; MinMemGiB = 1; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    MinMemGiB = 1; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv"; MinMemGiB = 4; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      MinMemGiB = 2; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";        MinMemGiB = 2; Type = "NVIDIA"; Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGiB = 2; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # XmRig-v6.18.1 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      MinMemGiB = 2; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       MinMemGiB = 2; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       MinMemGiB = 2; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      MinMemGiB = 2; Type = "NVIDIA"; Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $Currency = @{ 
        "CryptonightBittube2" = "cryptonight_bittube2"
        "CryptonightGpu"      = "cryptonight_gpu"
        "CryptonightLite"     = "cryptonight_lite"
        "CryptonightLiteV1"   = "cryptonight_lite_v7"
        "CryptonightLiteItbc" = "cryptonight_lite_v7_xor"
        "CryptonightHeavy"    = "cryptonight_heavy"
        "CryptonightHeavyXhv" = "cryptonight_haven"
        "CryptonightMsr"      = "cryptonight_masari"
        "CryptonightR"        = "cryptonight_r"
        "CryptonightDouble"   = "cryptonight_v8_double"
        "CryptonightRwz"      = "cryptonight_v8_reversewaltz"
        "CryptonightV1"       = "cryptonight_v7"
        "CryptonightXtl"      = "cryptonight_v7_stellite"
        "CryptonightV2"       = "cryptonight_v8"
    }

    $Coins = @("aeon7", "bbscoin", "bittube", "freehaven", "graft", "haven", "intense", "masari", "monero" ,"qrl", "ryo", "stellite", "turtlecoin")

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -eq $_.Type | ForEach-Object { 

            $MinMemGiB = $_.MinMemGiB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGiB -gt $MinMemGiB }) { 

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

                # Note: For fine tuning directly edit the config files in the miner binary directory
                $ConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("Config") + @($_.Type) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').txt")
                $MinerThreadsConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("ThreadsConfig") + @($_.Type) + @($_.Algorithm) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') | Select-Object) -join '-').txt")
                $PlatformThreadsConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("HwConfig") + @($_.Type) + @($_.Algorithm) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') | Select-Object) -join '-').txt")
                $PoolFileName = [System.Web.HttpUtility]::UrlEncode("$((@("PoolConf") + @($(Get-PoolBaseName $MinerPools[0].($_.Algorithm).Name)) + @($_.Algorithm) + @($MinerPools[0].($_.Algorithm).User) + @($MinerPools[0].($_.Algorithm).Pass) | Select-Object) -join '-').txt")

                $Arguments = [PSCustomObject]@{ 
                    PoolFile = [PSCustomObject]@{ 
                        FileName = $PoolFileName
                        Content  = [PSCustomObject]@{ 
                            pool_list = @(
                                [PSCustomObject]@{ 
                                    pool_address    = "$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1)"
                                    wallet_address  = $MinerPools[0].($_.Algorithm).User
                                    pool_password   = $MinerPools[0].($_.Algorithm).Pass
                                    use_nicehash    = $($MinerPools[0].($_.Algorithm).BaseName -eq "NiceHash")
                                    use_tls         = [Boolean]$MinerPools[0].($_.Algorithm).PoolPorts[1]
                                    tls_fingerprint = ""
                                    pool_weight     = 1
                                    rig_id          = "$($MinerPools[0].($_.Algorithm).WorkerName)"
                                }
                            )
                            currency = $(If ($Coins -icontains $MinerPools[0].($_.Algorithm).CoinName) { $MinerPools[0].($_.Algorithm).CoinName } Else { $Currency.($_.Algorithm) })
                        }
                    }
                    ConfigFile = [PSCustomObject]@{ 
                        FileName = $ConfigFileName
                        Content  = [PSCustomObject]@{ 
                            call_timeout    = 10
                            retry_time      = 10
                            giveup_limit    = 0
                            verbose_level   = 99
                            print_motd      = $true
                            h_print_time    = 60
                            aes_override    = $null
                            use_slow_memory = "warn"
                            tls_secure_algo = $true
                            daemon_mode     = $false
                            flush_stdout    = $false
                            output_file     = ""
                            httpd_port      = [UInt16]$MinerAPIPort
                            http_login      = ""
                            http_pass       = ""
                            prefer_ipv4     = $true
                        }
                    }
                    Arguments = "--poolconf $PoolFileName --config $ConfigFileName$($_.Arguments) $MinerThreadsConfigFileName --noUAC --httpd $($MinerAPIPort)".trim()
                    Devices  = @($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique)
                    HwDetectArguments = "--poolconf $PoolFileName --config $ConfigFileName$($_.Arguments) $PlatformThreadsConfigFileName --httpd $($MinerAPIPort)".trim()
                    MinerThreadsConfigFileName = $MinerThreadsConfigFileName
                    Platform = $Platform
                    PlatformThreadsConfigFileName = $PlatformThreadsConfigFileName
                    Threads = 1
                }

                If ($AvailableMiner_Devices.PlatformId) { $Arguments.ConfigFile.Content | Add-Member "platform_index" (($AvailableMiner_Devices | Select-Object PlatformId -Unique).PlatformId) }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Fireice"
                    Arguments   = $Arguments | ConvertTo-Json -Depth 10 -Compress
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = @(0.02)
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)/h"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = $_.Type
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}