# Lock Screen System Design

## Backends Supported

| Backend | Trigger | Notes |
|---------|---------|-------|
| `caelestia` | QuickShell IPC `caelestia lock` | Default. Uses WlSessionLock inside QuickShell process with Caelestia PAM auth surface. |
| `qylock` | QuickShell IPC `caelestia lock -b qylock -t <theme>` | Deep integration — Qylock themes run inside the SAME QuickShell process via `QylockSurface.qml`. |
| `custom-qylock` | QuickShell IPC `caelestia lock -b custom-qylock` | Qylock theme embedded inside WlSessionLock with custom wallpaper or video background override set in Caelestia (`~/.local/state/caelestia/lock_override_bg`). |
| `hyprlock` | `hyprlock` binary | External. Sourced per-theme configs stored at `~/Pictures/themes/<theme-name>/hyprlock/*.conf` via dynamically generated runtime config `~/.local/state/caelestia/hyprlock.conf`. |

## State Management

Lock backend, Qylock theme, decoupled lock wallpaper, and Hyprlock config are stored inside `theme.json`:

```json
{
  "name": "jinx",
  "path": "/home/nuwa/Pictures/themes/jinx",
  "scheme": "dynamic",
  "selectedWallpaper": "wallpapers/wall1.jpg",
  "selectedLockWallpaper": "wallpapers/wall1.jpg",
  "selectedPfp": "pfp/pfp1.png",
  "lockBackend": "custom-qylock",
  "qylockTheme": "nier-automata",
  "hyprlockConfig": "lock_screen1.conf"
}
```

Exposed to QML via `Theme.qml` singleton (`Theme.lockBackend`, `Theme.qylockTheme`, `Theme.hyprlockConfig`).

## Deep Qylock Integration Architecture

### Why "deep integration"?

Qylock's native `quickshell.sh` launcher runs a SEPARATE QuickShell process (`lock_shell.qml`), which conflicts with the running lunar-shell process and uses an SDDM shim for auth. Deep integration runs Qylock themes INSIDE lunar-shell's existing `WlSessionLock` using lunar-shell's native PAM authentication (`Pam.qml`).

### lunar-lock Repository Role

`lunar-lock` (our fork of qylock) is connected via a local relative symlink:
`lunar-shell/lock-themes` → `../lunar-lock/themes/` (ignored in `lunar-shell/.gitignore`).

`QylockSurface.qml` loads the target theme directly:
`Qt.resolvedUrl("../../lock-themes/themes/" + Theme.qylockTheme + "/Main.qml")`

### Lock Dispatching in `Lock.qml`

Location: `lunar-shell/modules/lock/Lock.qml`

`Lock.qml` wraps `WlSessionLock` and registers `IpcHandler` targeting `"lock"`.

```qml
Scope {
    property alias lock: lock

    WlSessionLock {
        id: lock
        signal unlock

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Connections {
        target: lock
        function onLockedChanged(): void {
            if (lock.locked && Theme.lockBackend === "hyprlock") {
                lock.locked = false; // release WlSessionLock
                Quickshell.execDetached(["hyprlock"]);
            }
        }
    }

    Pam { id: pam; lock: lock }

    CustomShortcut {
        name: "unlock"
        description: "Unlock the current session"
        onPressed: {
            lock.unlock();
            Quickshell.execDetached(["pkill", "-USR1", "hyprlock"]);
        }
    }

    LazyLoader {
        id: lockPickerLoader
        Variants {
            model: Screens.screens
            LockPickerWindow {
                modelData: modelData
                onClose: lockPickerLoader.activeAsync = false
            }
        }
    }

    IpcHandler {
        function lock(): void { lock.locked = true; }
        function unlock(): void { lock.unlock(); Quickshell.execDetached(["pkill", "-USR1", "hyprlock"]); }
        function isLocked(): bool { return lock.locked; }
        function openPicker(): void { lockPickerLoader.activeAsync = true; }
        function closePicker(): void { lockPickerLoader.activeAsync = false; }
        target: "lock"
    }
}
```

## Instant Lock Screen Picker Window

Location: `lunar-shell/modules/lock/LockPickerWindow.qml` & `LockPickerContent.qml`

Triggered via `caelestia lock --picker` or IPC call `qs ipc call lock openPicker`.

### Features & Layout:
- **4 Backend Tabs**: `[Caelestia]` `[Hyprlock]` `[Qylock]` `[Custom Qylock]`
- **Keyboard Navigation**:
  - `Tab` / `Shift+Tab`: Cycle active backend tab
  - `←` / `→`: Cycle Qylock Theme (for Qylock / Custom Qylock) or Lock Wallpaper (for Hyprlock / Custom Qylock)
  - `↑` / `↓`: Cycle Profile Picture (for Caelestia / Hyprlock) or Qylock Theme (for Custom Qylock)
  - `Enter` / `Space`: Apply current selection and close window
  - `Esc`: Close window without applying
- **Lazy Loading**: `LockPickerWindow` is loaded asynchronously via `LazyLoader` in `Lock.qml` on `openPicker()` IPC call.
- **Embedded Tab in Settings**: `LockPickerContent.qml` is also embedded into Nexus Settings (`modules/nexus/pages/wallandstyle/LockPicker.qml`).

