@echo off
cd /d %~dp0
ECHO This process will remove all benchmarking data.
set /p benchreset=Are you sure you want to continue? [Y/N] 
IF /I "%benchreset%"=="Y" (
	if exist "..\Stats\*_HashRate.txt" del "..\Stats\*_HashRate.txt"
	ECHO Success. You need to re-benchmark all miners to continue using NemosMiner. 
	PAUSE
)
