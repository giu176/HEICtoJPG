@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="" (
    call :usage
    exit /b 1
)

set "SOURCE=%~1"
set "DESTINATION=%~2"
set "CONVERTER=%~3"

if not exist "%SOURCE%" (
    echo Source directory "%SOURCE%" was not found.
    exit /b 1
)

if not defined DESTINATION set "DESTINATION=%SOURCE%"
if not defined CONVERTER set "CONVERTER=magick"

for %%I in ("%SOURCE%") do set "SOURCE=%%~fI"
for %%I in ("%DESTINATION%") do set "DESTINATION=%%~fI"

if not "%SOURCE:~-1%"=="\" set "SOURCE=%SOURCE%\"
if not "%DESTINATION:~-1%"=="\" set "DESTINATION=%DESTINATION%\"

call :resolveConverter "%CONVERTER%" CONVERTER || exit /b 1

if not exist "%DESTINATION%" md "%DESTINATION%"

set "processed=0"
set "hadError=0"

for /r "%SOURCE%" %%F in (*.heic) do (
    set "inputFile=%%~fF"
    set "relativeDir=%%~dpF"
    set "relativeDir=!relativeDir:%SOURCE%=!"
    set "targetDir=%DESTINATION%!relativeDir!"
    if not exist "!targetDir!" md "!targetDir!"
    set "targetFile=!targetDir!%%~nF.jpg"
    if exist "!targetFile!" (
        echo Skipping "!targetFile!" (already exists)
    ) else (
        echo Converting: "%%~fF"
        "!CONVERTER!" "%%~fF" "!targetFile!"
        if errorlevel 1 (
            echo Failed to convert "%%~fF"
            set "hadError=1"
        ) else (
            echo   -^> "!targetFile!"
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

:resolveConverter
set "requested=%~1"
set "outputVar=%~2"
set "resolved="
if exist "%requested%" (
    set "resolved=%requested%"
) else (
    for %%I in ("%requested%") do set "resolved=%%~$PATH:I"
    if not defined resolved (
        where "%requested%" >nul 2>nul
        if not errorlevel 1 (
            set "resolved=%requested%"
        )
    )
)
if not defined resolved (
    echo Converter "%requested%" was not found. Install it or supply the full path as the third argument.
    exit /b 1
)
set "%outputVar%=%resolved%"
exit /b 0

:usage
echo Usage: %~nx0 SOURCE_DIR [DEST_DIR] [CONVERTER]
echo.
echo   SOURCE_DIR  Root folder containing HEIC images.
echo   DEST_DIR    Where to place converted JPG files. Defaults to SOURCE_DIR.
echo   CONVERTER   Optional command or full path used for conversion.
echo                Defaults to "magick" (ImageMagick 7).
echo.
echo Example:
"%~nx0" "C:\Photos\HEIC" "C:\Photos\JPG" magick
exit /b 0
