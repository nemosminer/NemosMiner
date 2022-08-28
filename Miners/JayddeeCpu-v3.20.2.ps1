using module ..\Includes\Include.psm1

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.20.2/cpuminer-opt-3.20.2-windows.zip"
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
    [PSCustomObject]@{ Algorithm = "Blake2b";       MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo blake2b" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";       MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo hmq1725" }
    [PSCustomObject]@{ Algorithm = "Lyra2z330";     MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo lyra2z330" }
    [PSCustomObject]@{ Algorithm = "m7m";           MinerSet = 2; WarmupTimes = @(45, 40); Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "SHA3d";         MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo SHA3d" }
    [PSCustomObject]@{ Algorithm = "ScryptN11";     MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo scrypt(N,1,1)" }
    [PSCustomObject]@{ Algorithm = "ScryptN2";      MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo scrypt --param-n 1048576" }
    [PSCustomObject]@{ Algorithm = "VertHash";      MinerSet = 0; WarmupTimes = @(45, 40); Arguments = " --algo verthash" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";    MinerSet = 0; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  MinerSet = 0; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  MinerSet = 0; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; MinerSet = 0; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; MinerSet = 0; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   MinerSet = 0; WarmupTimes = @(45, 40); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).Host } | Where-Object { $MinerPools[0].($_.Algorithm).AvailablePorts[0] }) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        # Get arguments for available miner devices
        # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $Devices.$DeviceEnumerator

        $PrerequisitePath = ""
        $PrerequisiteURI = ""
        If ($_.Algorithm -eq "VertHash" -and -not (Test-Path -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction SilentlyContinue)) { 
            If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                    New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath | Out-Null
                }
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
            Arguments        = ("$($_.Arguments) --url $(If ($MinerPools[0].($_.Algorithm).AvailablePorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).AvailablePorts[0]) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            Algorithms       = @($_.Algorithm)
            API              = "Ccminer"
            Port             = $MinerAPIPort
            URI              = $Uri
            WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
            PrerequisitePath = $PrerequisitePath
            PrerequisiteURI  = $PrerequisiteURI
        }
    }
}
