# Lock Screen System Design

## Backends Supported

| Backend | Trigger | Notes |
|---------|---------|-------|
| `caelestia` | QuickShell IPC `caelestia lock` | Default. Uses WlSessionLock inside QuickShell process. |
| `qylock` | Embedded in lunar-shell's Lock.qml | Deep integration — Qylock themes run inside the SAME QuickShell process. |
| `hyprlock` | `hyprlock` binary | External. locks unique to the themes. stored at `~/Pictures/themes/<theme-name>/hyprlock.conf` (Caelestia manages this). |


## State

Lock backend and Qylock theme are stored inside `theme.json`:

```json
{
  ...,
  "lockBackend": "qylock",
  "qylockTheme": "nier-automata"
}
```

Exposed to QML via `Theme.qml` singleton (`Theme.lockBackend`, `Theme.qylockTheme`). For hyprlock and phase 4b lock, we use the wallpaper image as the background.

## Deep Qylock Integration Architecture

### Why "deep integration"?

Qylock's `quickshell.sh` launcher runs a SEPARATE QuickShell process (`lock_shell.qml`).
This is messy — it conflicts with the running lunar-shell process, and the themes
use an SDDM shim for auth which doesn't work cleanly with Hyprland session lock.

Deep integration means: run Qylock themes INSIDE lunar-shell's existing WlSessionLock,
using lunar-shell's PAM auth (Pam.qml) — same as the caelestia lock surface.

### lunar-lock repo role

`lunar-lock` (fork of qylock) is NOT run as a separate process.
We take its `themes/` directory and use the `Main.qml` from each theme.
The `lock_shell.qml`, `lock.sh`, and SDDM shim are NOT used.

The `lunar-lock` repo is either:
- A **git submodule** inside `lunar-shell/lock-themes/` → keeps themes updatable
However, qylock is a massive 1.5 GB repo. Adding it as a submodule will drain network for no reason and consume storage as well. apart from that, I needed to maintain it as a fork, so i forked the original repo and placed it in `/home/nuwa/work-linux/projects/arch/shell/lunar-lock` folder. What we can do is either symlink it to inside of the lunar-shell or someone use the 2 modules independently. Need an evaluation on the options.
- OR themes are copied directly into lunar-shell

Recommended: **git submodule** at `lunar-shell/lock-themes` pointing to `lunar-lock`.

```bash
cd lunar-shell
git submodule add https://github.com/Nuwantha005/lunar-lock.git lock-themes
```

Then `Lock.qml` references themes at: `Qt.resolvedUrl("../../lock-themes/themes/" + Theme.qylockTheme + "/Main.qml")`

### Modified Lock.qml

Location: `lunar-shell/modules/lock/Lock.qml`

```qml
WlSessionLock {
    id: lock

    LockSurface {   // this becomes a Loader that switches surfaces
        lock: lock
        pam: pam
    }
}
```

Becomes:

```qml
WlSessionLock {
    id: lock

    // Dynamic surface based on backend
    Loader {
        property var lock: lock  // pass lock ref
        property var pam: pam
        source: {
            switch (Theme.lockBackend) {
                case "qylock":  return "QylockSurface.qml"
                case "hyprlock": return ""  // dispatched externally below
                default:         return "LockSurface.qml"
            }
        }
        onLoaded: item.lock = lock
    }
}

// Hyprlock: dispatch externally when requested
Connections {
    target: lock
    function onLockedChanged() {
        if (lock.locked && Theme.lockBackend === "hyprlock") {
            lock.locked = false;  // release our lock
            Quickshell.execDetached(["hyprlock"]);
        }
    }
}
```

### New QylockSurface.qml

Location: `lunar-shell/modules/lock/QylockSurface.qml`

```qml
// Embeds a Qylock theme's Main.qml using our PAM auth
import QtQuick; import Quickshell; import Quickshell.Wayland; import qs.components.misc

Item {
    property var lock   // WlSessionLock ref
    property var pam    // Pam.qml ref (handles PAM auth, same as caelestia)

    readonly property string themePath:
        Quickshell.shellPath("lock-themes/themes/" + Theme.qylockTheme)

    Loader {
        anchors.fill: parent
        source: "file://" + themePath + "/Main.qml"
        onLoaded: {
            // Inject auth signal — Qylock themes expect an `authenticate(password)` signal
            // and emit `authenticated` or `failed`
            item.forceActiveFocus()
        }
        onStatusChanged: {
            if (status === Loader.Error)
                console.error("Failed to load Qylock theme:", source)
        }
    }

    // Bridge: listen for password submit from Qylock theme UI
    // Qylock themes emit passwordSubmitted(pass) or similar
    // We forward to Pam for verification
    Connections {
        target: loader.item
        // Adapt based on actual signal name in each theme
        function onPasswordSubmitted(password) { pam.authenticate(password) }
    }
}
```

> NOTE: Qylock themes were designed for SDDM (different auth flow). Some adaptation
> of the auth bridging may be needed per-theme. This is the main complexity of deep integration.

### Keybind

Update `~/.config/hypr/caelestia/hyprland/keybinds_extra.conf`:
```ini
# OLD:
bind = SUPER, L, exec, hyprlock
# NEW:
bind = SUPER, L, exec, caelestia lock
```

The `caelestia lock` command reads `theme.json` and triggers the appropriate backend:
- For `caelestia` and `qylock`: sends IPC message to QuickShell to lock
- For `hyprlock`: runs hyprlock directly

## CLI: lock.py Subcommand

Location: `lunar-cli/src/caelestia/subcommands/lock.py`

```
caelestia lock                                    → lock with current backend
caelestia lock --backend caelestia                → switch backend + lock
caelestia lock --backend qylock --theme nier-automata → switch backend + theme + lock
caelestia lock --backend hyprlock                 → switch to hyprlock + lock
caelestia lock --list-backends                    → print available backends
caelestia lock --list-themes                      → list available Qylock themes
caelestia lock --set-backend qylock               → change backend without locking
caelestia lock --set-theme pixel-sakura           → change theme without locking
```

Lock action sends IPC to QuickShell:
```python
subprocess.run(["caelestia", "shell", "lock"], ...)
# Or directly via QS IPC:
subprocess.run(["qs", "ipc", "call", "lock", "lock"], ...)
```

## LockPicker.qml Panel

A panel in the dashboard to configure lock settings:

- Segmented: [Caelestia] [Qylock] [hyprlock]
- When Qylock selected: scrollable grid of Qylock themes (37 available) similar to how wallpapers or themes are shown in quick picker.Both caelestia and hyprlock locks are one per theme: meaning we don't need a seperate carousel type chooser for them, we only need it for qylock lock and phase 4b custom background thing.
  - Each shows theme preview image from `lock-themes/Assets/previews/<name>/`
  qylock proivdes animated set of gifs (or videos) for each lock. For custom locks like hyprlock or caelestia lock, we might have to render them somehow.
  - Clicking a theme: calls `caelestia lock --set-theme <name>`
- Apply immediately or just change setting

## Qylock Theme Custom Background (Phase 4b)

When a theme's wallpaper should replace the Qylock theme's background:

1. CLI `set_theme()` writes selected wallpaper path to `~/.local/state/caelestia/lock_override_bg`
2. `QylockSurface.qml` reads this file and sets it as background:
   ```qml
   FileView {
       path: Paths.state + "/lock_override_bg"
       onLoaded: backgroundOverridePath = text().trim()
   }
   ```
3. Pass `backgroundOverridePath` to the loaded Qylock theme's background component

This is per-theme implementation (each Qylock theme's Main.qml needs to support it).
Start with one or two themes. Not urgent.
