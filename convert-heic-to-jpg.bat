@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="" (
    call :usage
    exit /b 1
)

set "SOURCE=%~1"
set "DESTINATION=%~2"
set "REQUESTED_CONVERTER=%~3"

if not exist "%SOURCE%" (
    echo Source directory "%SOURCE%" was not found.
    exit /b 1
)

if not defined DESTINATION set "DESTINATION=%SOURCE%"
if not defined REQUESTED_CONVERTER set "REQUESTED_CONVERTER=magick"

for %%I in ("%SOURCE%") do set "SOURCE=%%~fI"
for %%I in ("%DESTINATION%") do set "DESTINATION=%%~fI"

if not "%SOURCE:~-1%"=="\" set "SOURCE=%SOURCE%\"
if not "%DESTINATION:~-1%"=="\" set "DESTINATION=%DESTINATION%\"

call :strlen "%SOURCE%" SOURCE_LEN

call :resolveConverter "%REQUESTED_CONVERTER%" CONVERTER || exit /b 1

if not exist "%DESTINATION%" md "%DESTINATION%"

set "processed=0"
set "hadError=0"

for /r "%SOURCE%" %%F in (*.heic) do (
    set "inputFile=%%~fF"
    set "relativeDir=%%~dpF"
    set "relativeDir=!relativeDir:~%SOURCE_LEN%!"
    set "targetDir=%DESTINATION%!relativeDir!"
    if not exist "!targetDir!" md "!targetDir!"
    set "targetFile=!targetDir!%%~nF.jpg"
    if exist "!targetFile!" (
        echo Skipping "!targetFile!" ^(already exists^)
    ) else (
        echo Converting: "%%~fF"
        "!CONVERTER!" "%%~fF" "!targetFile!"
        if errorlevel 1 (
            echo Failed to convert "%%~fF"
            set "hadError=1"
        ) else (
            echo   -> "!targetFile!"
            set /a processed+=1 >nul
        )
    )
)

if %processed%==0 (
    echo No HEIC files were found under "%SOURCE%".
) else (
    echo Converted %processed% file^(s^).
)

exit /b %hadError%

:strlen
setlocal EnableExtensions EnableDelayedExpansion
set "str=%~1"
set /a len=0
:strlen_loop
if defined str (
    set "str=!str:~1!"
    set /a len+=1
    goto :strlen_loop
)
endlocal & set "%~2=%len%"
exit /b 0

:resolveConverter
set "requested=%~1"
set "outputVar=%~2"
set "resolved="
if exist "%requested%" (
    set "resolved=%requested%"
    goto :resolvedDone
)
for %%I in ("%requested%") do if not "%%~$PATH:I"=="" (
    set "resolved=%%~$PATH:I"
    goto :resolvedDone
)
for /f "delims=" %%I in ('where "%requested%" 2^>nul') do (
    set "resolved=%%I"
    goto :resolvedDone
)
if not defined resolved goto :missingConverter
:resolvedDone
set "%outputVar%=%resolved%"
exit /b 0

:missingConverter
echo Converter "%requested%" was not found. Install it or supply the full path as the third argument.
exit /b 1

:usage
echo Usage: %~nx0 SOURCE_DIR [DEST_DIR] [CONVERTER]
echo.
echo   SOURCE_DIR  Root folder containing HEIC images.
echo   DEST_DIR    Where to place converted JPG files. Defaults to SOURCE_DIR.
echo   CONVERTER   Optional command or full path used for conversion.
echo                Defaults to "magick" (ImageMagick 7).
echo.
echo Example:
echo "%~nx0" "C:\Photos\HEIC" "C:\Photos\JPG" magick
exit /b 0
