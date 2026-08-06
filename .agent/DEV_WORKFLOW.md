# Development Workflow

## Local Dev Setup (One-Time)

### 1. Shell — Redirect QuickShell to Fork

QuickShell picks up the shell to run from `/etc/xdg/quickshell/caelestia/`.
To override, we set an env var or use the `-p` flag.

**Method**: Create a user-level systemd override or a wrapper script.

The simplest approach: QuickShell is started by Hyprland. Find where it's invoked:

```bash
grep -r "quickshell" ~/.config/hypr/ 2>/dev/null
grep -r "quickshell" ~/.local/share/caelestia/ 2>/dev/null
```

It's likely in the Caelestia-managed exec config. To override, check:
- `~/.local/share/caelestia/hyprland/exec.conf` or similar

The approach to redirect:
```bash
# Start quickshell pointing at our fork
quickshell -p /home/nuwa/work-linux/projects/arch/shell/lunar-shell
```

In the relevant exec config, change:
```ini
# From: exec-once = quickshell
# To:   exec-once = quickshell -p /home/nuwa/work-linux/projects/arch/shell/lunar-shell
```

### 2. CLI — pip Editable Install

The AUR package installs caelestia to `/usr/lib/python3.14/site-packages/caelestia/`.
We override it with an editable install that Python will prefer:

```bash
cd /home/nuwa/work-linux/projects/arch/shell/lunar-cli

# Install in editable mode (changes take effect immediately)
pip install --user -e .

# Verify our fork is loaded
python3 -c "import caelestia; print(caelestia.__file__)"
# Should print: /home/nuwa/work-linux/projects/arch/shell/lunar-cli/src/caelestia/__init__.py
```

If ~/.local/lib/python3.14/site-packages takes precedence over /usr/lib/..., this works.
If not, temporarily move/rename the AUR site-packages version.

### 3. Verify Dev Environment

```bash
# Shell is running from our fork?
qs ipc call wallpaper get    # Or check shell version some other way
ls -la /proc/$(pgrep quickshell)/exe  # See which binary is running

# CLI is from our fork?
python3 -c "import caelestia; print(caelestia.__file__)"

# Test a change:
# Edit a QML file in lunar-shell/ → restart shell → see change
echo "// test" >> /home/nuwa/work-linux/projects/arch/shell/lunar-shell/shell.qml
pkill quickshell
sleep 1
quickshell -p /home/nuwa/work-linux/projects/arch/shell/lunar-shell &
# Revert test change
```

## Day-to-Day Dev Loop

### Editing Shell (QML)
```bash
# Edit a file in lunar-shell/
vim /home/nuwa/work-linux/projects/arch/shell/lunar-shell/modules/lock/Lock.qml

# Restart shell to pick up changes
pkill quickshell; quickshell -p /home/nuwa/work-linux/projects/arch/shell/lunar-shell &

# Or if watchFiles: true is active — just save the file, shell hot-reloads
```

### Editing CLI (Python)
```bash
# Edit a file in lunar-cli/
vim /home/nuwa/work-linux/projects/arch/shell/lunar-cli/src/caelestia/utils/wallpaper.py

# Test immediately — no restart needed (editable install)
caelestia wallpaper -r

# Check logs
caelestia theme set jinx 2>&1
```

### Checking Shell Logs
```bash
# Method 1: journalctl
journalctl --user -f -u quickshell

# Method 2: Run with verbose output
pkill quickshell
QUICKSHELL_LOG=debug quickshell -p /home/nuwa/work-linux/projects/arch/shell/lunar-shell 2>&1 | tee /tmp/qs.log
```

## Rollback to Original Setup

> [!WARNING]
> Run `~/.local/bin/lunar-rollback` to instantly revert to the original Caelestia setup.

The rollback script is at `~/.local/bin/lunar-rollback`:

```bash
#!/bin/bash
echo "Rolling back to original Caelestia setup..."

# 1. Kill current quickshell
pkill quickshell 2>/dev/null

# 2. Start original caelestia quickshell
quickshell -p /etc/xdg/quickshell/caelestia &

# 3. (Optional) restore pip override
# pip uninstall caelestia -y 2>/dev/null  # remove editable install if needed

echo "Done. Running original Caelestia shell."
```

To make rollback permanent (revert exec-once):
```bash
# Edit back: change quickshell -p /home/.../lunar-shell → quickshell
# in wherever exec-once is configured
```

## Switching Between Dev and Prod

```bash
# Start dev (lunar fork)
pkill quickshell
quickshell -p /home/nuwa/work-linux/projects/arch/shell/lunar-shell &

# Start prod (original caelestia)
pkill quickshell
quickshell -p /etc/xdg/quickshell/caelestia &
# or just: quickshell (if no -p override in exec-once)
```

## Committing Changes

```bash
# Each repo is independent
cd /home/nuwa/work-linux/projects/arch/shell/lunar-shell
git add -p          # stage hunks selectively
git commit -m "feat(lock): add QylockSurface.qml"
git push origin main  # push to YOUR GitHub fork (not upstream)

# .agent/ is committed to the repo
git add .agent/
git commit -m "docs: update LOCK_SYSTEM.md"
```

## After GitHub Fork Setup

Once you've forked on GitHub:
```bash
# lunar-shell
cd lunar-shell
git remote add origin https://github.com/Nuwantha005/lunar-shell.git
git push -u origin main

# lunar-cli
cd ../lunar-cli
git remote add origin https://github.com/Nuwantha005/lunar-cli.git
git push -u origin main

# lunar-lock
cd ../lunar-lock
git remote add origin https://github.com/Nuwantha005/lunar-lock.git
git push -u origin main
```

Verify remotes:
```bash
# Each repo should have:
# origin  → your fork
# upstream → original caelestia/qylock repo
git remote -v
```
