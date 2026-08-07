# System Architecture

## How the Stack Works

```
User action (keybind / CLI)
        │
        ▼
lunar-cli (Python, /usr/local/bin/lunar or pip editable)
        │
        │ writes state files
        ▼
~/.local/state/caelestia/        ← STATE DIRECTORY (shared with AUR caelestia)
    ├── scheme.json              ← Active colour scheme (M3 palette JSON)
    ├── theme.json               ← Active lunar theme (NEW)
    ├── wallpaper/
    │   ├── path.txt             ← Current wallpaper path (watched by shell)
    │   ├── current → <path>     ← Symlink to wallpaper
    │   └── thumbnail.jpg        ← 128x128 thumbnail
    └── pfp.jpg                  ← Current profile picture (symlink)

        │
        │ FileView watches (QML)
        ▼
lunar-shell (QML via QuickShell)
    ├── services/
    │   ├── Colours.qml          ← Reads scheme.json, exposes M3 palette
    │   ├── Wallpapers.qml       ← Reads wallpaper/path.txt, manages picker
    │   ├── Theme.qml            ← (NEW) Reads theme.json, exposes theme state
    │   └── LockState.qml        ← (NEW) Reads lock backend from theme.json
    └── modules/
        ├── lock/
        │   ├── Lock.qml         ← WlSessionLock wrapper (MODIFIED)
        │   ├── LockSurface.qml  ← Default caelestia lock UI
        │   └── QylockSurface.qml← (NEW) Embeds Qylock themes
        ├── launcher/
        │   ├── CarouselList.qml ← (NEW) Quick interactive launcher slider for wallpapers, themes, pfps, lock screens
        │   ├── ContentList.qml  ← (MODIFIED) Routes autocomplete actions (>theme, >pfp, >lockscreen) to CarouselList
        │   └── AppList.qml      ← (MODIFIED) Resolves launcher commands to autocomplete suggestions
        └── nexus/pages/wallandstyle/
            ├── ThemeSelect.qml  ← Full settings panel theme selection grid
            └── WallpaperSelect.qml ← Scoped theme wallpaper selector grid
```

## Key Data Flow: Wallpaper → Colours

```
User picks wallpaper (or theme auto-picks)
    │
    ▼
lunar-cli: set_wallpaper(path)
    ├── Writes path to ~/.local/state/caelestia/wallpaper/path.txt
    ├── Generates thumbnail (128x128)
    ├── Reads current scheme (scheme.json)
    │   └── If scheme.name == "dynamic":
    │       ├── Run materialyoucolor on thumbnail
    │       ├── Get M3 palette
    │       └── Update scheme.json
    ├── apply_colours() → writes to all configured apps
    │   ├── apply_hypr() → ~/.config/hypr/scheme/current.lua
    │   ├── apply_gtk()  → gtk.css
    │   ├── apply_terms() → /dev/pts/* (terminal colours)
    │   └── funnel_to_pywalfox() → (NEW) ~/.cache/wal/colors.json + pywalfox update
    └── Updates theme.json selectedWallpaper field (NEW)

lunar-shell: Colours.qml (FileView watches scheme.json)
    └── Notified of change → reloads M3 palette → all QML rebinds
```

## Key Data Flow: Theme Switch

```
User picks theme "jinx" (via ThemePicker.qml or CLI)
    │
    ▼
lunar-cli: set_theme("jinx")
    ├── Load ~/Pictures/themes/jinx/theme.json
    ├── Pick wallpaper: theme.selectedWallpaper (or first in wallpapers/)
    ├── set_wallpaper(wall) → triggers full colour pipeline above
    ├── Apply lock settings: theme.lockBackend, theme.qylockTheme
    ├── Copy selected pfp → ~/.local/state/caelestia/pfp.jpg
    └── Save ~/.local/state/caelestia/theme.json

lunar-shell: Theme.qml (FileView watches theme.json)
    └── Notified → updates currentTheme, lockBackend, etc.
```

## State File: theme.json

Written to `~/.local/state/caelestia/theme.json`:

```json
{
  "name": "jinx",
  "path": "/home/nuwa/Pictures/themes/jinx",
  "scheme": "dynamic",
  "schemeFlavour": "default",
  "schemeMode": "dark",
  "schemeVariant": "tonalspot",
  "selectedWallpaper": "/home/nuwa/Pictures/themes/jinx/wallpapers/wall1.jpg",
  "selectedPfp": "/home/nuwa/Pictures/themes/jinx/pfp/pfp1.png",
  "lockBackend": "caelestia",
  "qylockTheme": null
}
```

## Python Package Layout (lunar-cli)

```
src/caelestia/                    ← package name kept as "caelestia" for compatibility
    __init__.py
    __main__.py
    parser.py                     ← MODIFIED: adds theme + lock subcommands
    subcommands/
        scheme.py
        wallpaper.py
        theme.py                  ← NEW
        lock.py                   ← NEW (enhanced)
        install.py
        update.py
        ...
    utils/
        wallpaper.py              ← MODIFIED: theme-aware
        scheme.py                 ← MODIFIED: user_locked flag
        theme_engine.py           ← NEW
        pywal_bridge.py           ← NEW
        lock_engine.py            ← NEW
        theme.py                  ← existing (apply_colours) MODIFIED
        paths.py                  ← existing, add theme paths
        ...
```

## QML Module Layout (lunar-shell)

New files only — everything else is upstream Caelestia:

```
services/
    Theme.qml               ← NEW singleton, watches theme.json
    LockState.qml           ← NEW singleton, exposes lock backend

modules/
    lock/
        Lock.qml            ← MODIFIED: dispatches to caelestia/qylock surface
        QylockSurface.qml   ← NEW: embeds Qylock themes + uses Caelestia PAM

    launcher/
        CarouselList.qml    ← NEW: Shared component for theme/pfp/wallpaper launcher sliders
        ContentList.qml     ← MODIFIED: Handles >theme, >pfp, >lockscreen
        AppList.qml         ← MODIFIED: Exposes launcher autocomplete actions

    nexus/pages/wallandstyle/
        ThemeSelect.qml     ← Full settings panel grid for theme selection
        WallpaperSelect.qml ← Full settings panel grid for wallpaper selection

    utilities/              ← NEW panel group (Phase 6)
        ScreenshotTools.qml
        BgRemover.qml
        PdfMarker.qml
```

The CLI package is kept named `caelestia` for internal compatibility.
The executable is installed to `~/.local/bin/caelestia` as a Python wrapper script, calling our `caelestia` Python package in `~/.local/lib/python3.14/site-packages/caelestia` (symlinked to `lunar-cli/src/caelestia`).
The AUR packages (`caelestia-shell`, `caelestia-cli`) have been removed and replaced entirely with our system-installed `lunar-shell` build and `lunar-cli` setup.
