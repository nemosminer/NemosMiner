if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-MultiMiner\multiminer.exe"
$Uri = "https://github.com/bogdanadnan/multiminer/releases/download/v1.1.0/multiminer_v1.1.0_24.01.2019.zip"

$Commands = [PSCustomObject]@{
    "argon2d4096" = " -a argon2d4096 --use-gpu=CUDA --gpu-batchsize=512 -t 2" #Argon2d4096 ( --gpu-id=$($Config.SelGPUCC) )
    "argon2d-uis" = " -a argon2d4096 --use-gpu=CUDA --gpu-batchsize=512 -t 2" #Argon2d4096  
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--max-temp=95 -R 1 -q -b $($Variables.NVIDIAMinerAPITCPPort) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
