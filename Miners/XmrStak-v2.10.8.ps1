using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.ComputeCapability -lt 8.6})) { Return }

$Uri = "https://github.com/fireice-uk/xmr-stak/releases/download/2.10.8/xmr-stak-win64-2.10.8.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\xmr-stak.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; MinMemGB = 4; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGB = 3; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" } # SRBMinerMulti-v0.9.6 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     MinMemGB = 1; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   MinMemGB = 1; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; MinMemGB = 1; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    MinMemGB = 1; Type = "AMD"; MinerSet = 1; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";        MinMemGB = 2; Type = "AMD"; MinerSet = 1; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGB = 2; Type = "AMD"; MinerSet = 1; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }
    # [PSCustomObject]@{ Algorithm = "CryptonightXhv";      MinMemGB = 4; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" } # Invalid coin
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noCPU --noNVIDIA --amd" }

    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    Type = "CPU"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --noAMD --noNVIDIA --cpu" }

    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; MinMemGB = 4; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGB = 3; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     MinMemGB = 1; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   MinMemGB = 1; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; MinMemGB = 1; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    MinMemGB = 1; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";        MinMemGB = 2; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGB = 2; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    # [PSCustomObject]@{ Algorithm = "CryptonightXhv";      MinMemGB = 4; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # Invalid coin
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL }) { 

    $Currency = @{ 
        "CryptonightBittube2" = "cryptonight_bittube2"
        "CryptonightGpu"      = "cryptonight_gpu"
        "CryptonightLite"     = "cryptonight_lite"
        "CryptonightLiteV1"   = "cryptonight_lite_v7"
        "CryptonightLiteItbc" = "cryptonight_lite_v7_xor"
        "CryptonightXhv"      = "cryptonight_haven"
        "CryptonightHeavy"    = "cryptonight_heavy"
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

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -eq $_.Type | ForEach-Object { 

            $MinMemGB = $_.MinMemGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGB -gt $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Note: For fine tuning directly edit the config files in the miner binary directory
                $ConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("Config") + @($_.Type) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').txt")
                $MinerThreadsConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("ThreadsConfig") + @($_.Type) + @($_.Algorithm) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') | Select-Object) -join '-').txt")
                $PlatformThreadsConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("HwConfig") + @($_.Type) + @($_.Algorithm) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') | Select-Object) -join '-').txt")
                $PoolFileName = [System.Web.HttpUtility]::UrlEncode("$((@("PoolConf") + @($(Get-PoolBaseName $Pools.($_.Algorithm).Name)) + @($_.Algorithm) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) | Select-Object) -join '-').txt")

                $Arguments = [PSCustomObject]@{ 
                    PoolFile = [PSCustomObject]@{ 
                        FileName = $PoolFileName
                        Content  = [PSCustomObject]@{ 
                            pool_list = @(
                                [PSCustomObject]@{ 
                                    pool_address    = "$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)"
                                    wallet_address  = $Pools.($_.Algorithm).User
                                    pool_password   = $Pools.($_.Algorithm).Pass
                                    use_nicehash    = $($Pools.($_.Algorithm).BaseName -eq "NiceHash")
                                    use_tls         = $Pools.($_.Algorithm).SSL
                                    tls_fingerprint = ""
                                    pool_weight     = 1
                                    rig_id          = "$($Config.Pools.$($Pools.($_.Algorithm).Name).Worker)"
                                }
                            )
                            currency = $(If ($Coins -icontains $Pools.($_.Algorithm).CoinName) { $Pools.($_.Algorithm).CoinName } Else { $Currency.($_.Algorithm) })
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
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = $Arguments | ConvertTo-Json -Depth 10 -Compress
                    Algorithm   = $_.Algorithm
                    API         = "Fireice"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = @(0.02)
                    MinerUri    = "http://localhost:$($MinerAPIPort)/h"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
