# Lunar Shell — Project Overview

## What This Is

A personal fork of the Caelestia desktop shell ecosystem for Hyprland/QuickShell.
This is NOT intended to be a public-facing project — it's a personalized desktop environment.

## Repo Layout

```
~/work-linux/projects/arch/shell/
├── lunar-shell/     ← Fork of caelestia-dots/shell (QML/QuickShell & C++ plugins)
│   └── .agent/      ← Agentic context, docs, roadmap (tracked in lunar-shell)
├── lunar-cli/       ← Fork of caelestia-dots/cli (Python CLI)
└── lunar-lock/      ← Fork of Darkkal44/qylock (lock screen themes)
```

## Remotes Setup

| Repo | Upstream | Our GitHub Fork (origin) |
|------|----------|---------------------------|
| `lunar-shell` | `https://github.com/caelestia-dots/shell.git` | `https://github.com/Nuwantha005/lunar-shell.git` |
| `lunar-cli` | `https://github.com/caelestia-dots/cli.git` | `https://github.com/Nuwantha005/lunar-cli.git` |
| `lunar-lock` | `https://github.com/Darkkal44/qylock.git` | `https://github.com/Nuwantha005/lunar-lock.git` |

## Key Decisions & Architecture

- **Name**: `lunar` (shell, cli, lock)
- **AUR Removal**: Uninstalled `caelestia-shell` and `caelestia-cli` from AUR. Built directly from `lunar-shell` and installed to system paths (`/usr/lib/qt6/qml/Caelestia`, `/etc/xdg/quickshell/caelestia`).
- **CMake QML Versioning**: Set `VERSION 1.0` in `plugin/cmake/qml-module.cmake` so C++ `QML_ELEMENT` types (like `LogindManager`) export cleanly as version 1.0 instead of 254.0.
- **CLI Executable**: `~/.local/bin/caelestia` wrapper script calling `lunar-cli` via `~/.local/lib/python3.14/site-packages/caelestia` symlink.
- **Lock Screen Themes**: Local relative symlink `lunar-shell/lock-themes` → `../lunar-lock/themes/` (ignored in `.gitignore`). Zero overhead, direct editing.
- **Colour Engine**: Material You (M3 tokens via `materialyoucolor`). M3 colours funnelled to pywalfox for Firefox theming.
- **Theme Storage**: `~/Pictures/themes/<name>/` with `wallpapers/` and `pfp/` subdirs. One wallpapers folder serves both desktop and lock screen.
- **Upstream Merging**: Via `git fetch upstream` + `git cherry-pick` / `git merge upstream/main`.

## Current Status

- [x] Repos copied and git remotes configured (upstream & origin)
- [x] `.agent` docs created & committed to `lunar-shell/.agent/`
- [x] GitHub forks created and remotes connected
- [x] AUR packages removed (`caelestia-shell`, `caelestia-cli`)
- [x] System build & install configured (`lunar-shell/build`)
- [x] `VERSION 1.0` fix applied in `plugin/cmake/qml-module.cmake`
- [x] `caelestia` CLI wrapper installed to `~/.local/bin/caelestia`
- [x] `lunar-lock` connected via `lock-themes` symlink
- [x] Theme engine implementation (Phase 2)
- [x] Dynamic colour persistence & Pywalfox bridge (Phase 3)
- [ ] Lock screen integration (Phase 4)
- [ ] Custom widgets (Phase 6)

## Quick Reference

- **Build & System Install**:
  ```bash
  cd ~/work-linux/projects/arch/shell/lunar-shell
  cmake -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="/" \
      -DINSTALL_LIBDIR="usr/lib/caelestia" \
      -DINSTALL_QMLDIR="usr/lib/qt6/qml" \
      -DINSTALL_QSCONFDIR="etc/xdg/quickshell/caelestia" \
      -DENABLE_MODULES="extras;plugin;shell;m3shapes" \
      -DDISTRIBUTOR="lunar-fork"
  ninja -C build
  sudo ninja -C build install
  ```
- **Restart Shell**: `caelestia shell -d`
- **Check Shell Logs**: `caelestia shell --log` or `qs -p ~/work-linux/projects/arch/shell/lunar-shell log`
- **Current Scheme**: `cat ~/.local/state/caelestia/scheme.json | python3 -m json.tool`
