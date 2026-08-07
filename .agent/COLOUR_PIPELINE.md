# Colour Pipeline Design

## Overview

M3 (Material You) colours extracted by `materialyoucolor` are funnelled to:
1. **QuickShell UI** — via `scheme.json` & QML `Colours.qml` singleton
2. **Hyprland** — via `~/.config/hypr/scheme/current.lua`
3. **GTK / Qt** — via CSS templates (`gtk.css`, `thunar.css`, `qtengine.colors`)
4. **Terminals** — via ANSI sequences to `/dev/pts/*`
5. **Firefox** — via pywalfox (`pywal_bridge.py`)

### Live Carousel Preview Pipeline

During launcher carousel navigation (`>wallpaper` / `>theme`):
1. **QML** calls `caelestia wallpaper -p <image>` for the active item.
2. **lunar-cli** extracts dynamic M3 colours and live-applies:
   - **Terminals**: Sends ANSI escape sequences to `/dev/pts/*` (`apply_terms`), updating Kitty/Alacritty/Foot live on hover.
   - **GTK Apps**: Writes `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` (`apply_gtk`), live-reloading Thunar/GTK UI colors on hover.
   - **QML Shell**: Returns JSON palette to QML `Colours.qml` (`showPreview = true`).
3. **Exit / Cancel Preview**: `stopPreview()` in `Wallpapers.qml` triggers `caelestia scheme restore` to revert terminals and GTK apps back to the active saved scheme.
4. **Apply Selection**: `set_wallpaper` saves the new scheme permanently to `scheme.json` and runs full `apply_colours` and user `postHook` (`wal`, `pywalfox`, etc.).

### QML Preview Lock Fix

`Colours.qml` listens to `Wallpapers.previewColourLock`. When `previewColourLock` becomes `false` (after wallpaper write completes), a `Connections` handler forces `root.reload()` to guarantee the newly saved `scheme.json` is never missed due to asynchronous file watcher timing.

## The Dynamic Scheme Problem & Fix

### What's Happening

In `set_wallpaper()` (lunar-cli/src/caelestia/utils/wallpaper.py, lines 175-185):

```python
scheme = get_scheme()  # reads scheme.json

if scheme.name == "dynamic" and not no_smart:
    smart_opts = get_smart_opts(wall_cache, cache)
    scheme.mode = smart_opts["mode"]       # ← OVERRIDES your dark preference
    scheme.variant = smart_opts["variant"] # ← OVERRIDES your chosen variant
```

Smart detection uses:
- `mode`: if wallpaper dominant tone > 60 → light, else → dark
- `variant`: based on colourfulness score (< 10 → neutral, < 20 → content, else → tonalspot)

So if you set dynamic + dark + tonalspot, then change to a bright wallpaper, smart detection flips to light mode. Feels like a "reset".

### The Fix

In `set_wallpaper()`, respect theme-locked preferences:

```python
scheme = get_scheme()
theme = get_current_theme()

if theme:
    # Theme explicitly declares mode/variant — honour them
    if "schemeMode" in theme and theme["schemeMode"]:
        scheme._mode = theme["schemeMode"]
    if "schemeVariant" in theme and theme["schemeVariant"]:
        scheme._variant = theme["schemeVariant"]
    # Still regenerate colours from new wallpaper if dynamic
    if scheme.name == "dynamic":
        scheme.update_colours()
elif scheme.name == "dynamic" and not no_smart:
    # No theme active — use smart detection as before
    smart_opts = get_smart_opts(wall_cache, cache)
    scheme.mode = smart_opts["mode"]
    scheme.variant = smart_opts["variant"]
    scheme.update_colours()
```

Also: after `apply_colours()`, call `funnel_to_pywalfox(scheme.colours)`.

### Diagnosis Before Implementing

Run these to understand the current bug:

