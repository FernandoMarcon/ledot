# Second Brain Setup

This directory manages the shared Obsidian configuration for all vaults across machines.
The `setup.sh` script bootstraps `~/Vaults/` on any new machine.

## Directory Structure

```
~/.dotfiles/second-brain/
├── setup.sh              # Bootstrap script (run once per machine)
├── setup.md              # This file
├── plan-vault-sync.md    # Architecture reference (Syncthing + GitHub sync plan)
└── obsidian-configs/     # Shared Obsidian config — single source of truth
    ├── appearance.json
    ├── app.json
    ├── hotkeys.json
    ├── community-plugins.json
    ├── core-plugins.json
    ├── plugins/
    │   ├── checklist-progress
    │   ├── dataview
    │   ├── github-sync
    │   ├── obsidian-excalidraw-plugin
    │   ├── obsidian-latex-suite
    │   ├── obsidian-tasks-plugin
    │   ├── pdf-plus
    │   ├── table-editor-obsidian
    │   ├── tag-wrangler
    │   └── templater-obsidian
    ├── snippets/
    └── themes/
        └── Obsidian Nord
```

## What `setup.sh` Does

### 1. Creates `~/Vaults/`

### 2. Clones vaults from GitHub

| Vault      | Remote                                      |
|------------|---------------------------------------------|
| LGCM       | git@github.com:FernandoMarcon/LGCM          |
| concursos  | git@github.com:FernandoMarcon/concursos.git |
| leiloes    | git@github.com:FernandoMarcon/leiloes.git   |
| projects   | git@github.com:FernandoMarcon/projects.git  |
| wiki       | git@github.com:FernandoMarcon/wiki.git      |

> H4 and Piracaia have no GitHub remote — create them manually if needed.
> Clone is skipped if the vault directory already exists.

### 3. Symlinks shared config into each vault

For every directory under `~/Vaults/`, the script symlinks the shared files and dirs
into `<vault>/.obsidian/`, backing up any pre-existing real files as `<file>.bak`.

**Shared (symlinked from `obsidian-configs/`):**

| File/Dir                | Why shared                              |
|-------------------------|-----------------------------------------|
| `appearance.json`       | Theme is a global preference            |
| `app.json`              | Core editor settings (vim mode, fonts)  |
| `hotkeys.json`          | Keymaps are personal, not vault-specific|
| `community-plugins.json`| Plugin list should be consistent        |
| `core-plugins.json`     | Mostly shared across vaults             |
| `plugins/`              | Plugin code and their configs           |
| `snippets/`             | CSS snippets are editor-wide            |
| `themes/`               | Theme files                             |

**Kept per-vault (not symlinked):**

| File                    | Why per-vault                           |
|-------------------------|-----------------------------------------|
| `workspace.json`        | Machine/session state (open tabs)       |
| `daily-notes.json`      | Vault-specific folder paths             |
| `templates.json`        | Vault-specific                          |
| `graph.json`            | Vault-specific                          |
| `bookmarks.json`        | Vault-specific                          |

## Usage

### New machine setup

```bash
git clone git@github.com:FernandoMarcon/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/second-brain/setup.sh
```

### After adding a new vault

Add the remote to `VAULT_REMOTES` in `setup.sh`, then re-run the script. It is idempotent.

### Updating shared config

Changes made in Obsidian (e.g. new hotkey, theme tweak) write through the symlink directly
into `obsidian-configs/`. Commit and push from `~/.dotfiles`:

```bash
cd ~/.dotfiles
git add second-brain/obsidian-configs/
git commit -m "update obsidian shared config"
git push
```

On other machines, a `git pull` in `~/.dotfiles` picks up the changes immediately —
no need to re-run `setup.sh`.

## How This Fits the Broader Sync Architecture

```
Phone ←── Syncthing (LAN/WiFi) ──→ ThinkPad
                                       ↕
                                    GitHub
                                       ↕
                                 Work Ubuntu
```

- **Phone ↔ ThinkPad**: Syncthing syncs note content only. `.obsidian/` is excluded from
  Syncthing (phone manages its own Obsidian Mobile config).
- **ThinkPad ↔ Work Ubuntu**: Each vault's git repo syncs notes + symlinks. The symlinks
  resolve correctly as long as `~/.dotfiles` is cloned at the same path.
- **Shared config**: Lives in this dotfiles repo, applied via symlinks. One `git pull`
  propagates config changes to all vaults on all machines.

See `plan-vault-sync.md` for the full architecture including Syncthing configuration
and `.stignore` setup.
