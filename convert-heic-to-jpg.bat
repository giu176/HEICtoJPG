@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 SOURCE_DIR [CONVERTER] [MAX_PARALLEL_JOBS]
    echo(
    echo   SOURCE_DIR          Directory containing HEIC images to convert.
    echo   CONVERTER           Optional converter executable. Defaults to "magick".
    echo   MAX_PARALLEL_JOBS   Optional maximum number of parallel conversions.
    exit /b 1
)

set "SRC=%~1"
if not exist "%SRC%" (
    echo [ERROR] Source directory "%SRC%" not found.
    exit /b 1
)

for %%I in ("%SRC%") do (
    set "SRC_FULL=%%~fI"
    set "SRC_NAME=%%~nxI"
    set "SRC_PARENT=%%~dpI"
)

set "DEST=%SRC_PARENT%%SRC_NAME%_jpg"
if exist "%DEST%" (
    echo [ERROR] Destination folder "%DEST%" already exists. Remove it or choose another source.
    exit /b 1
)

set "CONVERTER=%~2"
if not defined CONVERTER set "CONVERTER=magick"

for /f "delims=" %%P in ('where "%CONVERTER%" 2^>nul') do if not defined CONVERTER_PATH set "CONVERTER_PATH=%%~fP"
if not defined CONVERTER_PATH (
    echo [ERROR] Unable to find converter executable "%CONVERTER%". Ensure it is on PATH or supply a full path.
    exit /b 1
)

set "MAX_JOBS=%~3"
if not defined MAX_JOBS set "MAX_JOBS=%NUMBER_OF_PROCESSORS%"
for /f "tokens=*" %%J in ("%MAX_JOBS%") do set "MAX_JOBS=%%~J"
set /a MAX_JOBS=MAX_JOBS
if %MAX_JOBS% LEQ 0 set "MAX_JOBS=1"

mkdir "%DEST%" >nul 2>&1
robocopy "%SRC_FULL%" "%DEST%" /E /COPY:DATSO /DCOPY:DAT /R:2 /W:2 /NFL /NDL /NJH /NJS >nul
set "ROBOCOPY_RC=%ERRORLEVEL%"
if %ROBOCOPY_RC% GEQ 8 (
    echo [ERROR] Failed to copy source tree to destination (robocopy exit code %ROBOCOPY_RC%).
    exit /b %ROBOCOPY_RC%
)

set "TMP_PS=%TEMP%\convert_heic_%RANDOM%_%RANDOM%.ps1"
(
    echo param(^[string^]$DestRoot, ^[string^]$ConverterPath, ^[int^]$MaxJobs^)
    echo $ErrorActionPreference = 'Stop'
    echo $DestRoot = [System.IO.Path]::GetFullPath($DestRoot)
    echo if (-not (Test-Path -LiteralPath $DestRoot)) { Write-Error "Destination path not found: $DestRoot"; exit 1 }
    echo if ($MaxJobs -lt 1) { $MaxJobs = 1 }
    echo $heicFiles = @(Get-ChildItem -Path $DestRoot -Recurse -File ^| Where-Object { $_.Extension -ieq '.heic' })
    echo if ($heicFiles.Count -eq 0) { exit 0 }
    echo Write-Host ^"Converting $($heicFiles.Count) HEIC file(s) using up to $MaxJobs parallel jobs...^"
    echo $jobs = @(^)
    echo $failed = $false
    echo foreach ($file in $heicFiles) {
    echo ^    while ($jobs.Count -ge $MaxJobs) {
    echo ^        $completed = Wait-Job -Job $jobs -Any
    echo ^        if ($completed.State -eq 'Failed') { $failed = $true }
    echo ^        Receive-Job -Job $completed ^| Write-Host
    echo ^        $jobs = $jobs ^| Where-Object { $_.Id -ne $completed.Id -and $_.State -eq 'Running' }
    echo ^        Remove-Job -Job $completed ^| Out-Null
    echo ^    }
    echo ^    $jobs += Start-Job -ArgumentList $file.FullName, $ConverterPath -ScriptBlock {
    echo ^        param($filePath, $converterPath)
    echo ^        $jpgPath = [System.IO.Path]::ChangeExtension($filePath, '.jpg')
    echo ^        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    echo ^        $processInfo.FileName = $converterPath
    echo ^        $processInfo.Arguments = '"' + $filePath + '" "' + $jpgPath + '"'
    echo ^        $processInfo.UseShellExecute = $false
    echo ^        $processInfo.CreateNoWindow = $true
    echo ^        $process = [System.Diagnostics.Process]::Start($processInfo)
    echo ^        $process.WaitForExit(^)
    echo ^        if ($process.ExitCode -ne 0) {
    echo ^            throw "Conversion failed for $filePath (exit code $($process.ExitCode))"
    echo ^        }
    echo ^        Remove-Item -LiteralPath $filePath
    echo ^    }
    echo }
    echo foreach ($job in $jobs) {
    echo ^    Wait-Job -Job $job ^| Out-Null
    echo ^    if ($job.State -eq 'Failed') { $failed = $true }
    echo ^    Receive-Job -Job $job ^| Write-Host
    echo ^    Remove-Job -Job $job ^| Out-Null
    echo }
    echo if ($failed) { exit 1 } else { exit 0 }
) > "%TMP_PS%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS%" "%DEST%" "%CONVERTER_PATH%" %MAX_JOBS%
set "PS_EXIT=%ERRORLEVEL%"
del "%TMP_PS%" >nul 2>&1

if not %PS_EXIT%==0 (
    echo [ERROR] One or more conversions failed.
    exit /b %PS_EXIT%
)

echo [DONE] JPG files are available in "%DEST%".
exit /b 0
