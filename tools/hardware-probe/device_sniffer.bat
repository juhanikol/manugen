@echo off
setlocal DisableDelayedExpansion
rem Define the requested hardware fields here, once. No input INI. Option /nopause (used by tools\setup\MALLIN-ASENNUS.cmd).
rem Recommendation: the first matching profile of profiles.json, written to results\selection.cmd and results\downloads.txt.
set "CPU_FIELDS=Name,Architecture,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed"
set "SYSTEM_FIELDS=Manufacturer,Model,TotalPhysicalMemory"
set "OS_FIELDS=Caption,OSArchitecture,TotalVisibleMemorySize,FreePhysicalMemory"
set "RAM_FIELDS=Capacity,SMBIOSMemoryType,Speed,ConfiguredClockSpeed"
set "GPU_FIELDS=Name,PNPDeviceID,DriverVersion,AdapterRAM,ConfigManagerErrorCode"
set "PCI_FIELDS=DEVPKEY_PciDevice_CurrentLinkSpeed,DEVPKEY_PciDevice_CurrentLinkWidth,DEVPKEY_PciDevice_MaxLinkSpeed,DEVPKEY_PciDevice_MaxLinkWidth"
set "OUTPUT_DIR=%~dp0results"
set "CATALOG_FILE=%~dp0profiles.json"

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
>"%OUTPUT_DIR%\hardware.ini" echo STATUS=collecting
del "%OUTPUT_DIR%\selection.cmd" "%OUTPUT_DIR%\downloads.txt" 2>nul
>"%OUTPUT_DIR%\report.txt" echo Laitetietojen tunnistus ei valmistunut. Tarkista errors.txt.
pnputil /enum-devices /connected >"%OUTPUT_DIR%\devices-connected.txt" 2>&1
set "CONNECTED_RC=%ERRORLEVEL%"
pnputil /enum-devices /disconnected >"%OUTPUT_DIR%\devices-disconnected.txt" 2>&1
set "DISCONNECTED_RC=%ERRORLEVEL%"
cscript //nologo "%~dp0hardware-query.js" >"%OUTPUT_DIR%\errors.txt" 2>&1
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" type "%OUTPUT_DIR%\errors.txt"
type "%OUTPUT_DIR%\report.txt"
echo.
echo Tiedostot: "%OUTPUT_DIR%"
if /i not "%~1"=="/nopause" pause
exit /b %RESULT%
