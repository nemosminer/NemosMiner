@echo off
cd /d %~dp0
ECHO This process will remove all accumulated coin data and reset your profit statistics.
set /p statreset=Are you sure you want to continue? [Y/N] 
IF /I "%statreset%"=="Y" (
	if exist "..\Stats\*_Profit.txt" del "..\Stats\*_Profit.txt"
	ECHO Your pool stats have been successfully reset. 
	PAUSE
)
