REM This file will run for skein2 algo
REM This file and nvidia inspector is disabled by default to Enable them, rename this file from skein2-example.bat to skein2.bat
REM Below is a example for a 6 GPU setup

SET PL=61
SET MEMORY=-750
SET CORE=50
SET TEMP=90

SET GPU0=-setBaseClockOffset:0,0,%CORE% -setMemoryClockOffset:0,0,%MEMORY% -setPowerTarget:0,%PL% -setTempTarget:0,0,%TEMP%

nvidiaInspector.exe %GPU0%
