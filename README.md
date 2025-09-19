# HEICtoJPG

This repository provides a Windows batch script for converting directories full of
HEIC photos into JPG images while keeping the original folder structure intact.

## Batch script

The [`convert-heic-to-jpg.bat`](convert-heic-to-jpg.bat) script duplicates the
source folder next to itself with the `_jpg` suffix, mirrors its directory tree,
and then converts every `.heic` file inside the copy to `.jpg` using a
command-line converter. Each conversion runs in its own background job so that
multiple photos are processed in parallel, and every HEIC file is deleted from
the copy as soon as its JPG counterpart has been created.

```
convert-heic-to-jpg.bat SOURCE_DIR [CONVERTER] [MAX_PARALLEL_JOBS]
```

- **SOURCE_DIR** – Path to the HEIC folder you want to clone and convert.
- **CONVERTER** – Optional command or full path to the executable that performs
  the conversion. Defaults to `magick`.
- **MAX_PARALLEL_JOBS** – Optional number of concurrent conversions. If omitted,
  the script uses the number of logical processors reported by Windows.

### Workflow

1. The script creates `<SOURCE_DIR>_jpg` alongside the original folder and
   mirrors the complete directory structure (including non-HEIC assets) using
   `robocopy`.
2. Every `.HEIC` file inside the new tree is converted with `magick` (or the
   converter you provide) into a `.jpg` file with the same base name.
3. Converted HEIC files are deleted immediately so that the new folder only
   retains the JPG files and any non-HEIC resources. The original folder remains
   untouched throughout the process.

If any conversion fails, the script reports the error, continues processing the
remaining files, and exits with a non-zero status code.

### Prerequisites

- Windows 10/11 with Command Prompt and PowerShell.
- A converter capable of reading HEIC files (ImageMagick, `heif-convert`, etc.)
  installed and available on `PATH`, or provide its full path as `CONVERTER`.

### Examples

Convert an entire photo archive using defaults:

```
convert-heic-to-jpg.bat "D:\Photos\Holiday"
```

Use a custom converter executable and limit concurrency to four jobs:

```
convert-heic-to-jpg.bat "D:\Photos\iPhone" "C:\Tools\magick.exe" 4
```
