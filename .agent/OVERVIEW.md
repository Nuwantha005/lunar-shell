# Lunar Shell — Project Overview

## What This Is

A personal fork of the Caelestia desktop shell ecosystem for Hyprland/QuickShell.
This is NOT intended to be a public-facing project — it's a personalized desktop environment.

## Repo Layout

```
~/work-linux/projects/arch/shell/
├── .agent/          ← THIS FOLDER — agentic context, docs, roadmap
├── lunar-shell/     ← Fork of caelestia-dots/shell (QML/QuickShell)
├── lunar-cli/       ← Fork of caelestia-dots/cli (Python CLI)
└── lunar-lock/      ← Fork of Darkkal44/qylock (lock screen themes)
```

## Upstream Remotes

| Repo | Upstream | Our GitHub (after forking) |
|------|----------|---------------------------|
| `lunar-shell` | `https://github.com/caelestia-dots/shell.git` | `https://github.com/Nuwantha005/lunar-shell.git` |
| `lunar-cli` | `https://github.com/caelestia-dots/cli.git` | `https://github.com/Nuwantha005/lunar-cli.git` |
| `lunar-lock` | `https://github.com/Darkkal44/qylock.git` | `https://github.com/Nuwantha005/lunar-lock.git` |

After forking on GitHub, add origin in each repo:
```bash
# Example for lunar-shell:
cd lunar-shell
git remote add origin https://github.com/Nuwantha005/lunar-shell.git
git push -u origin main
```

## Key Decisions Made

- **Name**: `lunar` (shell, cli, lock)
- **Colour engine**: Material You (M3 tokens via `materialyoucolor`). M3 colours are funnelled to pywalfox for Firefox theming.
- **Theme storage**: `~/Pictures/themes/<name>/` with `wallpapers/` and `pfp/` subdirs. One wallpapers folder serves both desktop and lock screen.
- **pfp selection**: Stored as `selectedPfp` path inside `theme.json`. No separate picker state file.
- **Lock screen**: Deep Qylock integration — Qylock themes run inside the lunar-shell QuickShell process (not a separate process). Backend (caelestia/qylock/hyprlock) stored in `~/.local/state/caelestia/theme.json`.
- **Pickers**: Native QuickShell QML panels, matching Caelestia's existing wallpaper picker style.
- **Upstream merging**: Via `git fetch upstream` + `git cherry-pick` for selective updates.

## Current Status

- [x] Repos copied and git remotes configured
- [x] .agent docs written
- [ ] GitHub forks created and `origin` remotes set
- [ ] Local dev environment activated (manifest.conf redirect)
- [ ] pip editable install for lunar-cli
- [ ] Theme engine implementation (Phase 2)
- [ ] Dynamic colour persistence fix (Phase 3)
- [ ] Lock screen integration (Phase 4)
- [ ] Custom widgets (Phase 6)

## Quick Reference

- **Restart shell**: `pkill quickshell; quickshell &`
- **Check shell logs**: `journalctl --user -f -u quickshell` or `QUICKSHELL_LOG=debug quickshell`
- **Current wallpaper**: `cat ~/.local/state/caelestia/wallpaper/path.txt`
- **Current scheme**: `cat ~/.local/state/caelestia/scheme.json | python3 -m json.tool`
- **Rollback**: `~/.local/bin/lunar-rollback`
