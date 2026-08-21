# System Architecture

## How the Stack Works

```
User action (keybind / CLI / Launcher / IPC)
        │
        ▼
lunar-cli (Python package, invoked via ~/.local/bin/caelestia)
        │
        ├── writes state files to ~/.local/state/caelestia/
        ├── triggers DBus signals (KGlobalSettings.notifyChange) for Qt/Dolphin
        ├── recolors Kitty terminals via Unix sockets (kitten @ --to=unix:<sock>)
        ├── funnels M3 colors to pywalfox (~/.cache/wal/colors.json)
        └── communicates with QuickShell via IPC (qs ipc call lock ...)
        │
        ▼
~/.local/state/caelestia/        ← STATE DIRECTORY
    ├── scheme.json              ← Active colour scheme (M3 palette JSON)
    ├── theme.json               ← Active lunar theme & lock configuration
    ├── lock_override_bg         ← Active lockscreen background override path
    ├── hyprlock.conf            ← Auto-generated runtime hyprlock launcher config
    ├── wallpaper/
    │   ├── path.txt             ← Current wallpaper path (watched by shell)
    │   ├── current → <path>     ← Symlink to wallpaper
    │   └── thumbnail.jpg        ← 128x128 thumbnail
    └── pfp.jpg                  ← Current profile picture (symlink to active pfp)

        │
        │ FileView & FileSystemModel watch changes (QML)
        ▼
lunar-shell (QML via QuickShell)
    ├── services/
    │   ├── Colours.qml          ← Reads scheme.json, exposes M3 palette
    │   ├── Wallpapers.qml       ← Reads wallpaper/path.txt, manages wallpapers & previews
    │   ├── Theme.qml            ← Reads theme.json, exposes theme, lockBackend, pfp
    │   └── LockState.qml        ← Exposes active lock backend and Qylock theme
    └── modules/
        ├── lock/
        │   ├── Lock.qml         ← WlSessionLock & IPC target ("lock")
        │   ├── LockSurface.qml  ← Default Caelestia lock UI
        │   ├── QylockSurface.qml← Embeds Qylock themes inside WlSessionLock
        │   ├── LockPickerWindow.qml ← Standalone overlay window for Lock Picker
        │   └── LockPickerContent.qml← 4-backend tabbed picker UI with keyboard nav
        ├── launcher/
        │   ├── CarouselList.qml ← Launcher slider for wallpapers, themes, pfps
        │   ├── ContentList.qml  ← Routes autocomplete actions (>theme, >pfp)
        │   └── AppList.qml      ← Resolves launcher commands to actions
        └── nexus/pages/wallandstyle/
            ├── ThemeSelect.qml  ← Settings panel theme selection grid
            ├── WallpaperSelect.qml ← Theme wallpaper selector grid
            └── LockPicker.qml   ← Embedded Lock Screen Picker tab
```

## Key Data Flow: Inter-App & Colour Pipeline

```
User picks wallpaper / theme (or CLI runs set_wallpaper / set_theme)
    │
    ▼
lunar-cli: set_wallpaper(path)
    ├── Writes path to ~/.local/state/caelestia/wallpaper/path.txt
    ├── Generates 128x128 thumbnail in ~/.local/state/caelestia/wallpaper/thumbnail.jpg
    ├── If scheme == "dynamic": generates M3 palette via materialyoucolor & updates scheme.json
    ├── apply_colours():
    │   ├── Hyprland   → writes ~/.config/hypr/scheme/current.lua
    │   ├── GTK 3/4    → updates gtk.css & thunar.css
    │   ├── Qt/Dolphin  → updates qtengine/caelestia.colors & sends DBus org.kde.KGlobalSettings.notifyChange
    │   ├── Terminals  → scans /tmp & $XDG_RUNTIME_DIR for Kitty sockets, executes kitten @ --to=unix:<sock> set-colors
    │   ├── Neovim     → updates ~/.config/nvim/lua/caelestia_theme.lua
    │   └── Pywalfox   → generates ~/.cache/wal/colors.json & calls pywalfox update
    └── Updates theme.json selectedWallpaper field

lunar-shell: Colours.qml (FileView watches scheme.json)
    └── Reloads M3 palette → all QML UI rebinds live
```

## Key Data Flow: Lock System & Labwc Headless Previews

