# Git Workflow — Remotes & Upstream Merging

## Remote Setup (Per Repo)

Each of the three repos has two remotes configured:

```
origin   → https://github.com/Nuwantha005/lunar-<name>.git  (YOUR GitHub fork)
upstream → original repository (caelestia-dots/shell, caelestia-dots/cli, Darkkal44/qylock)
```

Verify in any repo:
```bash
git remote -v
```

---

## Pulling Upstream Changes

Upstream changes can be pulled selectively (preferred) or via full merge:

```bash
# 1. Fetch upstream changes (does NOT modify local working tree)
git fetch upstream

# 2. Inspect new commits
git log HEAD..upstream/main --oneline

# 3a. Cherry-pick specific commits (selective — recommended)
git cherry-pick <commit-hash>

# 3b. Or merge full upstream branch
git merge upstream/main

# 4. Push to your fork
git push origin main
```

---

## `.agent/` Documentation Folder

The `.agent/` folder is located at `lunar-shell/.agent/` and is **tracked in git** inside `lunar-shell`.

- It only exists in your fork (`Nuwantha005/lunar-shell`), so upstream merges will **never** create conflicts in `.agent/`.
- Future AI agent runs can clone `lunar-shell` and immediately read the architectural context.

---

## `lunar-lock` Integration (Relative Symlink)

Instead of using git submodules, `lunar-shell` accesses Qylock lock themes via a local relative symlink:

```bash
cd ~/work-linux/projects/arch/shell/lunar-shell
ln -sf ../lunar-lock/themes lock-themes
```

- `lock-themes` is listed in `lunar-shell/.gitignore`.
- Both `lunar-shell` and `lunar-lock` remain independent git repos.
- Modifying themes in `lunar-lock/` reflects immediately in `lunar-shell/lock-themes/`.

---

## Repo Relationships Diagram

```
caelestia-dots/shell ──(fork)──→ Nuwantha005/lunar-shell  [includes .agent/]
        │                                  │
        └──── git fetch upstream ──────────┘ (cherry-pick/merge)

caelestia-dots/cli   ──(fork)──→ Nuwantha005/lunar-cli
Darkkal44/qylock     ──(fork)──→ Nuwantha005/lunar-lock ──(symlink)──> lunar-shell/lock-themes
```
