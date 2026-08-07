# Development Workflow

## Architecture: Bleeding-Edge System Build & Dev Workflow

```
caelestia shell -d
    └── runs: qs -p ~/work-linux/projects/arch/shell/lunar-shell
              (hardcoded in lunar-cli/src/caelestia/subcommands/shell.py)

Python CLI & Packages:
    ~/.local/bin/caelestia (wrapper script)
    └── imports: ~/.local/lib/python3.14/site-packages/caelestia (symlink)
        └── → ~/work-linux/projects/arch/shell/lunar-cli/src/caelestia/

QML Plugins (C++ Modules):
    Built from lunar-shell/plugin/ and installed system-wide:
    - /usr/lib/qt6/qml/Caelestia/
    - /usr/lib/qt6/qml/M3Shapes/
    - /usr/lib/caelestia/version

Qylock Themes:
    lunar-shell/lock-themes → ../lunar-lock/themes/ (relative symlink, ignored in .gitignore)
```

---

## One-Time System Build & Setup

### 1. Build & Install `lunar-shell` (QML + C++ Plugins)

The latest QML components require matching C++ plugins (e.g. `Caelestia.Internal`, `M3Shapes`).
We build all modules directly from source and install to system paths:

```bash
cd ~/work-linux/projects/arch/shell/lunar-shell

# Configure with CMake
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="/" \
    -DINSTALL_LIBDIR="usr/lib/caelestia" \
    -DINSTALL_QMLDIR="usr/lib/qt6/qml" \
    -DINSTALL_QSCONFDIR="etc/xdg/quickshell/caelestia" \
    -DENABLE_MODULES="extras;plugin;shell;m3shapes" \
    -DDISTRIBUTOR="lunar-fork"

# Build all 227+ targets
ninja -C build

# Install system-wide (overwrites previous AUR paths cleanly)
sudo ninja -C build install
```

> [!IMPORTANT]
> **CMake QML Versioning Fix**: `plugin/cmake/qml-module.cmake` includes `VERSION 1.0` in `qt_add_qml_module`. This ensures C++ `QML_ELEMENT` types (such as `LogindManager`) are exported as `Caelestia.Internal/LogindManager 1.0` rather than the `254.0` fallback revision.

**Rebuild needed only when**: C++ source files in `plugin/src/` or CMake options change.
QML UI changes in `lunar-shell/` are read live by `qs -p ~/work-linux/projects/arch/shell/lunar-shell` and do **not** require a rebuild.

---

### 2. CLI Setup (`lunar-cli`)

1. **Python package symlink**:
   ```bash
   mkdir -p ~/.local/lib/python3.14/site-packages
   ln -sf ~/work-linux/projects/arch/shell/lunar-cli/src/caelestia \
       ~/.local/lib/python3.14/site-packages/caelestia
   ```

2. **CLI binary wrapper** (`~/.local/bin/caelestia`):
   ```bash
   cat > ~/.local/bin/caelestia << 'EOF'
   #!/usr/bin/env python3
   from caelestia import main
   main()
   EOF
   chmod +x ~/.local/bin/caelestia
   ```

3. Verify:
   ```bash
   which caelestia
   # Should print: /home/nuwa/.local/bin/caelestia
   python3 -c "import caelestia; print(caelestia.__file__)"
   # Should print: /home/nuwa/work-linux/projects/arch/shell/lunar-cli/src/caelestia/__init__.py
   ```

---

### 3. Lock Screen Themes Link (`lunar-lock`)

Connect `lunar-lock` themes to `lunar-shell` without submodule overhead:

```bash
cd ~/work-linux/projects/arch/shell/lunar-shell
ln -sf ../lunar-lock/themes lock-themes
```

`lock-themes` is listed in `lunar-shell/.gitignore` so local symlinks are not committed to git.

---

## Day-to-Day Development Loop

### Editing Shell (QML)

```bash
# 1. Edit QML files in lunar-shell/
vim ~/work-linux/projects/arch/shell/lunar-shell/modules/launcher/CarouselList.qml

# 2. Restart shell to load updated QML
caelestia shell -d

# 3. View live logs
caelestia shell --log
```

### Editing CLI (Python)

```bash
# 1. Edit python files in lunar-cli/
vim ~/work-linux/projects/arch/shell/lunar-cli/src/caelestia/utils/wallpaper.py

# 2. Test immediately (symlink reflects changes live)
caelestia wallpaper -r
```

### Editing Lock Screen Themes (Qylock QML)

```bash
# Edit files in lunar-lock/
vim ~/work-linux/projects/arch/shell/lunar-lock/themes/nier-automata/Main.qml
# Lunar shell accesses it instantly via lock-themes symlink!
```

---

## Rollback & Maintenance

- **Temporary Rollback**: Set `LUNAR_ROLLBACK=1` when calling `caelestia shell -d` to force `qs -c caelestia`.
- **Git Rollback**: Revert commits in `lunar-shell`, run `ninja -C build`, and `sudo ninja -C build install`.
