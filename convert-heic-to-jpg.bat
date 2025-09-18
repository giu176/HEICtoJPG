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

rem Precalcola varianti utili del percorso di input
set "INROOT_UP=%INROOT%"
call :ToUpper INROOT_UP
call :StrLen INLEN "%INROOT%"

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
  rem Percorso sorgente completo: %%F
  rem Ottieni percorso+nome senza estensione
  set "SRCFULL=%%~pnF"
  set "SRCFULL_UP=!SRCFULL!"
  call :ToUpper SRCFULL_UP

  rem Calcola percorso relativo rimuovendo la radice input (ignorando il case)
  set "RELPN=!SRCFULL!"
  if "!SRCFULL_UP:~0,%INLEN%!"=="%INROOT_UP%" set "RELPN=!SRCFULL:~%INLEN%!"
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
exit /b

:ToUpper
setlocal EnableDelayedExpansion
set "_VAL=!%~1!"
for %%A in (a=A b=B c=C d=D e=E f=F g=G h=H i=I j=J k=K l=L m=M n=N o=O p=P q=Q r=R s=S t=T u=U v=V w=W x=X y=Y z=Z) do (
  for /F "tokens=1,2 delims==" %%B in ("%%A") do set "_VAL=!_VAL:%%B=%%C!"
)
endlocal & set "%~1=%_VAL%"
exit /b

:StrLen
setlocal EnableDelayedExpansion
set "_STR=%~2"
set /A _LEN=0
:len_loop
if defined _STR (
  set "_STR=!_STR:~1!"
  set /A _LEN+=1
  goto len_loop
)
endlocal & set "%~1=%_LEN%"
exit /b
