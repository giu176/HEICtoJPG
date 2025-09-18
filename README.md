# HEICtoJPG

This repository provides a Windows batch script for converting directories full of
HEIC photos into JPG images while keeping the original folder structure intact.

## Batch script

The [`convert-heic-to-jpg.bat`](convert-heic-to-jpg.bat) script walks the source
folder recursively, mirrors the directory tree into the destination, and calls a
command-line converter for each `.heic` file it finds. By default it uses the
[`magick`](https://imagemagick.org/script/magick.php) command that ships with
ImageMagick 7, but you can supply another tool if you prefer (for example,
`heif-convert`).

```
convert-heic-to-jpg.bat SOURCE_DIR [DEST_DIR] [CONVERTER]
```

- **SOURCE_DIR** – Directory that contains the HEIC files you want to convert.
- **DEST_DIR** – Output root folder. If omitted, JPG files are written next to
  the source HEIC files.
- **CONVERTER** – Optional command or full path to the executable that should
  perform the conversion. Defaults to `magick`.

### Prerequisites

- Windows 10/11 with Command Prompt.
- A converter capable of reading HEIC files (ImageMagick, `heif-convert`, etc.)
  installed and available on `PATH`, or provide its full path as `CONVERTER`.

### Examples

Convert an entire photo archive in place:

```
convert-heic-to-jpg.bat "D:\Photos"
```

Mirror the converted JPGs into a separate folder using ImageMagick:

```
convert-heic-to-jpg.bat "D:\Photos\HEIC" "D:\Photos\JPG" magick
```

Use a custom converter executable:

```
convert-heic-to-jpg.bat "D:\Photos" "D:\Photos\JPG" "C:\Tools\heif-convert.exe"
```

The script skips files that already have a JPG counterpart in the destination.
If a conversion fails, the script reports the failure and continues processing
other files. The exit code will be non-zero if any conversion fails.
