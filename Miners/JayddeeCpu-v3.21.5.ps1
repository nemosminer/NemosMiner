If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.21.5/cpuminer-opt-3.21.5-windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" # Intel

If     ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx512", "sha", "vaes") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = ".\Bin\$($Name)\cpuminer-avx512-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2", "sha", "vaes")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx512")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = ".\Bin\$($Name)\cpuminer-avx512.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2", "sha")           -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = ".\Bin\$($Name)\cpuminer-avx2.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx")                   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = ".\Bin\$($Name)\cpuminer-avx.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("aes", "sse42")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" }
Else { Return }

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Blake2b";       MinerSet = 3; WarmupTimes = @(45, 30); Arguments = " --algo blake2b" } # FPGA
    [PSCustomObject]@{ Algorithm = "HMQ1725";       Minerset = 3; WarmupTimes = @(45, 45); Arguments = " --algo hmq1725" } # GPU
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";     MinerSet = 3; WarmupTimes = @(45, 45); Arguments = " --algo lyra2z330" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "m7m";           Minerset = 1; WarmupTimes = @(45, 80); Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "SHA3d";         MinerSet = 3; WarmupTimes = @(45, 40); Arguments = " --algo SHA3d" } # FPGA
    [PSCustomObject]@{ Algorithm = "ScryptN11";     Minerset = 3; WarmupTimes = @(45, 40); Arguments = " --algo scrypt(N,1,1)" } # GPU
    [PSCustomObject]@{ Algorithm = "ScryptN2";      Minerset = 1; WarmupTimes = @(90, 60); Arguments = " --algo scrypt --param-n 1048576" }
    [PSCustomObject]@{ Algorithm = "VertHash";      MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo verthash --data-file ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  Minerset = 2; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "ARWN"' } # Arrowana
    [PSCustomObject]@{ Algorithm = "YespowerIc";    Minerset = 2; WarmupTimes = @(45, 60); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  Minerset = 2; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  Minerset = 2; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; Minerset = 2; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    [PSCustomObject]@{ Algorithm = "YespowerMGPC";  Minerset = 2; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Magpies are birds of the Corvidae family."' } # Magpiecoin
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; Minerset = 1; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  Minerset = 1; WarmupTimes = @(45, 55); Arguments = ' --algo yespower --param-n 2048 --param-r 8' } # TDC tidecoin
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   MinerSet = 0; WarmupTimes = @(45, 60); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath).length -ne 1283457024) { 
            $PrerequisitePath = $Variables.VerthashDatPath
            $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
        }
        Else { 
            $PrerequisitePath = ""
            $PrerequisiteURI = ""
        }

        # Get arguments for available miner devices
        # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Algorithms       = @($_.Algorithm)
            API              = "Ccminer"
            Arguments        = ("$($_.Arguments) --url $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            DeviceNames      = $AvailableMiner_Devices.Name
            MinerSet         = $_.MinerSet
            Name             = $Miner_Name
            Path             = $Path
            Port             = $MinerAPIPort
            PrerequisitePath = $PrerequisitePath
            PrerequisiteURI  = $PrerequisiteURI
            Type             = ($AvailableMiner_Devices.Type | Select-Object -Unique)
            URI              = $Uri
            WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
        }
    }
}

$Error.Clear()