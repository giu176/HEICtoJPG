@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 SOURCE_DIR [MAGICK_COMMAND] [MAX_JOBS]
    echo.
    echo   SOURCE_DIR      Directory that contains HEIC files to convert.
    echo   MAGICK_COMMAND  Optional command or path to ImageMagick's ^"magick^".
    echo   MAX_JOBS        Optional maximum number of parallel conversions.
    exit /b 1
)

set "SRC_DIR=%~1"
if not exist "%SRC_DIR%" (
    echo Source directory "%SRC_DIR%" does not exist.
    exit /b 1
)

for %%I in ("%SRC_DIR%") do (
    set "SRC_FULL=%%~fI"
    set "SRC_NAME=%%~nI"
    set "SRC_PARENT=%%~dpI"
)

set "DEST_DIR=%SRC_PARENT%%SRC_NAME%_jpg"
if exist "%DEST_DIR%" (
    echo Destination directory "%DEST_DIR%" already exists.
    exit /b 1
)

set "MAGICK_CMD=%~2"
if not defined MAGICK_CMD (
    if defined HEIC2JPG_MAGICK (
        set "MAGICK_CMD=%HEIC2JPG_MAGICK%"
    ) else (
        set "MAGICK_CMD=magick"
    )
)

set "MAX_JOBS=%~3"
if not defined MAX_JOBS (
    if defined HEIC2JPG_MAX_JOBS (
        set "MAX_JOBS=%HEIC2JPG_MAX_JOBS%"
    ) else (
        set "MAX_JOBS=0"
    )
)

echo Copying "%SRC_FULL%" to "%DEST_DIR%"...
robocopy "%SRC_FULL%" "%DEST_DIR%" /E /COPY:DAT /DCOPY:T /R:1 /W:1 >nul
set "ROBOCOPY_RC=%ERRORLEVEL%"
if %ROBOCOPY_RC% GEQ 8 (
    echo Failed to copy directory tree. ROBOCOPY exited with code %ROBOCOPY_RC%.
    exit /b %ROBOCOPY_RC%
)

echo Copy complete. Starting HEIC to JPG conversion...

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
    "& { param(^$dest,^$magick,^$maxJobs)^
        ^$ErrorActionPreference = 'Stop'^
        if (-not (Test-Path -LiteralPath ^$dest)) { Write-Error \"Destination directory not found: ^$dest\" }^
        ^$files = Get-ChildItem -LiteralPath ^$dest -Recurse -File | Where-Object { ^$_.Extension -ieq '.heic' }^
        if (^$files.Count -eq 0) { Write-Host 'No HEIC files found in destination.'; exit 0 }^
        if ([string]::IsNullOrWhiteSpace(^$magick)) { ^$magick = 'magick' }^
        try { ^$null = [int]::Parse(^$maxJobs) } catch { ^$maxJobs = 0 }^
        if ([int]^$maxJobs -lt 1) { ^$maxJobs = [System.Environment]::ProcessorCount }^
        Write-Host (\"Converting ^$([int]^$files.Count) HEIC file(s) using up to ^$maxJobs parallel job(s)...\")^
        ^$parallelOptions = New-Object System.Threading.Tasks.ParallelOptions^
        ^$parallelOptions.MaxDegreeOfParallelism = [int]^$maxJobs^
        ^$errors = New-Object System.Collections.Concurrent.ConcurrentBag[string]^
        [System.Threading.Tasks.Parallel]::ForEach(^$files,^$parallelOptions,{ param(^$file)
            try {
                ^$jpg = [System.IO.Path]::ChangeExtension(^$file.FullName,'.jpg')
                ^$psi = New-Object System.Diagnostics.ProcessStartInfo
                ^$psi.FileName = ^$magick
                ^$psi.Arguments = '"' + ^$file.FullName + '" "' + ^$jpg + '"'
                ^$psi.CreateNoWindow = ^$true
                ^$psi.UseShellExecute = ^$false
                ^$psi.RedirectStandardOutput = ^$true
                ^$psi.RedirectStandardError = ^$true
                ^$proc = [System.Diagnostics.Process]::Start(^$psi)
                ^$proc.WaitForExit()
                if (^$proc.ExitCode -ne 0) {
                    ^$stdErr = ^$proc.StandardError.ReadToEnd()
                    if ([string]::IsNullOrWhiteSpace(^$stdErr)) { ^$stdErr = ^$proc.StandardOutput.ReadToEnd() }
                    throw (\"magick exited with code ^$(^$proc.ExitCode). ^$stdErr\")
                }
                Remove-Item -LiteralPath ^$file.FullName -ErrorAction Stop
            } catch {
                ^$errors.Add(^$file.FullName + ': ' + ^$_.Exception.Message) | Out-Null
            }
        })
        if (^$errors.Count -gt 0) {
            Write-Host 'Some conversions failed:' -ForegroundColor Red
            ^$errors | ForEach-Object { Write-Host '  ' ^$_ -ForegroundColor Red }
            exit 1
        } else {
            Write-Host 'Conversion completed successfully.' -ForegroundColor Green
        }
    }" "%DEST_DIR%" "%MAGICK_CMD%" "%MAX_JOBS%"
set "PS_EXIT=%ERRORLEVEL%"

if not "%PS_EXIT%"=="0" (
    echo Conversion encountered errors.
    exit /b %PS_EXIT%
)

echo All HEIC files converted successfully.
exit /b 0
