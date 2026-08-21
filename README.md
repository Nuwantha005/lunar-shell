# lunar-shell

> [!NOTE]
> This repository is a custom fork of [caelestia-dots/shell](https://github.com/caelestia-dots/shell). It is designed to work as part of the integrated desktop environment alongside [lunar-cli](https://github.com/Nuwantha005/lunar-cli) and [lunar-lock](https://github.com/Nuwantha005/lunar-lock).

---

## Reasoning for Forking & Modifications

The original `caelestia-shell` was extended to create `lunar-shell` to support key custom desktop requirements:
- **Per-Theme Asset Management**: Integrated the custom `lunar` theme engine, enabling distinct wallpapers, profile pictures, lock screen backgrounds, and scheme configurations per theme.
- **Integrated Lock Screen System**: Deeply integrated `lunar-lock` (Qylock) themes directly into `lunar-shell`'s native `WlSessionLock` process without running external launcher processes.
- **Headless Lock Screen Preview**: Integrated with `lunar-cli` to display real-time pre-rendered lock screen previews within the shell's lock picker UI.

---

## Features & Architecture

- **4 Lock Screen Backends Architecture**:
  - `caelestia`: Default lock screen surface with native PAM authentication.
  - `qylock`: Deep QML integration running `lunar-lock` themes inside `WlSessionLock`.
  - `custom-qylock`: Embedded Qylock surface with custom image or video background override.
  - `hyprlock`: External compositor-level locking via dynamic runtime configuration (`~/.local/state/caelestia/hyprlock.conf`).
- **Integrated Lock Screen Picker**: Dedicated picker window (`caelestia lock --picker`) with instant IPC control (`qs ipc call lock openPicker`) and keyboard navigation.
- **Theme & Profile Picture Switcher Carousel**: Custom UI elements for browsing and applying desktop themes and profile picture assets on the fly.

---

## Technical Details

### Theme Folder Structure & `theme.json`

Desktop themes are stored in `~/Pictures/themes/<theme-name>/`. Each theme directory includes assets and a central metadata definition file, `theme.json`:

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

The shell's singleton services (`Theme.qml`, `Wallpapers.qml`, `LockState.qml`) continuously monitor `~/.local/state/caelestia/theme.json` to synchronize state changes across the UI.

### Lock Picker Navigation

The Lock Screen Picker (`LockPickerWindow.qml` / `LockPickerContent.qml`) provides full keyboard interaction:
- **`Tab` / `Shift+Tab`**: Cycle between active backends (`caelestia`, `hyprlock`, `qylock`, `custom-qylock`).
- **`←` / `→`**: Cycle Qylock themes (for `qylock` / `custom-qylock`) or Lock Wallpapers (for `hyprlock` / `custom-qylock`).
- **`↑` / `↓`**: Cycle Profile Pictures (for `caelestia` / `hyprlock`) or Qylock themes (for `custom-qylock`).
- **`Enter` / `Space`**: Apply active selection and close picker.
- **`Esc`**: Dismiss without saving.

---

## Installation & Setup

> [!WARNING]
> Installation currently requires manual configuration and technical knowledge, as file paths are hardcoded across `lunar-shell`, `lunar-cli`, and `lunar-lock`. A unified installation script is planned as a future target.

---

## Known Issues & Limitations

- **Caelestia Preview**: The profile picture in the lock screen picker preview is rendered as a standard rectangle rather than matching the real lock screen's diamond container. Left/Right arrow key navigation currently has no assigned action for this backend.
- **Hyprlock Config Cycling**: The picker does not currently have a dedicated keybind (e.g. `Spacebar`) assigned to switch between multiple `hyprlock` configuration files within the same theme.

---

## Gallery

<!-- Add screenshots and videos here -->
