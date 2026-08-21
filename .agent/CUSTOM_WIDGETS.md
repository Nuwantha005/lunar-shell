# Custom Widgets Design (Phase 6)

## Overview

Custom QML panels and widgets to be added to lunar-shell.
Phases 1-4 (including theme engine, dynamic color persistence, pywalfox bridge, and lock screen system) are complete and stable. These widgets are planned for Phase 6.

## Widget 1: Screenshot Tools Panel

**Trigger**: After a screenshot is taken, OR via a dedicated keybind / launcher button.

**Location**: `lunar-shell/modules/utilities/ScreenshotTools.qml`

### Features

#### Text OCR
- Input: screenshot or region image
- Tool: `tesseract-ocr` (must be installed)
- Output: extracted text → copy to clipboard via `wl-copy`
- Command: `tesseract <image> stdout | wl-copy`

#### LaTeX OCR
- Input: screenshot of math equation
- Tool: `pix2tex` or `latex-ocr` (pip package)
- Output: LaTeX string → copy to clipboard
- Command: `pix2tex <image> | wl-copy`
- Requires: `pip install pix2tex` or AUR package

#### QR Code Decode
- Input: screenshot or image containing QR
- Tool: `zbar` (`zbarimg`)
- Output: decoded URL/text → copy to clipboard, optionally open URL
- Command: `zbarimg --raw <image> | wl-copy`

### QML Design

```
ScreenshotTools panel:
  ┌─────────────────────────┐
  │  🔍 Screenshot Tools    │
  ├─────────────────────────┤
  │  [OCR Text]             │  ← button, runs tesseract
  │  [LaTeX OCR]            │  ← button, runs pix2tex
  │  [Decode QR]            │  ← button, runs zbarimg
  └─────────────────────────┘
  Result shown below buttons, with copy button
```

## Widget 2: Image Background Remover

**Location**: `lunar-shell/modules/utilities/BgRemover.qml`

### Features
- File picker → select image
- Runs: `rembg i <input> <output>` (`pip install rembg`)
- Shows before/after preview side by side
- Save to `~/Pictures/BgRemoved/` with `_nobg.png` suffix
- Progress indicator while processing

## Widget 3: marker-pdf Runner

**Location**: `lunar-shell/modules/utilities/PdfMarker.qml`

### Features
- File picker → select PDF
- Output directory selector (default: `~/Documents/marked/`)
- Runs: `marker <pdf_path> --output_dir <dir>`
- Progress/spinner during processing
- "Open folder" button when done

## Widget 4: Custom Scripts Launcher Integration

**Location**: Modify `lunar-shell/modules/launcher/` (the existing app launcher)

### Design
- Add a "Scripts" category to the existing launcher
- Reads scripts from `~/dotfiles/customScripts/`
- Each script entry shows:
  - Filename (without extension) as title
  - First line comment as description (if it's `# Description: ...`)
  - Default terminal icon
- Clicking a script: run in ghostty terminal OR background depending on flag

### Script Discovery
```qml
FileSystemModel {
    path: Paths.home + "/dotfiles/customScripts"
    filter: FileSystemModel.Files
}
```

Filter to executable files only. Parse first-line comments for metadata.

### Script Metadata Format (optional convention)
```bash
#!/bin/bash
# Name: My Script
# Description: Does something useful
# Terminal: true   (run in terminal window, default true)
# Icon: script     (icon name, optional)
```

## Removing Unused Panels

### How to disable without deleting

In `lunar-shell/shell.qml`, wrap module loads with config checks:

```qml
// Currently:
Recorder {}

// Modified to:
Loader {
    active: GlobalConfig.features?.screenRecorder ?? true
    sourceComponent: Recorder {}
}
```

Add to user config (`~/.config/caelestia/config.json`):
```json
{
  "features": {
    "screenRecorder": false
  }
}
```

This approach:
- Keeps code intact (easier upstream merging)
- Lets you disable at runtime via config
- Easy to re-enable by changing config value

### Panels to Consider Removing
- Screen recorder panel (if not used)
- Any other panels identified during usage

Identify them by reading `shell.qml` and `modules/` directory.

## Future Ideas (Not yet planned)
- add auto paste to QML Clipboard viewer
- add image preview support for QML clipboard viewer
- add battery max charge limiter with valuess [60%, 80%, 100%] using ~/dotfiles/customScripts/batter_toggle.sh` to the bottom of the battery status QML widget.
- add a quick audio output / input switcher form speakers to BT: one that actually works for all sources.