```
CLI / Launcher action: caelestia lock --picker (or qs ipc call lock openPicker)
    │
    ▼
QuickShell: Lock.qml IpcHandler receives openPicker()
    └── Loads LockPickerWindow.qml (LockPickerContent.qml)
        ├── Tab 0: Caelestia Lock (uses default WlSessionLock + Caelestia surface)
        ├── Tab 1: Hyprlock (dispatches hyprlock with runtime ~/.local/state/caelestia/hyprlock.conf)
        ├── Tab 2: Qylock (embeds Qylock theme Main.qml inside WlSessionLock)
        └── Tab 3: Custom Qylock (embeds Qylock theme + custom wallpaper/video bg override)

Preview Generation (caelestia lock --generate-previews / --render-preview):
    ├── Spawns labwc in headless mode (WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1)
    ├── Sets resolution (1920x1080) via wlr-randr
    ├── If video bg (.mp4/.webm): extracts 1st frame via ffmpeg (-ss 00:00:01 -vframes 1)
    ├── Launches hyprlock or qylock lock.sh script with settle delay (1.8s - 2.5s)
    ├── Captures screenshot via grim → saves to ~/.cache/caelestia/previews/{hyprlock,custom-qylock}/<hash>.png
    └── Updates manifest.json with SHA-256 cache keys
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
  "selectedWallpaper": "wallpapers/wall1.jpg",
  "selectedLockWallpaper": "wallpapers/wall1.jpg",
  "selectedPfp": "pfp/pfp1.png",
  "lockBackend": "custom-qylock",
  "qylockTheme": "nier-automata",
  "hyprlockConfig": "lock_screen1.conf"
}
```

## Python Package Layout (lunar-cli)

```
src/caelestia/
    __init__.py
    __main__.py
    parser.py                     ← CLI arguments (theme, lock, scheme, wallpaper, preview options)
    subcommands/
        scheme.py
        wallpaper.py
        theme.py                  ← Theme commands
        lock.py                   ← Lock backend launcher, IPC calls, preview CLI options
        install.py
        update.py
    utils/
        wallpaper.py              ← Smart dynamic M3 color generation & wallpaper state
        scheme.py                 ← Scheme persistence & locked modes
        theme_engine.py           ← Theme switching, lock wallpaper & hyprlock config setting
        pywal_bridge.py           ← Pywalfox colors.json generator & bridge
        preview.py                ← Headless labwc compositor capture, video frame extraction, manifest cache
        theme.py                  ← App recoloring (Hyprland, GTK, Qt/Dolphin DBus, Kitty sockets, Neovim)
        paths.py                  ← State & cache path definitions
```

## QML Module Layout (lunar-shell)

```
services/
    Theme.qml               ← Singleton: watches theme.json, exposes currentTheme, lockBackend, pfp
    LockState.qml           ← Singleton: exposes lock backend and Qylock theme state
    Colours.qml             ← Singleton: watches scheme.json, exposes M3 palette

modules/
    lock/
        Lock.qml            ← WlSessionLock wrapper, IPC target ("lock"), shortcuts & hyprlock launcher
        LockSurface.qml     ← Caelestia lock UI surface
        QylockSurface.qml   ← Embeds Qylock themes + Caelestia PAM auth bridge
        LockPickerWindow.qml← Standalone overlay window for lock screen selection
        LockPickerContent.qml← Keyboard-driven tabbed UI (Caelestia, Hyprlock, Qylock, Custom Qylock)

    launcher/
        CarouselList.qml    ← Launcher carousel slider for wallpapers, themes, pfps
        ContentList.qml     ← Routes launcher autocomplete actions (>theme, >pfp)
        AppList.qml         ← Exposes launcher autocomplete actions

    nexus/pages/wallandstyle/
        ThemeSelect.qml     ← Full settings panel grid for theme selection
        WallpaperSelect.qml ← Full settings panel grid for wallpaper selection
        LockPicker.qml      ← Embedded Nexus Settings tab wrapping LockPickerContent.qml
```

The CLI package is kept named `caelestia` for internal compatibility.
The executable is installed to `~/.local/bin/caelestia` as a Python wrapper script calling `lunar-cli`.
All AUR packages (`caelestia-shell`, `caelestia-cli`) have been removed and replaced entirely with system-installed `lunar-shell` builds and `lunar-cli`.

