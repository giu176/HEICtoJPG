@@ -39,52 +39,68 @@ for /r "%SOURCE%" %%F in (*.heic) do (
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
    goto :resolvedDone
)

for %%I in ("%requested%") do set "resolved=%%~$PATH:I"
if defined resolved goto :resolvedDone

where "%requested%" >nul 2>nul
if errorlevel 1 goto :missingConverter

for /f "delims=" %%I in ('where "%requested%" 2^>nul') do (
    set "resolved=%%I"
    goto :resolvedDone
)

set "resolved=%requested%"

:resolvedDone
if not defined resolved goto :missingConverter
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

"%~nx0" "C:\Photos\HEIC" "C:\Photos\JPG" magick

exit /b 0

