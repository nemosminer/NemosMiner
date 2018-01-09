@echo off
set DIR=%~dp0

cd %DIR%
powershell -version 5.0 -noexit -executionpolicy bypass -windowstyle minimized -command "&.\NemosMiner-v2.3.ps1 -SelGPUDSTM '0 1' -SelGPUCC '0,1' -Currency USD -Passwordcurrency BTC -interval 30 -Wallet 1G1384gnsaswY3ddHukcCv4rEGbhsEnrrg -Location US -PoolName ahashpool -Type nvidia -Algorithm xevan,hsr,phi,tribus,c11,lbry,skein,timetravel,sib,bitcore,x17,Nist5,MyriadGroestl,Lyra2RE2,neoscrypt,blake2s,skunk,Groestl,HMQ1725,Keccak,Scrypt -Donate 0 -WorkerName server
