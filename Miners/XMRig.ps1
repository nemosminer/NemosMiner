if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-XMRig\xmrig-nvidia.exe"
$Uri = "https://github.com/xmrig/xmrig-nvidia/releases/download/v2.7.0-beta/xmrig-nvidia-2.7.0-beta-cuda9-win64.zip"

$Commands = [PSCustomObject]@{
    #"cryptonight" = " --cuda-devices $($Config.SelGPUCC)" #Cryptonight(max 3 gpus)
    #"cryptonight-lite" = " --cuda-devices $($Config.SelGPUCC)" #Cryptonight-lite(max 3 gpus)
    #"cryptonightV7" = " --cuda-devices $($Config.SelGPUCC)" #CryptonightV7(max 3 gpus)
}
$Port = $Variables.NVIDIAMinerAPITCPPort #2222
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) --api-port $port --donate-level 1"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "XMRig"
        Port = $Port
        Wrap = $false
        URI = $Uri    
        User = $Pools.(Get-Algorithm($_)).User
    }
}
