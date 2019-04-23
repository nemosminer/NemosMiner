if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\CPU-XMRig\xmrig.exe"
$Uri = "https://github.com/xmrig/xmrig/releases/download/v2.6.2/xmrig-2.6.2-msvc-win64.zip"

$Commands = [PSCustomObject]@{
    #"cryptonight" = "" #Cryptonight
    #"cryptonight-lite" = "" #Cryptonight-lite
    #"cryptonight-heavy" = "" #Cryptonight-Heavy
    #"cryptonightV7" = "" #CryptonightV7
}

$ThreadCount = $ThreadCount = $Variables.ProcessorCount - 2

$Port = $Variables.CPUMinerAPITCPPort #2222
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        # Arguments = "-t $($ThreadCount) -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) --api-port $($port) --donate-level 1"
        Arguments = "-a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) --api-port $($port) --donate-level 1"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Week * .99} # substract 1% devfee
        API = "XMRig"
        Port = $Port
        Wrap = $false
        URI = $Uri    
		User = $Pools.($Algo).User
    }
}
