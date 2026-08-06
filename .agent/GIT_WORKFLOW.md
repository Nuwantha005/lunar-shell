# Git Workflow — Upstream Merging

## Remote Setup (Per Repo)

After GitHub forks are created:

```
origin   → https://github.com/Nuwantha005/lunar-shell.git  (YOUR fork)
upstream → https://github.com/caelestia-dots/shell.git     (original)
```

## Pulling Upstream Changes

```bash
# 1. Fetch what upstream has (does NOT change your files)
git fetch upstream

# 2. See what's new
git log upstream/main --oneline --since="1 week ago"
git log HEAD..upstream/main --oneline   # commits you don't have yet

# 3a. Cherry-pick a specific commit (selective — preferred)
git cherry-pick abc1234   # just that one fix

# 3b. Merge all upstream changes (careful — may conflict with our customizations)
git merge upstream/main

# 4. Resolve conflicts (if any) — our custom files won't exist in upstream, so low risk
# Key files we MODIFY that upstream also touches:
#   - modules/lock/Lock.qml     ← we change this
#   - services/Wallpapers.qml   ← we change this
#   - services/Colours.qml      ← we may change this
# If upstream touches these, resolve manually.

# 5. Push to our fork
git push origin main
```

## .gitignore Strategy for .agent/

The `.agent/` folder IS tracked in our fork. It only exists in our fork — upstream
Caelestia doesn't have it, so upstream merges will NEVER conflict on `.agent/`.

This means:
- `.agent/` is version-controlled and backed up to GitHub ✓
- Future AI sessions can read `.agent/` from the repo ✓
- Upstream merges don't interfere ✓

No `.gitignore` entry needed for `.agent/` — let it be tracked.

## What NOT to Merge from Upstream

These files are modified by us. Review carefully before accepting upstream changes:

### lunar-shell
- `modules/lock/Lock.qml` — we add Qylock dispatch
- `services/Wallpapers.qml` — we modify for theme-scoped picking
- `shell.qml` — we may add modules and disable others

### lunar-cli
- `src/caelestia/utils/wallpaper.py` — we add theme-awareness
- `src/caelestia/utils/theme.py` — we add pywal bridge call
- `src/caelestia/parser.py` — we add theme + lock subcommands

### Strategy: Topic Branches

For big upstream merges, use a topic branch:
```bash
git checkout -b merge-upstream-v2.3
git merge upstream/main
# Resolve conflicts
# Test thoroughly
git checkout main
git merge merge-upstream-v2.3
git branch -d merge-upstream-v2.3
```

## lunar-lock as Git Submodule (Recommended)

Instead of embedding Qylock themes by copy, use a submodule:

```bash
# In lunar-shell:
cd /home/nuwa/work-linux/projects/arch/shell/lunar-shell
git submodule add https://github.com/Nuwantha005/lunar-lock.git lock-themes
git commit -m "feat: add lunar-lock as lock-themes submodule"
```

Then when cloning fresh:
```bash
git clone --recurse-submodules https://github.com/Nuwantha005/lunar-shell.git
```

Updating Qylock themes from upstream:
```bash
cd lock-themes
git fetch upstream
git merge upstream/main   # get new Qylock themes
cd ..
git add lock-themes
git commit -m "chore: update lunar-lock to latest"
```

## Repo Relationships Diagram

```
caelestia-dots/shell ──(fork)──→ Nuwantha005/lunar-shell
        ↑                                  ↓
   upstream remote                    origin remote
        │                                  │
        └──── git fetch upstream ──────────┘
              git cherry-pick <hash>

caelestia-dots/cli ──(fork)──→ Nuwantha005/lunar-cli
Darkkal44/qylock   ──(fork)──→ Nuwantha005/lunar-lock (used as submodule in lunar-shell)
```

## GitHub Fork Setup Steps

1. Go to https://github.com/caelestia-dots/shell → "Fork" → fork to your account as `lunar-shell`
2. Go to https://github.com/caelestia-dots/cli → "Fork" → fork as `lunar-cli`
3. Go to https://github.com/Darkkal44/qylock → "Fork" → fork as `lunar-lock`

Then locally:
```bash
cd /home/nuwa/work-linux/projects/arch/shell/lunar-shell
git remote add origin https://github.com/Nuwantha005/lunar-shell.git
git push -u origin main

cd ../lunar-cli
git remote add origin https://github.com/Nuwantha005/lunar-cli.git
git push -u origin main

cd ../lunar-lock
git remote add origin https://github.com/Nuwantha005/lunar-lock.git
git push -u origin main
```

Note: The `.agent/` folder at `/home/nuwa/work-linux/projects/arch/shell/.agent/` is NOT inside
any of the three repos — it's at the parent `shell/` directory level. It won't be pushed
to any GitHub repo automatically. To version-control it, either:
1. Init a separate `shell-config` repo in the `shell/` directory itself
2. Add it to one of the repos (e.g., `lunar-shell/.agent/`)

Recommendation: Move `.agent/` inside `lunar-shell/.agent/` and track it there.