## Headless Labwc Preview Engine & Cache Architecture

To provide instant previews in the lock picker for `hyprlock` and `custom-qylock` backends, `lunar-cli` includes a headless rendering pipeline (`utils/preview.py`).

### Headless Execution (`capture_with_labwc`):
- **Environment**: Sets `WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1`, removing `HYPRLAND_INSTANCE_SIGNATURE`.
- **Headless Compositor**: Launches `labwc` with a runner script configuring resolution `1920x1080` via `wlr-randr`.
- **Settling Delays**: Waits for visuals to load before taking a screenshot using `grim`:
  - `HYPRLOCK_SETTLE_DELAY = 1.8` seconds
  - `CUSTOM_QYLOCK_SETTLE_DELAY = 2.5` seconds
- **Video Background Frame Extraction**: If the lock screen background is a video (`.mp4`, `.webm`, `.mkv`), `ffmpeg` extracts the frame at 1s:
  `ffmpeg -y -ss 00:00:01 -i <video> -vframes 1 <tmp.png>`

### Cache Location & Keying:
- **Path**: `~/.cache/caelestia/previews/{hyprlock,custom-qylock}/`
- **Manifest**: `manifest.json` tracks metadata, parameters, and generated timestamps.
- **Cache Keying**: SHA-256 hash of concatenated file mtime identities (`path:mtime_ns`) and config/theme IDs (`preview_cache_key`). Modifying a wallpaper or PFP automatically invalidates the cache key.
- **CLI Commands**:
  - Batch generation: `caelestia lock --generate-previews`
  - On-Demand JIT rendering: `caelestia lock --render-preview --preview-backend <backend> --preview-wallpaper <wall> --preview-output <dest>`

## CLI: lock.py Subcommand

Location: `lunar-cli/src/caelestia/subcommands/lock.py`

```bash
caelestia lock                                    # Lock session using active backend
caelestia lock -b, --backend <backend>            # Switch backend and lock
caelestia lock -t, --theme <theme>                # Switch Qylock theme and lock
caelestia lock -p, --picker                       # Open instant Lock Screen Picker window
caelestia lock --hyprlock-config <cfg.conf>       # Switch Hyprlock config and lock
caelestia lock --set-backend <backend>            # Set backend in theme.json without locking
caelestia lock --set-theme <theme>                # Set Qylock theme in theme.json without locking
caelestia lock --set-hyprlock-config <cfg.conf>   # Set Hyprlock config in theme.json without locking
caelestia lock --set-lock-wallpaper <path>        # Set lock screen background override
caelestia lock --list-backends                    # List backends (* for active)
caelestia lock --list-themes                      # List available Qylock themes
caelestia lock --list-hyprlock-configs            # List Hyprlock configs for active theme
caelestia lock --generate-previews                # Batch generate headless preview cache
caelestia lock --render-preview ...               # Render a single preview image JIT
```

## Emergency Unlock Mechanism

If lock screen authentication fails or hangs:
- Keyboard shortcut `CustomShortcut { name: "unlock" }` or IPC call `qs ipc call lock unlock` triggers `pkill -USR1 hyprlock` and releases `WlSessionLock`.
- Available as CLI fallback command options.



# Additional Notes and Future Work

## QYLock not supporting custom background
some qylock themes dont respect enforecd backgorund for some reason: their backgorund might be qml generated for example. there were few such cases that came acrros in the first run:
```
issue: blur plane, nothing else
themes: genshin, clockwork
issue: default background
themes:R1999_1, girl-coffee, last-of-us, nothing, star-rail, wuwa
issue: doesn't unlock when pressed enter
themes: material-you, ninesols, ninja_gaiden, nothing,  osu, osumania,
```

Not unlocking part is some incompatibility or something. They didn't wor when i used qylock raw either.

## Previews

### Headless rendering
We first tired a headless hyprland which was impossible, and then `weston` but it didnt suuport `grim` to take screenshots, so we moved on with `labwc` which worked perfectly fine.

Right now we just dynamically lazy load the previews using the headless compositor an cache them. But we can go ao step further and live pipe the frames from the headless to our window for live wallpaper display, but this is an overkill for now.

### Hyprlock
Hyprlock rendering works fine. But i forgot that when we have multiple configs, we need a way to switch between them. Rn left right moves wallpaper and up down moves the pfp. maybe we can use space to move config.

### Caelestia
The caelestia preview is fine, except its pfp is not inside that diamond shape container like in the real one. Also i have this idea to swich its colours similar to how we use wallpaepr carousel, since its left right keys doesnt do anything rn.

### Native Qylock
The gifs are too blury. maybe we can use that live rendering thing i mentoned in [[###Headless rendering]] here to get high res preview while keeping gifs for left and right side thumbnails.

## Publishing
I think I should add this to portfolio. But before that i neeed to clean files in the `.agent` folder since they are outdated. Then I have to update all the readme's acknoledge the original repos and outline my custom modifications. Only then i can proceed to take ss , video and do some prsentation, which i hates. So I will do that later.

## Developement
I'm kinda getting fratigue for non stop working on this for few days so i will move on to something else and come back later. (or never idk) As my last action I will try to add video support for custom qylock -  really want that reze dancing video as my lock bg....
