if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-XMRig2140\xmrig-nvidia.exe"
$Uri = "https://github.com/xmrig/xmrig-nvidia/releases/download/v2.14.0/xmrig-nvidia-2.14.0-cuda10-win64.zip"

$Commands = [PSCustomObject]@{
    #"cryptonight" = " --cuda-devices $($Config.SelGPUCC)" #Cryptonight
    #"cryptonight-lite" = " --cuda-devices $($Config.SelGPUCC)" #Cryptonight-lite
    #"cryptonightV7" = " --cuda-devices $($Config.SelGPUCC)" #CryptonightV7
    #"cryptonightV8" = " --cuda-devices $($Config.SelGPUCC)" #CryptonightV7
    #"cryptonightheavy" = " --cuda-devices $($Config.SelGPUCC)" #CryptonightHeavy
    #"cryptonightr" = " --cuda-devices $($Config.SelGPUCC)" #cryptonightR (Monero)
}
$Port = 4068 #2222
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) --api-port 4068 --donate-level 1"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .99} # substract 1% devfee
        API = "XMRig"
        Port = 4068
        Wrap = $false
        URI = $Uri    
        User = $Pools.(Get-Algorithm($_)).User
    }
}
