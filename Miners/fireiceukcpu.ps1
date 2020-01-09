if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\Cpu-FireIce2108\xmr-stak.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/2.10.8/xmr-stak-win64-2.10.8-cuda10.0.7z"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Port = $Variables.CPUMinerAPITCPPort

$Commands = [PSCustomObject]@{
    #"cryptonight_haven"   = "cryptonight_haven" #cryptonight_haven 
    #"cryptonight_heavy"   = "cryptonight_heavy" #cryptonight_heavy 
    #"cryptonight_conceal" = "cryptonight_conceal" #cryptonight_conceal
    #"cryptonight_heavyx"  = "cryptonight_v8_double" #cryptonight_heavyx
}

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm($_)

    ([PSCustomObject]@{
            pool_list       = @([PSCustomObject]@{
                    pool_address    = "$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port)"
                    wallet_address  = "$($Pools.$Algorithm_Norm.User)"
                    pool_password   = "$($Pools.$Algorithm_Norm.Pass)"
                    use_nicehash    = $true
                    use_tls         = $Pools.$Algorithm_Norm.SSL
                    tls_fingerprint = ""
                    pool_weight     = 1
                    rig_id          = ""
                }
            )
            currency        = $Commands.$_
            call_timeout    = 10
            retry_time      = 10
            giveup_limit    = 0
            verbose_level   = 3
            print_motd      = $true
            h_print_time    = 60
            aes_override    = $null
            use_slow_memory = "warn"
            tls_secure_algo = $true
            daemon_mode     = $false
            flush_stdout    = $false
            output_file     = ""
            httpd_port      = $Port
            http_login      = ""
            http_pass       = ""
            prefer_ipv4     = $true
        } | ConvertTo-Json -Depth 10
    ) -replace "^{" -replace "}$" | Set-Content "$(Split-Path $Path)\$($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_CPU.txt" -Force -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "-C $($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_CPU.txt --noAMD --noNVIDIA -i $($Variables.CPUMinerAPITCPPort)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Day } #recompiled 0% Dev fee
        API       = "fireice"
        Port      = $Variables.CPUMinerAPITCPPort
        URI       = $Uri
    }
} 
