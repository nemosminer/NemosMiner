if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\Nvida-FireIce2108\xmr-stak.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/2.10.8/xmr-stak-win64-2.10.8-cuda10.0.7z"
$Commands = [PSCustomObject]@{
    #"cryptonight_haven"   = "cryptonight_haven" #cryptonight_haven 
    #"cryptonight_gpu"     = "cryptonight_gpu" #Cryptonight_gpu
    #"cryptonight_fast"    = "cryptonight_v8_half" #cryptonightFast
    #"cryptonight_heavy"   = "cryptonight_heavy" #cryptonight_heavy 
    #"cryptonight_conceal" = "cryptonight_conceal" #cryptonight_conceal
    #"cryptonight-saber"   = "cryptonight_bittube2" #cryptonight-saber
    #"cryptonight_xeq"     = "cryptonight_gpu" #cryptonight_xeq
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    ([PSCustomObject]@{
            pool_list       = @([PSCustomObject]@{
                    pool_address    = "$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
                    wallet_address  = "$($Pools.$Algo.User)"
                    pool_password   = "$($Pools.$Algo.Pass)"
                    use_nicehash    = $true
                    use_tls         = "$($Pools.$Algo.SSL)"
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
    ) -replace "^{" -replace "}$" | Set-Content "$(Split-Path $Path)\$($Pools.$Algo.Name)_$($Pools.$Algo)_$($Pools.$Algo.User)_CPU.txt" -Force -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-C $($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_Nvidia.txt --noAMD --noCPU -i $($Variables.NVIDIAMinerAPITCPPort)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day } #Recompiled 0% fee
        API       = "fireice"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
} 
