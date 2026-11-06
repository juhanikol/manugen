@echo off
rem Opens MANUgen as an application window. If the application does not answer yet, this first starts
rem ticket-demo.cmd in its own minimized console window (closing that window stops MANUgen and the servers it
rem started) and waits until the application answers. A second start only opens a new window.
rem Browser: Microsoft Edge, else Google Chrome (both with --app), else the default browser.
setlocal DisableDelayedExpansion
set "CURL=%SystemRoot%\System32\curl.exe"
set "PORT=3000"
rem application.listen.port: the only "port" line with a 6-space indent in the delivered settings.json
for /f "tokens=2 delims=:, " %%p in ('findstr /r /c:"^      \"port\": [0-9]" "%~dp0settings.json" 2^>nul') do set "PORT=%%p"
set "URL=http://127.0.0.1:%PORT%/"

"%CURL%" -s -o nul -m 3 "%URL%" && goto open
echo MANUgen kaynnistyy. Tama voi kestaa noin minuutin, kun kielimalli latautuu muistiin.
echo Palvelin toimii tehtavapalkin pienennetyssa ikkunassa "MANUgen". Sen sulkeminen lopettaa MANUgenin.
start "MANUgen" /min "%SystemRoot%\System32\conhost.exe" "%~dp0ticket-demo.cmd"
set /a WAIT=0
:wait
ping -n 3 127.0.0.1 >nul
"%CURL%" -s -o nul -m 3 "%URL%" && goto open
set /a WAIT+=1
rem about 5 minutes; ticket-demo.cmd keeps its window open with the error when the start fails
if %WAIT% lss 100 goto wait
echo MANUgen ei vastannut osoitteessa %URL%. Avaa tehtavapalkin ikkuna "MANUgen": siina on syy.
pause
exit /b 1

:open
set "OPENED="
for %%b in (msedge.exe chrome.exe) do for %%h in (HKCU HKLM) do if not defined OPENED call :find %%h %%b
if defined OPENED exit /b 0
start "" "%URL%"
exit /b 0

rem :find HIVE EXE - opens the application window with the browser registered in App Paths; sets OPENED
:find
set "BROWSER="
for /f "tokens=2*" %%a in ('reg query "%1\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%2" /ve 2^>nul ^| findstr /c:"REG_SZ"') do set "BROWSER=%%~b"
if not defined BROWSER exit /b 0
if not exist "%BROWSER%" exit /b 0
start "" "%BROWSER%" --app=%URL%
set "OPENED=1"
exit /b 0
