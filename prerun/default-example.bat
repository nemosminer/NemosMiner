SET PL=65
SET MEMORY=350
SET CORE=25
SET TEMP=90
SET FAN=75

SET GPU0=-setBaseClockOffset:0,0,%CORE% -setMemoryClockOffset:0,0,%MEMORY% -setPowerTarget:0,%PL% -setTempTarget:0,0,%TEMP% -setFanSpeed:0,%FAN%
SET GPU1=-setBaseClockOffset:1,0,%CORE% -setMemoryClockOffset:1,0,%MEMORY% -setPowerTarget:1,%PL% -setTempTarget:1,0,%TEMP% -setFanSpeed:1,%FAN%
SET GPU2=-setBaseClockOffset:2,0,%CORE% -setMemoryClockOffset:2,0,%MEMORY% -setPowerTarget:2,%PL% -setTempTarget:2,0,%TEMP% -setFanSpeed:2,%FAN%
SET GPU3=-setBaseClockOffset:3,0,%CORE% -setMemoryClockOffset:3,0,%MEMORY% -setPowerTarget:3,%PL% -setTempTarget:3,0,%TEMP% -setFanSpeed:3,%FAN%
SET GPU4=-setBaseClockOffset:4,0,%CORE% -setMemoryClockOffset:4,0,%MEMORY% -setPowerTarget:4,%PL% -setTempTarget:4,0,%TEMP% -setFanSpeed:4,%FAN%
SET GPU5=-setBaseClockOffset:5,0,%CORE% -setMemoryClockOffset:5,0,%MEMORY% -setPowerTarget:5,%PL% -setTempTarget:5,0,%TEMP% -setFanSpeed:5,%FAN%

nvidiaInspector.exe %GPU0% %GPU1% %GPU2% %GPU3% %GPU4% %GPU5%