```bash
# What scheme is currently saved?
cat ~/.local/state/caelestia/scheme.json | python3 -m json.tool

# Set dynamic explicitly
caelestia scheme set -n dynamic
cat ~/.local/state/caelestia/scheme.json | python3 -m json.tool
# Check: is name = "dynamic" ?

# Change wallpaper
caelestia wallpaper -r
cat ~/.local/state/caelestia/scheme.json | python3 -m json.tool
# Check: is name still "dynamic"? Did mode/variant change?
```

## pywalfox Bridge (NEW)

### Why

pywalfox reads `~/.cache/wal/colors.json` (pywal format) to theme Firefox.
We never run pywal, so that file is empty/missing → Firefox doesn't get themed.

### Solution

After every colour change (`apply_colours()`), generate a pywal-compatible
`colors.json` from the M3 palette, then run `pywalfox update`.

### Implementation

File: `lunar-cli/src/caelestia/utils/pywal_bridge.py`

```python
import json, subprocess
from pathlib import Path
from caelestia.utils.paths import wallpaper_path_path

PYWAL_COLORS_PATH = Path.home() / ".cache/wal/colors.json"

def m3_to_pywal(colours: dict[str, str]) -> dict:
    """
    Map M3 colour tokens to pywal colors.json format.

    M3 tokens available (from scheme.json 'colours' dict):
      background, onBackground, surface, onSurface, surfaceVariant, onSurfaceVariant,
      primary, onPrimary, primaryContainer, onPrimaryContainer,
      secondary, onSecondary, secondaryContainer, onSecondaryContainer,
      tertiary, onTertiary, tertiaryContainer, onTertiaryContainer,
      outline, outlineVariant, inverseSurface, inverseOnSurface,
      term0..term15 (terminal colours)
    """
    wallpaper = ""
    try:
        wallpaper = wallpaper_path_path.read_text().strip()
    except IOError:
        pass

    return {
        "wallpaper": wallpaper,
        "alpha": "100",
        "special": {
            "background": f"#{colours['surface']}",
            "foreground": f"#{colours['onSurface']}",
            "cursor":     f"#{colours['secondary']}",
        },
        "colors": {
            f"color{i}": f"#{colours[f'term{i}']}"
            for i in range(16)
        }
    }

def funnel_to_pywalfox(colours: dict[str, str]) -> None:
    """Generate pywal colors.json and run pywalfox update."""
    try:
        pywal_data = m3_to_pywal(colours)
        PYWAL_COLORS_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(PYWAL_COLORS_PATH, "w") as f:
            json.dump(pywal_data, f, indent=2)
        subprocess.run(
            ["pywalfox", "update"],
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
        )
    except Exception:
        pass  # Don't crash if pywalfox isn't installed
```

### Where to Call It

In `lunar-cli/src/caelestia/utils/theme.py`, inside `apply_colours()`, at the very end (after the existing app applications):

```python
# At end of apply_colours():
from caelestia.utils.pywal_bridge import funnel_to_pywalfox
funnel_to_pywalfox(colours)
```

This means Firefox gets updated whenever:
- Wallpaper changes (scheme regenerated)
- Theme changes
- User explicitly runs `caelestia scheme set`

## Scheme Variants Available

```
tonalspot   ← default, balanced
vibrant     ← high saturation
expressive  ← very vivid, creative
fidelity    ← stays close to wallpaper source colour
fruitsalad  ← playful
monochrome  ← greyscale
neutral     ← muted, low saturation
rainbow     ← uses multiple hues
content     ← subtle, content-aware
```

## M3 Colour Token Reference

Key tokens used in QML (`Colours.m3<name>`):
- `m3primary` — accent colour (buttons, highlights)
- `m3onPrimary` — text on primary
- `m3primaryContainer` — muted primary (card backgrounds)
- `m3surface` — base surface (panels, backgrounds)
- `m3onSurface` — text on surface
- `m3surfaceContainer` — slightly elevated surface
- `m3surfaceContainerHigh` — more elevated
- `m3outline` — borders, dividers
- `m3background` — page background

Terminal mappings (term0-15) follow standard 16-colour order.
