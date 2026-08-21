# Theme Engine Design

## Theme Directory Structure

```
~/Pictures/themes/
├── jinx/
│   ├── theme.json
│   ├── wallpapers/        ← used for BOTH desktop AND lock screen bg
│   │   ├── wall1.jpg
│   │   └── wall2.png
│   └── pfp/               ← multiple options; active one stored in theme.json
│       ├── pfp1.png
│       └── pfp2.jpg
├── ocean/
│   └── ...
└── space/
    └── ...
```

## theme.json Schema (Full)

```json
{
  "name": "jinx",
  "description": "Arcane-inspired electric theme",
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

Field explanations:
- `scheme`: `"dynamic"` = M3 from wallpaper. Any other value = predefined scheme name (e.g. `"catppuccin"`).
- `schemeFlavour`: for predefined schemes (e.g. `"mocha"` for catppuccin). `"default"` or `"hard"` for dynamic.
- `schemeMode`: `"dark"` or `"light"`. This OVERRIDES smart detection. If you want always-dark, set this.
- `schemeVariant`: `"tonalspot"`, `"vibrant"`, `"expressive"`, `"fidelity"`, etc. Overrides smart colourfulness detection.
- `selectedWallpaper`: relative path from theme dir. Updated by desktop wallpaper picker. Supports image (`.jpg`, `.png`, `.webp`) and video (`.mp4`, `.webm`).
- `selectedLockWallpaper`: relative path from theme dir. Decoupled lock screen wallpaper/video background.
- `selectedPfp`: relative path from theme dir. Updated by pfp picker.
- `lockBackend`: `"caelestia"`, `"qylock"`, `"custom-qylock"`, or `"hyprlock"`.
- `qylockTheme`: name of Qylock theme to use when lockBackend is `"qylock"` or `"custom-qylock"`. e.g. `"nier-automata"`.
- `hyprlockConfig`: filename of the Hyprlock configuration file inside `hyprlock/` directory when `lockBackend` is `"hyprlock"`. e.g. `"lock_screen1.conf"`.

## CLI: theme_engine.py

Location: `lunar-cli/src/caelestia/utils/theme_engine.py`

Key functions:

```python
THEMES_DIR = Path.home() / "Pictures/themes"
THEME_STATE_PATH = c_state_dir / "theme.json"

def get_themes_dir() -> Path:
    """Returns ~/Pictures/themes/"""

def list_themes() -> list[dict]:
    """List all subdirs with theme metadata, resolving wallpapers, lock wallpapers, pfps, and hyprlock configs."""

def get_current_theme_state() -> dict:
    """Read active theme state from ~/.local/state/caelestia/theme.json."""

def save_theme_state(data: dict) -> None:
    """Save state dict to ~/.local/state/caelestia/theme.json."""

def set_theme(name: str) -> bool:
    """
    Full theme application pipeline:
    1. Resolve theme metadata and wallpapers/pfps
    2. Save theme state to theme.json (so schemeMode & schemeVariant are honored)
    3. Update scheme.json immediately
    4. Call set_wallpaper() — triggers full color pipeline
    5. Copy / symlink pfp -> ~/.local/state/caelestia/pfp.jpg and ~/.face
    6. Write lock override background path to ~/.local/state/caelestia/lock_override_bg
    """

def set_theme_wallpaper(wall_path: str) -> bool:
    """Set desktop wallpaper and update selectedWallpaper in active theme.json."""

def set_theme_lock_wallpaper(wallpaper_path: str) -> bool:
    """Set lock screen wallpaper/video override and update selectedLockWallpaper in active theme.json."""

def set_theme_hyprlock_config(config_name: str) -> bool:
    """Set active Hyprlock config file name and update hyprlockConfig in active theme.json."""

def set_theme_pfp(pfp_path: str) -> bool:
    """Symlink pfp -> ~/.local/state/caelestia/pfp.jpg and ~/.face, updating selectedPfp in theme.json."""
```

## CLI: theme.py Subcommand

Location: `lunar-cli/src/caelestia/subcommands/theme.py`

Commands registered:
- `caelestia theme set <name>` → `set_theme(name)`
- `caelestia theme get` → print current theme name
- `caelestia theme list` → print all available themes
- `caelestia theme wallpaper set <path>` → `set_theme_wallpaper(path)`
- `caelestia theme wallpaper random` → pick random from current theme's wallpapers/
- `caelestia theme pfp set <path>` → `set_theme_pfp(path)`

## Shell: Theme.qml Service

Location: `lunar-shell/services/Theme.qml`

```qml
pragma Singleton
import QtQuick; import Quickshell; import Quickshell.Io

