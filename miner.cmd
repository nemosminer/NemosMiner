@echo off
set DIR=%~dp0

cd %DIR%
powershell -version 5.0 -noexit -executionpolicy bypass -windowstyle minimized -command "&.\NemosMiner-v2.3.ps1 -PoolName ahashpool -Algorithm xevan,hsr,phi,tribus,c11,lbry,skein,timetravel,sib,bitcore,x17,Nist5,MyriadGroestl,Lyra2RE2,neoscrypt,blake2s,skunk,Groestl,HMQ1725,Keccak,Scrypt -WorkerName NemosMiner

; powershell -version 5.0 -noexit -executionpolicy bypass -windowstyle minimized -command "&.\NemosMiner-v2.3.ps1 -SelGPUDSTM '0 1' -SelGPUCC '0,1' -Currency USD -Passwordcurrency BTC -interval 30 -Wallet 1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE -Location US -PoolName ahashpool -Type nvidia -Algorithm xevan,hsr,phi,tribus,c11,lbry,skein,timetravel,sib,bitcore,x17,Nist5,MyriadGroestl,Lyra2RE2,neoscrypt,blake2s,skunk,Groestl,HMQ1725,Keccak,Scrypt -Donate 5 -WorkerName NemosMiner
