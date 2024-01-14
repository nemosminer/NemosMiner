@echo off
cd /d %~dp0
ECHO This process will remove all power usage data.
set /p powerusagereset=Are you sure you want to continue? [Y/N] 
IF /I "%powerusagereset%"=="Y" (
	if exist "..\Stats\*_PowerUsage.txt" del "..\Stats\*_PowerUsage.txt"
	ECHO Success. You need to measure the power consumption for all required miners ^& algorithms to continue using NemosMiner. 
	PAUSE
)
