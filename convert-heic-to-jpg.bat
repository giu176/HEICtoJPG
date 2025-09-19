@echo off
setlocal EnableExtensions EnableDelayedExpansion

if /i "%~1"=="_worker" (
    shift
    call :Worker "%~1" "%~2" "%~3" "%~4"
    exit /b %errorlevel%
)

if "%~1"=="" (
    echo Usage: %~nx0 SOURCE_DIR
    echo.
    echo Creates a "_jpg" copy of SOURCE_DIR and converts all HEIC files to JPG in parallel.
    exit /b 1
)

set "SOURCE=%~f1"
if not exist "%SOURCE%" (
    echo [ERROR] Source directory "%SOURCE%" not found.
    exit /b 1
)

for %%I in ("%SOURCE%") do set "DEST=%%~fI_jpg"

if /i "%SOURCE%"=="%DEST%" (
    echo [ERROR] Source directory already ends with _jpg.
    exit /b 1
)

echo [INFO] Copying directory tree to "%DEST%"...
robocopy "%SOURCE%" "%DEST%" /MIR /NFL /NDL /NJH /NJS /NC /NS >nul
if errorlevel 8 (
    echo [ERROR] robocopy failed to mirror the directory.
    exit /b 1
)

set "CONVERTER=magick"
set "MAX_JOBS=%NUMBER_OF_PROCESSORS%"
if defined HEIC2JPG_MAX_JOBS set "MAX_JOBS=%HEIC2JPG_MAX_JOBS%"
if not defined MAX_JOBS set "MAX_JOBS=1"
for /f "delims=" %%J in ("%MAX_JOBS%") do set "MAX_JOBS=%%~J"
set /a MAX_JOBS+=0 >nul 2>&1
if %MAX_JOBS% LSS 1 set "MAX_JOBS=1"

where /q "%CONVERTER%"
if errorlevel 1 (
    echo [ERROR] Converter "%CONVERTER%" not found in PATH.
    exit /b 1
)

echo [INFO] Using %MAX_JOBS% parallel conversion job(s).

set "LOCKDIR=%TEMP%\heic2jpg_%RANDOM%%RANDOM%"
if exist "%LOCKDIR%" rd /s /q "%LOCKDIR%" >nul 2>&1
md "%LOCKDIR%" 2>nul
if errorlevel 1 (
    echo [ERROR] Unable to create temporary directory "%LOCKDIR%".
    exit /b 1
)
set "FAILFLAG=%LOCKDIR%\fail.flag"
set "JOB_SEQ=0"
set "HAS_FILES=0"

for /r "%DEST%" %%F in (*.HEIC) do (
    set "CURRENT_FILE=%%~fF"
    set "HAS_FILES=1"
    call :WaitForSlot "%LOCKDIR%" %MAX_JOBS%
    set /a JOB_SEQ+=1
    set "LOCKFILE=%LOCKDIR%\job!JOB_SEQ!.lock"
    type nul >"!LOCKFILE!"
    start "" /b cmd /c ""%~f0" _worker "!CONVERTER!" "!CURRENT_FILE!" "!LOCKFILE!" "%FAILFLAG%""
)

call :WaitForAll "%LOCKDIR%"

set "EXITCODE=0"
if exist "%FAILFLAG%" set "EXITCODE=1"

rd /s /q "%LOCKDIR%" >nul 2>&1

if "!HAS_FILES!"=="0" (
    echo [INFO] No HEIC files found in destination directory.
) else (
    if %EXITCODE% neq 0 (
        echo [ERROR] Conversion completed with errors. Check messages above.
    ) else (
        echo [INFO] Conversion completed successfully.
    )
)

exit /b %EXITCODE%

:Worker
setlocal EnableExtensions EnableDelayedExpansion
set "CONVERTER=%~1"
set "SOURCE_FILE=%~2"
set "LOCKFILE=%~3"
set "FAILFLAG=%~4"
set "TARGET_FILE=%~dpn2.jpg"

if not exist "%SOURCE_FILE%" (
    echo [WARN] Source file "%SOURCE_FILE%" not found by worker.
    if exist "%LOCKFILE%" del "%LOCKFILE%" >nul 2>&1
    exit /b 0
)

if exist "%TARGET_FILE%" (
    echo [INFO] Skipping "%SOURCE_FILE%" because "%TARGET_FILE%" already exists.
    del "%SOURCE_FILE%" >nul 2>&1
    if exist "%LOCKFILE%" del "%LOCKFILE%" >nul 2>&1
    exit /b 0
)

"%CONVERTER%" "%SOURCE_FILE%" "%TARGET_FILE%"
set "RESULT=%ERRORLEVEL%"
if %RESULT% neq 0 (
    echo [ERROR] Conversion failed for "%SOURCE_FILE%". Exit code: %RESULT%
    if not exist "%FAILFLAG%" (echo failure>"%FAILFLAG%")
) else (
    del "%SOURCE_FILE%" >nul 2>&1
)

if exist "%LOCKFILE%" del "%LOCKFILE%" >nul 2>&1

endlocal
exit /b %RESULT%

:WaitForSlot
set "LOCKDIR=%~1"
set "MAX=%~2"
:WaitForSlotLoop
call :CountLocks "%LOCKDIR%" CURRENT_JOBS
if !CURRENT_JOBS! GEQ !MAX! (
    timeout /t 1 /nobreak >nul
    goto :WaitForSlotLoop
)
exit /b 0

:WaitForAll
set "LOCKDIR=%~1"
:WaitForAllLoop
call :CountLocks "%LOCKDIR%" REMAINING_JOBS
if !REMAINING_JOBS! GTR 0 (
    timeout /t 1 /nobreak >nul
    goto :WaitForAllLoop
)
exit /b 0

:CountLocks
set "LOCKDIR=%~1"
set /a COUNT=0
if exist "%LOCKDIR%\*.lock" (
    for %%L in ("%LOCKDIR%\*.lock") do (
        if exist "%%~fL" set /a COUNT+=1
    )
)
set "%~2=%COUNT%"
exit /b 0
