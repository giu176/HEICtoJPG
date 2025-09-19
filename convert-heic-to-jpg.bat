@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem === Controllo parametri ===
if "%~1"=="" (
  echo Uso: %~nx0 "C:\cartella\input" "C:\cartella\output"
  exit /b 1
)
if "%~2"=="" (
  echo Uso: %~nx0 "C:\cartella\input" "C:\cartella\output"
  exit /b 1
)

rem Normalizza percorsi con slash finale rimosso
set "INROOT=%~f1"
set "OUTROOT=%~f2"
if "%INROOT:~-1%"=="\" set "INROOT=%INROOT:~0,-1%"
if "%OUTROOT:~-1%"=="\" set "OUTROOT=%OUTROOT:~0,-1%"

rem Verifica esistenza input
if not exist "%INROOT%" (
  echo Errore: cartella input non trovata: "%INROOT%"
  exit /b 1
)

rem (Opzionale) verifica presenza comando magick
where /q magick
if errorlevel 1 (
  echo Errore: comando "magick" non trovato nel PATH. Installa ImageMagick o aggiungilo al PATH.
  exit /b 1
)

rem Assicurati che la cartella di output esista
if not exist "%OUTROOT%" mkdir "%OUTROOT%" >nul 2>&1

echo === Conversione .HEIC -> .jpg ===
echo Input : "%INROOT%"
echo Output: "%OUTROOT%"
echo.

rem Cerca ricorsivamente .HEIC (maiusc/minusc)
for /R "%INROOT%" %%F in (*.HEIC *.heic) do (
  rem Calcola il percorso relativo rispetto alla radice di input
  call :GetRelativePath "%%~pnF" "%INROOT%" RELPN

  rem Costruisci destinazione: OUTROOT + relativo + .jpg
  set "DESTFILE=%OUTROOT%\!RELPN!.jpg"

  rem Crea la cartella di destinazione se non esiste
  for %%D in ("!DESTFILE!") do set "DESTDIR=%%~dpD"
  if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1

  echo Converto: "%%F"
  rem Esegui la conversione
  magick "%%F" "!DESTFILE!" || (
    echo   ^> Errore nella conversione di "%%F"
  )
)

echo.
echo Fatto.
endlocal
exit /b

:GetRelativePath
setlocal EnableDelayedExpansion
set "SRC=%~1"
set "BASE=%~2"
set "ORIG=%~1"
if "!BASE:~-1!"=="\" set "BASE=!BASE:~0,-1!"
set "SRC_UP=%SRC%"
set "BASE_UP=%BASE%"
call :ToUpper SRC_UP
call :ToUpper BASE_UP
:rel_loop
if "!BASE_UP!"=="" goto rel_success
if "!SRC_UP!"=="" goto rel_fail
if not "!SRC_UP:~0,1!"=="!BASE_UP:~0,1!" goto rel_fail
set "SRC_UP=!SRC_UP:~1!"
set "BASE_UP=!BASE_UP:~1!"
set "SRC=!SRC:~1!"
goto rel_loop

:rel_success
if "!SRC:~0,1!"=="\" set "SRC=!SRC:~1!"
goto rel_finish

:rel_fail
for %%P in ("!ORIG!") do set "SRC=%%~nxP"
goto rel_finish

:rel_finish
endlocal & set "%~3=%SRC%"
exit /b

:ToUpper
setlocal EnableDelayedExpansion
set "_VAL=!%~1!"
for %%A in (a=A b=B c=C d=D e=E f=F g=G h=H i=I j=J k=K l=L m=M n=N o=O p=P q=Q r=R s=S t=T u=U v=V w=W x=X y=Y z=Z) do (
  for /F "tokens=1,2 delims==" %%B in ("%%A") do set "_VAL=!_VAL:%%B=%%C!"
)
endlocal & set "%~1=%_VAL%"
exit /b
