@echo off
REM Mandatory parameters
REM     -Pool = "ahashpool"
REM     -Wallet = "1Hgmj84fzSbgYbv2QgrDmBNWSL7762Ry8P"

REM Optional parameters    
REM     -APIUri = "http://www.ahashpool.com/api/walletEx?address="
REM     -PaymentThreshold = 0.01
REM     -Interval = 10
REM     -ShowText = $true
REM     -ShowRawData = $false

REM		Replace Pool name and Wallet below with your info

powershell -version 5.0 -noexit -executionpolicy bypass -windowstyle Normal -command "&.\EarningsTracker.ps1 -Pool ahashpool -Wallet 1Hgmj84fzSbgYbv2QgrDmBNWSL7762Ry8P 
