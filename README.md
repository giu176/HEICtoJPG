# HEIC to JPG Converter

This repository provides a Windows batch script that mirrors a directory tree and converts every `.HEIC` image it finds into `.jpg` using [ImageMagick](https://imagemagick.org/). The script is designed to run the conversions in parallel so large collections of HEIC files can be processed quickly.

## Prerequisites

- Windows 10 or later with the **Command Prompt**.
- [ImageMagick](https://imagemagick.org/script/download.php) installed and the `magick` executable available on your `PATH`.
- Optional: set the environment variable `HEIC2JPG_MAX_JOBS` to limit the maximum number of concurrent conversion jobs. If the variable is not set, the script uses the number of logical processors on the machine.

## Usage

```batch
convert-heic-to-jpg.bat "C:\path\to\source"
```

The script performs the following steps:

1. Validates the source directory.
2. Creates a mirror of the directory named `<source>_jpg` using `robocopy`.
3. Finds each `.HEIC` file within the mirrored directory and starts a background worker to convert the file to `.jpg`.
4. Removes the original `.HEIC` file after a successful conversion. If the `.jpg` already exists it skips conversion and deletes the duplicate `.HEIC` copy.

All worker processes share a lightweight lock directory to ensure no more than the configured number of jobs run concurrently. If any conversion fails the script reports an error once all background jobs finish.

## Tips

- Run the script from an elevated prompt if the destination directory requires additional permissions.
- If you want to preserve the original HEIC files, remove the line that deletes `"%SOURCE_FILE%"` after the conversion in the `:Worker` label before running the script.
- The `_jpg` directory can safely be deleted and recreated if you need to run the conversion again.

## Troubleshooting

- **`Converter "magick" not found in PATH`** – confirm ImageMagick is installed and the folder containing `magick.exe` is included in the `PATH` environment variable.
- **`robocopy` errors** – the script relies on `robocopy` mirroring the tree. Check the exit code in the console output for additional details and ensure the destination directory is not open in another program.
- **No HEIC files found** – the script will still create the `_jpg` directory. Verify that the source path points to a directory that contains HEIC files.

