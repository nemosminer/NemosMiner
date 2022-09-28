rem @echo off
taskkill /IM HWiNFO64.EXE /T > nul
ping localhost -n 5 > nul
taskkill /IM HWiNFO64.EXE /T > nul
start "" "C:\Program Files\Tools\HWiNFO64.EXE"
rem "C:\Program Files\Tools\MSI Afterburner\MSIAfterburner.exe" -profile1
exit