Singleton {
    id: root
    property string currentTheme: ""
    property string themePath: ""
    property string lockBackend: "caelestia"
    property string qylockTheme: ""
    property string hyprlockConfig: ""
    property var themeData: ({})

    FileView {
        path: `${Paths.state}/theme.json`
        watchChanges: true
        onLoaded: {
            const t = JSON.parse(text());
            root.currentTheme = t.name ?? "";
            root.themePath = t.path ?? "";
            root.lockBackend = t.lockBackend ?? "caelestia";
            root.qylockTheme = t.qylockTheme ?? "";
            root.hyprlockConfig = t.hyprlockConfig ?? "";
            root.themeData = t;
        }
    }

    FileSystemModel { id: themesDirModel; path: Paths.home + "/Pictures/themes"; filter: FileSystemModel.Directories; onEntriesChanged: root.refreshThemeList() }
    FileSystemModel { id: wallpapersModel; path: root.themePath + "/wallpapers"; filter: FileSystemModel.Images }
    FileSystemModel { id: pfpsModel; path: root.themePath + "/pfp"; filter: FileSystemModel.Images }

    Searcher { id: pfpsSearcher; list: pfpsModel.entries; key: "name" }

    readonly property var themeWallpapers: wallpapersModel.entries
    function queryPfp(search) { return pfpsSearcher.query(search); }

    function setTheme(name) { Quickshell.execDetached(["caelestia", "theme", "set", name]); }
    function setWallpaper(path) { Quickshell.execDetached(["caelestia", "theme", "wallpaper", "set", path]); }
    function setLockWallpaper(path) { Quickshell.execDetached(["caelestia", "lock", "--set-lock-wallpaper", path]); }
    function setPfp(path) { Quickshell.execDetached(["caelestia", "theme", "pfp", "set", path]); }
    function setLockBackend(backend) { Quickshell.execDetached(["caelestia", "lock", "--set-backend", backend]); }
    function setQylockTheme(theme) { Quickshell.execDetached(["caelestia", "lock", "--set-theme", theme]); }
    function setHyprlockConfig(cfg) { Quickshell.execDetached(["caelestia", "lock", "--set-hyprlock-config", cfg]); }
}
```

## Shell UI Options for Theme & Asset Selection

Theme switching and asset pickers are accessible via UI interfaces:

### Option A: Launcher Carousel (CarouselList.qml)

Location: `lunar-shell/modules/launcher/CarouselList.qml`

UI design:
- Quick horizontal sliding carousel (PathView) for fast keyboard-driven selection of Themes, Profile Pictures, and Wallpapers.
- Triggered by typing `>theme`, `>pfp`, or `>wallpaper` in the launcher.
- Fully supports Vim-style (`h`/`l`) and Arrow key navigation.

### Option B: Standalone Lock Screen Picker Window (LockPickerWindow.qml)

Location: `lunar-shell/modules/lock/LockPickerWindow.qml`

UI design:
- Dedicated standalone overlay window triggered by `caelestia lock --picker` or launcher action `Lock Screen Picker`.
- Features 4 backend tabs (`caelestia`, `hyprlock`, `qylock`, `custom-qylock`).
- Full keyboard control (`Tab`, `←`/`→`, `↑`/`↓`, `Enter`, `Esc`).

### Option C: Nexus Settings Panel (ThemeSelect.qml, WallpaperSelect.qml, LockPicker.qml)

Location: `lunar-shell/modules/nexus/pages/wallandstyle/`

UI design:
- Embedded inside the Nexus Settings panel under Wallpaper & Style.
- Visual grid cards for Theme selection (`ThemeSelect.qml`), Wallpaper browsing (`WallpaperSelect.qml`), and embedded Lock Picker (`LockPicker.qml`).

## Migration from Old Themes

Old themes are at `~/.config.bak/hypr/themes/` with structure:
```
<name>/
  wallpaper/            ← rename to wallpapers/
  lockScreenBackground/ ← merge into wallpapers/ (same pool now)
  pfp/                  ← keep as pfp/
  hyprlock.conf         ← discard (replaced by lunar lock system)
```

Migration script is at: `.agent/SCRIPTS/migrate-themes.sh`
