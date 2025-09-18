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

echo === Conversione .HEIC -> .jpg ===
echo Input : "%INROOT%"
echo Output: "%OUTROOT%"
echo.

rem Cerca ricorsivamente .HEIC (maiusc/minusc)
for /R "%INROOT%" %%F in (*.HEIC *.heic) do (
  rem Percorso sorgente completo: %%F
  rem Ottieni percorso+nome senza estensione
  set "SRCFULL=%%F"
  set "RELPN=%%~pnF"

  rem Calcola percorso relativo rimuovendo la radice input
  set "RELPN=!RELPN:%INROOT%=!"
  if "!RELPN:~0,1!"=="\" set "RELPN=!RELPN:~1!"

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
