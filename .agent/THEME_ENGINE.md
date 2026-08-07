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
  "selectedPfp": "pfp/pfp1.png",
  "lockBackend": "caelestia",
  "qylockTheme": null
}
```

Field explanations:
- `scheme`: `"dynamic"` = M3 from wallpaper. Any other value = predefined scheme name (e.g. `"catppuccin"`).
- `schemeFlavour`: for predefined schemes (e.g. `"mocha"` for catppuccin). `"default"` or `"hard"` for dynamic.
- `schemeMode`: `"dark"` or `"light"`. This OVERRIDES smart detection. If you want always-dark, set this.
- `schemeVariant`: `"tonalspot"`, `"vibrant"`, `"expressive"`, `"fidelity"`, etc. Overrides smart colourfulness detection.
- `selectedWallpaper`: relative path from theme dir. Updated by wallpaper picker.
- `selectedPfp`: relative path from theme dir. Updated by pfp picker.
- `lockBackend`: `"caelestia"`, `"qylock"`, or `"hyprlock"`.
- `qylockTheme`: name of Qylock theme to use when lockBackend is `"qylock"`. e.g. `"nier-automata"`.

## CLI: theme_engine.py

Location: `lunar-cli/src/caelestia/utils/theme_engine.py`

Key functions:

```python
THEMES_DIR = Path.home() / "Pictures/themes"
THEME_STATE_PATH = c_state_dir / "theme.json"

def get_themes_dir() -> Path:
    """Returns ~/Pictures/themes/"""

def list_themes() -> list[str]:
    """List all subdirs with a theme.json"""

def get_current_theme() -> dict | None:
    """Read active theme from ~/.local/state/caelestia/theme.json.
    Returns dict of theme.json contents, or None if no theme active."""

def load_theme_definition(name: str) -> dict:
    """Load ~/Pictures/themes/<name>/theme.json"""

def set_theme(name: str) -> None:
    """
    Full theme application pipeline:
    1. load_theme_definition(name)
    2. Save theme state FIRST & update active scheme.json (name & flavour) immediately
       so dynamic colour pipeline works correctly.
    3. Resolve wallpaper: selectedWallpaper if set, else first in wallpapers/
    4. Call set_wallpaper(wall) — triggers colour pipeline
       (scheme.json will be updated with dynamic colours from this wallpaper)
    5. Resolve pfp: selectedPfp if set, else first in pfp/
    6. Symlink pfp → ~/.local/state/caelestia/pfp.jpg
    7. Notify: notify-send "Theme applied" "Switched to {name}"
    """

def set_theme_wallpaper(wall_path: str) -> None:
    """
    Set a specific wallpaper within the current theme:
    1. Call set_wallpaper(wall_path)
    2. Update theme.json selectedWallpaper field
    """

def set_theme_pfp(pfp_path: str) -> None:
    """
    Set a specific pfp within the current theme:
    1. Copy pfp_path → ~/.local/state/caelestia/pfp.jpg
    2. Update theme.json selectedPfp field
    """
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
            root.themeData = t;
        }
    }

    FileSystemModel { id: wallpapersModel; path: root.themePath + "/wallpapers"; filter: FileSystemModel.Images }
    FileSystemModel { id: pfpsModel; path: root.themePath + "/pfp"; filter: FileSystemModel.Images }
    
    Searcher { id: pfpsSearcher; list: pfpsModel.entries; key: "name" }

    readonly property var themeWallpapers: wallpapersModel.entries
    function queryPfp(search) { return pfpsSearcher.query(search); }

    function setTheme(name) { Quickshell.execDetached(["caelestia", "theme", "set", name]); }
    function setWallpaper(path) { Quickshell.execDetached(["caelestia", "theme", "wallpaper", "set", path]); }
    function setPfp(path) { Quickshell.execDetached(["caelestia", "theme", "pfp", "set", path]); }
    function randomWallpaper() { Quickshell.execDetached(["caelestia", "theme", "wallpaper", "random"]); }
}
```

## Shell UI Options for Theme & Asset Selection

Theme switching and asset pickers are accessible via two distinct UI interfaces:

### Option A: Launcher Carousel (CarouselList.qml)

Location: `lunar-shell/modules/launcher/CarouselList.qml`

UI design:
- Quick horizontal sliding carousel (PathView) for fast keyboard-driven selection of Themes, Profile Pictures, Wallpapers, and Lockscreen backgrounds.
- Triggered by typing `>theme`, `>pfp`, `>wallpaper`, or `>lockscreen` in the launcher.
- Fully supports Vim-style (`h`/`l`) and Arrow key navigation.
- Preserves theme preview states cleanly and executes selections on `Enter`.

### Option B: Nexus Settings Panel (ThemeSelect.qml & WallpaperSelect.qml)

Location: `lunar-shell/modules/nexus/pages/wallandstyle/ThemeSelect.qml`

UI design:
- Full grid layout embedded inside the Nexus Settings panel (under Wallpaper & Style).
- Displays visual cards of all themes available in `~/Pictures/themes/`.
- Shows active theme badge and wallpaper preview thumbnails.
- Allows browsing featured and local theme wallpapers in a multi-column grid (`WallpaperSelect.qml`).

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
