@echo off
rem Selects the model server and workflow in settings.json:
rem   settings_change.cmd SERVER WORKFLOW [SETTINGS_FILE]
rem Rewrites exactly three lines of the application section (4-space indent, ending with a comma):
rem   "modelServer": "start",   "server": "SERVER",   "workflow": "WORKFLOW",
rem Every other line is copied unchanged. SERVER must be an "id" in the file. Nothing is changed if a
rem check fails. The previous file is kept as settings.json.bak.
rem No delayed expansion: lines with ! ^ & < > are copied as they are.
setlocal DisableDelayedExpansion
set "SERVER=%~1"
set "WORKFLOW=%~2"
set "FILE=%~3"
if not defined FILE set "FILE=%~dp0..\..\settings.json"
set "TMPFILE=%FILE%.tmp"

if not defined SERVER goto usage
if not defined WORKFLOW goto usage
call :name "%SERVER%" || goto fail
call :name "%WORKFLOW%" || goto fail
if not exist "%FILE%" (echo Asetustiedostoa ei loydy: "%FILE%"& goto fail)
findstr /r /c:"\"id\": *\"%SERVER%\"" "%FILE%" >nul || (echo Palvelinta "%SERVER%" ei ole tiedostossa "%FILE%".& goto fail)

call :line modelServer || goto fail
set "L_MODEL=%LINE%"
call :line server || goto fail
set "L_SERVER=%LINE%"
call :line workflow || goto fail
set "L_WORKFLOW=%LINE%"

rem findstr /n numbers every line ("N:text"); tokens=1* keeps the text after the first colon, empty lines too.
(for /f "tokens=1* delims=:" %%a in ('findstr /n "^" "%FILE%"') do (
  if "%%a"=="%L_MODEL%" (echo     "modelServer": "start",
  ) else if "%%a"=="%L_SERVER%" (echo     "server": "%SERVER%",
  ) else if "%%a"=="%L_WORKFLOW%" (echo     "workflow": "%WORKFLOW%",
  ) else echo(%%b
)) >"%TMPFILE%" || goto fail

copy /y "%FILE%" "%FILE%.bak" >nul || goto fail
move /y "%TMPFILE%" "%FILE%" >nul || goto fail
echo settings.json: modelServer "start", server "%SERVER%", workflow "%WORKFLOW%". Edellinen: "%FILE%.bak"
exit /b 0

rem Sets LINE to the number of the only line starting '    "KEY": ' and containing a comma (application section, 4 spaces).
:line
set "LINE="
set "COUNT=0"
for /f "delims=:" %%n in ('findstr /n /r /c:"^    \"%1\": .*," "%FILE%"') do (set "LINE=%%n"& set /a COUNT+=1)
if "%COUNT%"=="1" exit /b 0
echo Rivia '    "%1": "...",' ei loydy tasan kerran tiedostosta "%FILE%" (loytyi %COUNT%). Mitaan ei muutettu.
exit /b 1

rem Allows only letters, digits, dot, underscore and hyphen.
:name
for /f "delims=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-" %%x in ("%~1") do (
  echo Virheellinen nimi "%~1": sallitut merkit ovat kirjaimet, numerot seka . _ -
  exit /b 1
)
exit /b 0

:usage
echo Kaytto: settings_change.cmd PALVELIN TYONKULKU [ASETUSTIEDOSTO]
:fail
if exist "%TMPFILE%" del "%TMPFILE%"
exit /b 1
