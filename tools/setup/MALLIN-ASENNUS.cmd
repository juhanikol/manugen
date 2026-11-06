@echo off
rem Model setup: device_sniffer recommends a profile of tools\hardware-probe\profiles.json; this file downloads its
rem llama.cpp release (curl.exe), extracts it to runtime\llama (tar.exe), downloads the models to models\, finds the
rem GPU device name (llama-server --list-devices) and selects the matching server in settings.json (settings_change.cmd).
rem Only Windows tools are used. Downloaded files stay in downloads\ and models\; a repeated run skips them.
setlocal DisableDelayedExpansion
cd /d "%~dp0..\.."
set "ROOT=%CD%"
set "PROBE=%ROOT%\tools\hardware-probe"
set "LLAMA=%ROOT%\runtime\llama"
set "DL=%ROOT%\downloads"
set "CURL=%SystemRoot%\System32\curl.exe"
set "TAR=%SystemRoot%\System32\tar.exe"
set "FINDSTR=%SystemRoot%\System32\findstr.exe"
set "VCURL=https://aka.ms/vc14/vc_redist.x64.exe"

echo MANUgen: kielimallin asennus
echo Sulje MANUgen ennen jatkamista. Mallitiedostot ovat suuria (1-5 Gt): lataus voi kestaa kauan.
echo.
echo [1/6] Laitetunnistus
call "%PROBE%\device_sniffer.bat" /nopause
if not exist "%PROBE%\results\selection.cmd" (echo Laitetunnistus ei valmistunut. Katso "%PROBE%\results\errors.txt".& goto fail)
call "%PROBE%\results\selection.cmd"
if not defined PROFILE (echo Tahan koneeseen ei loydy sopivaa mallia. Ota yhteytta toimittajaan ja liita mukaan "%PROBE%\results\report.txt".& goto fail)
echo.
echo Suositus: %LABEL%
if defined GPU_NAME echo Naytonohjain: %GPU_NAME%
echo Tyonkulku: %WORKFLOW%
echo Ladattavat tiedostot:
type "%PROBE%\results\downloads.txt"
echo.
choice /c KE /m "Asennetaanko tama malli (K = kylla, E = ei)"
if errorlevel 2 goto cancel

echo.
echo [2/6] Microsoft Visual C++ -ajonaikainen kirjasto
:vc
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Installed /reg:64 2>nul | "%FINDSTR%" /r /c:"Installed  *REG_DWORD  *0x1" >nul && goto vcok
echo Kirjasto puuttuu. Selain avaa latauksen: suorita VC_redist.x64.exe (vaatii jarjestelmanvalvojan oikeudet).
start "" "%VCURL%"
choice /c JL /m "Kun asennus on valmis, valitse J = tarkista uudelleen, L = lopeta"
if errorlevel 2 goto cancel
goto vc
:vcok
echo Asennettu.

echo.
echo [3/6] Lataukset
if not exist "%DL%" mkdir "%DL%" || goto fail
if not exist "%ROOT%\models" mkdir "%ROOT%\models" || goto fail
for /f "usebackq tokens=1,2" %%a in ("%PROBE%\results\downloads.txt") do call :get %%a "%%b" || goto fail

echo.
echo [4/6] llama.cpp: puretaan kansioon "%LLAMA%"
if exist "%LLAMA%" rd /s /q "%LLAMA%"
if exist "%LLAMA%" (echo Kansiota ei voi korvata: sulje MANUgen ja llama-server ja aja tama uudelleen.& goto fail)
mkdir "%LLAMA%" || goto fail
for /f "usebackq tokens=1,2" %%a in ("%PROBE%\results\downloads.txt") do if "%%a"=="runtime" call :unzip "%%b" || goto fail
if not exist "%LLAMA%\llama-server.exe" (echo Purettu paketti ei sisalla tiedostoa llama-server.exe.& goto fail)

echo.
echo [5/6] Laite
set "SERVER=%PROFILE%"
if "%BACKEND%"=="cpu" (echo Ajo prosessorilla, naytonohjainta ei kayteta.& goto apply)
set "DEVICE="
for /f "tokens=1 delims=: " %%d in ('call "%LLAMA%\llama-server.exe" --list-devices 2^>^&1 ^| "%FINDSTR%" /l /c:": %GPU_NAME% ("') do set "DEVICE=%%d"
if defined DEVICE goto device
echo llama-server ei nayttanyt laitetta "%GPU_NAME%". Laitteet:
call "%LLAMA%\llama-server.exe" --list-devices
echo Jos lista on tyhja, paivita naytonohjaimen ajuri (LUEMINUT.txt) ja aja tama uudelleen.
set /p "DEVICE=Kirjoita laitteen nimi kaksoispisteen vasemmalta puolelta (esim. Vulkan1), tai paina Enter lopettaaksesi: "
if not defined DEVICE goto cancel
:device
echo Laite: %DEVICE%
set "DEVICE_ID=%DEVICE%"
for %%L in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do call set "DEVICE_ID=%%DEVICE_ID:%%L=%%L%%"
set "SERVER=%PROFILE%-%DEVICE_ID%"

:apply
echo.
echo [6/6] settings.json: palvelin %SERVER%, tyonkulku %WORKFLOW%
"%FINDSTR%" /r /c:"\"id\": *\"%SERVER%\"" "%ROOT%\settings.json" >nul && goto change
echo settings.json ei sisalla palvelinta "%SERVER%" (esimerkiksi aiemman version asetukset).
if not exist "%~dp0settings.default.json" goto fail
choice /c KE /m "Korvataanko settings.json taman version oletusasetuksilla (nykyinen talteen nimella settings.json.bak) (K/E)"
if errorlevel 2 goto cancel
copy /y "%ROOT%\settings.json" "%ROOT%\settings.json.bak" >nul || goto fail
copy /y "%~dp0settings.default.json" "%ROOT%\settings.json" >nul || goto fail
:change
call "%~dp0settings_change.cmd" "%SERVER%" "%WORKFLOW%" "%ROOT%\settings.json" || goto fail
echo.
echo Valmis. Kaynnista MANUgen (Kaynnista-valikko, tyopoyta tai MANUgen.cmd). Ensimmainen kaynnistys lataa mallin muistiin.
pause
exit /b 0

rem :get KIND URL  - models go to models\, release zips to downloads\. An existing file is not loaded again.
:get
set "URL=%~2"
for %%f in ("%URL%") do set "NAME=%%~nxf"
set "DEST=%DL%\%NAME%"
if "%~1"=="model" set "DEST=%ROOT%\models\%NAME%"
if exist "%DEST%" (echo Jo ladattu: %NAME%& exit /b 0)
echo Ladataan %NAME%
"%CURL%" -L --fail --retry 3 -C - -o "%DEST%.part" "%URL%" || (echo Lataus epaonnistui: %URL%. Tarkista verkkoyhteys ja aja tama uudelleen, lataus jatkuu.& exit /b 1)
move /y "%DEST%.part" "%DEST%" >nul || exit /b 1
exit /b 0

:unzip
for %%f in ("%~1") do set "NAME=%%~nxf"
echo Puretaan %NAME%
"%TAR%" -xf "%DL%\%NAME%" -C "%LLAMA%" || (echo Purku epaonnistui: "%DL%\%NAME%". Poista tiedosto ja aja tama uudelleen.& exit /b 1)
exit /b 0

:cancel
echo Keskeytetty. Mitaan ei muutettu settings.json-tiedostoon.
pause
exit /b 1
:fail
echo Asennus ei valmistunut.
pause
exit /b 1
