# HEICtoJPG

This repository provides a Windows batch script for converting directories full of
HEIC photos into JPG images while keeping the original folder structure intact.

## Batch script

The [`convert-heic-to-jpg.bat`](convert-heic-to-jpg.bat) script clones the source
folder, converts every `.HEIC` file within the clone to `.jpg` using the
[`magick`](https://imagemagick.org/script/magick.php) command, and removes the
intermediate HEIC files once each conversion completes. The conversion work is
parallelised based on the number of CPU cores that Windows reports.

```
convert-heic-to-jpg.bat SOURCE_DIR
```

- **SOURCE_DIR** – Directory that contains the HEIC files you want to convert.
  A sibling directory named `SOURCE_DIR_jpg` is created automatically to host
  the converted images.

### Behaviour

- The script mirrors the complete directory tree from `SOURCE_DIR` into the new
  `_jpg` directory using `robocopy`.
- Each HEIC file in the new directory is converted to JPG via `magick` and the
  HEIC copy is deleted immediately after a successful conversion to minimise
  disk usage.
- Multiple conversions run in parallel (one per logical CPU by default) to
  reduce the overall processing time. Set the `HEIC2JPG_MAX_JOBS` environment
  variable if you want to override the level of parallelism.
- If a conversion fails, the script keeps the `.HEIC` file in place, reports the
  error, and sets a non-zero exit code once all conversions finish.

### Prerequisites

- Windows 10/11 with Command Prompt.
- [ImageMagick](https://imagemagick.org/) installed and available on `PATH`
  (for the `magick` command).

### Example

Convert an entire photo archive, writing the resulting `*_jpg` directory next to
the original:

```
convert-heic-to-jpg.bat "D:\Photos\Holiday"
```

The script skips files that already have a JPG counterpart in the destination.
If a conversion fails, the script reports the failure and continues processing
other files. The exit code will be non-zero if any conversion fails.
