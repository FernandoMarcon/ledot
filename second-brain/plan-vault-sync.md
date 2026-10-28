  ---
  Syncthing + Obsidian Multi-Device Architecture Plan

  Current State Analysis

  - Syncthing is already partially configured on ThinkPad (~/Vaults/): .stfolder, .stignore, and .stversions/LGCM/ exist
  - .stignore already correctly ignores .git, .obsidian, .trash — this is the right foundation
  - LGCM is clearly the primary/most configured vault (Obsidian Nord theme, vim mode, rich hotkeys, 10 plugins)
  - Other vaults have minimal or empty config (e.g., projects has blank appearance.json)
  - The wiki vault has old sync-conflict files — evidence of the problem with shared configs

  ---
  Part 1: Syncthing Configuration (ThinkPad ↔ Phone)

  Folder Setup

  ThinkPad folder: ~/Vaults/ (already exists, keep it)
  Phone folder: /storage/emulated/0/Vaults/ (Obsidian on Android can access internal storage here)

  Both devices: Send & Receive mode — the phone writes Daily Notes, ThinkPad writes everything.

  Device-Level Settings (Android Syncthing App)

  ┌─────────────────────────────┬──────────────────┬─────────────────────────────────────────────────────────────────────────────┐
  │           Setting           │      Value       │                                   Reason                                    │
  ├─────────────────────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────┤
  │ Sync only on WiFi           │ ON               │ Core requirement — home-only sync                                           │
  ├─────────────────────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────┤
  │ Sync only on these networks │ [your home SSID] │ Prevents accidental sync on public WiFi                                     │
  ├─────────────────────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────┤
  │ Run on mobile data          │ OFF              │ No data charges                                                             │
  ├─────────────────────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────┤
  │ Use relay servers           │ OFF              │ You only want LAN sync; no traffic through Syncthing's relay infrastructure │
  ├─────────────────────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────┤
  │ Local discovery             │ ON               │ Required for LAN peer discovery                                             │
  ├─────────────────────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────┤
  │ Global discovery            │ ON               │ Needed for device pairing (but relays off means no actual relay traffic)    │
  └─────────────────────────────┴──────────────────┴─────────────────────────────────────────────────────────────────────────────┘

  ▎ Why keep Global discovery ON but Relays OFF? Discovery (finding each other) and relaying (routing traffic through a server) are separate. With relays off, devices will find each other globally but only transfer data over direct LAN
  connections. No data leaves your home network.

  File Versioning

  Since git already provides full history for each vault, Syncthing versioning is just a safety net for accidental deletions and mid-sync conflicts. Keep it minimal:

  On ThinkPad: Trash Can Versioning
  - Clean deleted files after: 30 days
  - Path: ~/Vaults/.stversions/ (already configured)

  On Phone: Trash Can Versioning
  - Clean deleted files after: 14 days (storage is limited)

  Do NOT use Staggered or Simple versioning — git already handles history; doubling it wastes storage.

  Advanced Folder Settings

  ┌────────────────────┬────────────────────────────────┬─────────┬──────────────────────────────────────────────────────┐
  │      Setting       │            ThinkPad            │  Phone  │                        Reason                        │
  ├────────────────────┼────────────────────────────────┼─────────┼──────────────────────────────────────────────────────┤
  │ Watch for changes  │ ON                             │ ON      │ Near-real-time sync without polling                  │
  ├────────────────────┼────────────────────────────────┼─────────┼──────────────────────────────────────────────────────┤
  │ Rescan interval    │ 60s                            │ 60s     │ Fallback if filesystem watch misses events           │
  ├────────────────────┼────────────────────────────────┼─────────┼──────────────────────────────────────────────────────┤
  │ Ignore permissions │ OFF                            │ ON      │ Android FAT/exFAT doesn't support Unix permissions   │
  ├────────────────────┼────────────────────────────────┼─────────┼──────────────────────────────────────────────────────┤
  │ Conflict handling  │ Default (create conflict file) │ Default │ Acceptable; phone mostly writes new Daily Note files │
  └────────────────────┴────────────────────────────────┴─────────┴──────────────────────────────────────────────────────┘

  ---
  Part 2: .stignore (Improved)

  The current .stignore is a good start but has gaps. Replace it with:

  // ── Git ──────────────────────────────────────────────
  // Never sync git repos (catastrophic if mixed with GitHub sync plugin)
  .git

  // ── Obsidian ─────────────────────────────────────────
  // Config dirs: phone has its own Obsidian Mobile config
  .obsidian
  // Obsidian's own trash
  .trash

  // ── Syncthing meta ───────────────────────────────────
  .stfolder
  .stversions
  .stignore

  // ── Temp / OS files ──────────────────────────────────
  .DS_Store
  Thumbs.db
  desktop.ini
  *.tmp
  ~$*

  // ── Project-specific ─────────────────────────────────
  .env
  .f2py_f2cmap
  .gitignore

  Key additions vs. current:
  - .stversions — prevents phone from syncing ThinkPad's version history (large, useless on phone)
  - .DS_Store, Thumbs.db, desktop.ini — OS cruft
  - *.tmp, ~$* — temp files that could cause spurious sync events
  - Comments for maintainability

  ---
  Part 3: Data Flow & Workflow

  ┌─────────────────────────────────────────────────────────┐
  │                     Data Flows                          │
  │                                                         │
  │  Phone ←──── Syncthing (LAN/WiFi only) ────→ ThinkPad  │
  │                                                    ↕    │
  │                                                 GitHub  │
  │                                                    ↕    │
  │                                              Work Ubuntu│
  └─────────────────────────────────────────────────────────┘

  What syncs where:

  ┌────────────────────────────┬────────────────────────────┬───────────────────────────┐
  │          Content           │ ThinkPad↔Phone (Syncthing) │  ThinkPad↔Work (GitHub)   │
  ├────────────────────────────┼────────────────────────────┼───────────────────────────┤
  │ Notes (.md, .canvas, etc.) │ ✅                         │ ✅                        │
  ├────────────────────────────┼────────────────────────────┼───────────────────────────┤
  │ Attachments                │ ✅                         │ ✅                        │
  ├────────────────────────────┼────────────────────────────┼───────────────────────────┤
  │ .obsidian/ config          │ ❌ (ignored)               │ ✅ (in each vault's repo) │
  ├────────────────────────────┼────────────────────────────┼───────────────────────────┤
  │ .git/ dirs                 │ ❌ (ignored)               │ N/A (IS the mechanism)    │
  └────────────────────────────┴────────────────────────────┴───────────────────────────┘

  Phone write cycle:
  1. You're home, phone picks up a note → Syncthing pushes it to ThinkPad immediately (LAN)
  2. ThinkPad's GitHub sync plugin (running on its timer) picks it up and pushes to GitHub
  3. Work computer pulls from GitHub on next open

  No action needed — the two sync mechanisms (Syncthing + GitHub) are decoupled and non-interfering because .git and .obsidian are excluded from Syncthing.

  ---
  Part 4: Shared Obsidian Config Across Computers

  This is the most architectural piece. The goal: one unified theme, plugins, hotkeys, keymaps across all vaults on ThinkPad and Work Ubuntu — but NOT phone (Obsidian Mobile handles its own config).

  Why the Current Setup Doesn't Share Config

  Each vault has its own git repo. Config lives in .obsidian/ inside each vault and syncs only to the same vault on the other computer. LGCM's Nord theme and vim mode don't appear in projects or concursos because they're different repos.

  Recommended Architecture: Shared Config Layer via Symlinks + Dedicated Git Repo

  Concept: Create ~/Vaults/.obsidian-shared/ as the single source of truth for editor config. Each vault's .obsidian/ symlinks to the shared files. The shared dir has its own GitHub repo and is pulled on both computers.

  What to share vs. keep per-vault:

  ┌────────────────────────┬─────────┬──────────────────────────────────────────────────┐
  │          File          │ Shared? │                      Reason                      │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ appearance.json        │ ✅      │ Theme is global preference                       │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ app.json               │ ✅      │ Core editor settings (vim mode, font size, etc.) │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ hotkeys.json           │ ✅      │ Keymaps are personal, not vault-specific         │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ community-plugins.json │ ✅      │ Plugin list should be consistent                 │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ plugins/ (directory)   │ ✅      │ Plugin code and their configs                    │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ snippets/              │ ✅      │ CSS snippets are editor-wide                     │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ themes/                │ ✅      │ Theme files                                      │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ workspace.json         │ ❌      │ Machine/session state (open tabs)                │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ daily-notes.json       │ ❌      │ Vault-specific (folder paths differ)             │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ templates.json         │ ❌      │ Vault-specific                                   │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ graph.json             │ ❌      │ Vault-specific                                   │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ bookmarks.json         │ ❌      │ Vault-specific                                   │
  ├────────────────────────┼─────────┼──────────────────────────────────────────────────┤
  │ core-plugins.json      │ ⚠️       │ Mostly shared, but some vaults may differ        │
  └────────────────────────┴─────────┴──────────────────────────────────────────────────┘

  Implementation Steps

  Step 1: Create the shared config repo
  mkdir ~/Vaults/.obsidian-shared
  cd ~/Vaults/.obsidian-shared
  git init

  # Copy from LGCM (your most complete vault) as the starting point
  cp ~/Vaults/LGCM/.obsidian/appearance.json .
  cp ~/Vaults/LGCM/.obsidian/app.json .
  cp ~/Vaults/LGCM/.obsidian/hotkeys.json .
  cp ~/Vaults/LGCM/.obsidian/community-plugins.json .
  cp -r ~/Vaults/LGCM/.obsidian/plugins .
  cp -r ~/Vaults/LGCM/.obsidian/snippets .
  cp -r ~/Vaults/LGCM/.obsidian/themes .

  git add -A
  git commit -m "Initial shared obsidian config"
  # Push to a new GitHub repo: obsidian-shared-config

  Step 2: Apply symlinks to all vaults (run once per machine)
  #!/usr/bin/env bash
  # ~/Vaults/apply-shared-config.sh
  set -euo pipefail

  SHARED="$HOME/Vaults/.obsidian-shared"
  SHARED_FILES="appearance.json app.json hotkeys.json community-plugins.json"
  SHARED_DIRS="plugins snippets themes"
  VAULTS_DIR="$HOME/Vaults"

  for vault_obs in "$VAULTS_DIR"/*/.obsidian; do
      vault=$(dirname "$vault_obs")
      [ -d "$vault_obs" ] || continue

      for f in $SHARED_FILES; do
          src="$SHARED/$f"
          target="$vault_obs/$f"
          [ -f "$src" ] || continue
          # Back up if it's a real file (not already a symlink)
          [ -L "$target" ] || { [ -f "$target" ] && mv "$target" "$target.bak"; }
          ln -sf "$src" "$target"
      done

      for d in $SHARED_DIRS; do
          src="$SHARED/$d"
          target="$vault_obs/$d"
          [ -d "$src" ] || continue
          [ -L "$target" ] || { [ -d "$target" ] && mv "$target" "$target.bak"; }
          ln -sf "$src" "$target"
      done

      echo "Linked: $(basename $vault)"
  done

  Step 3: On Work Ubuntu (one-time setup)
  git clone git@github.com:youruser/obsidian-shared-config.git ~/Vaults/.obsidian-shared
  bash ~/Vaults/apply-shared-config.sh

  Step 4: Workflow for config changes

  When you change a setting in Obsidian (e.g., change theme, add a hotkey):
  - Obsidian writes to the symlink → the write goes to ~/.obsidian-shared/ directly
  - Commit and push ~/Vaults/.obsidian-shared/ to GitHub
  - On work computer: cd ~/Vaults/.obsidian-shared && git pull
  - Config is immediately applied everywhere (no script re-run needed)

  Step 5: Add .obsidian-shared to Syncthing's .stignore (already covered above — .stignore at the Vaults root ignores .obsidian patterns; the phone doesn't need shared config at all since its .obsidian/ dirs are all ignored by Syncthing)

  Handling each vault's git repo

  Each vault's git repo will now track symlinks for the shared files (git handles symlinks as special files). When you push LGCM's repo with a symlink at .obsidian/appearance.json → ../../.obsidian-shared/appearance.json, and the work
  computer pulls, git recreates the symlink — which resolves correctly as long as ~/Vaults/.obsidian-shared/ is cloned there.

  Add to each vault's .gitignore (if not already):
  .obsidian/workspace.json
  .obsidian/workspace-mobile.json

  ---
  Summary Checklist

  Syncthing (one-time)

  - Add Phone as device in ThinkPad's Syncthing (exchange device IDs)
  - Share ~/Vaults/ folder with phone, path /storage/emulated/0/Vaults/
  - Set both sides: Send & Receive, Trash Can versioning
  - Android Syncthing: WiFi-only + restrict to home SSID + relays OFF
  - Update .stignore with the improved version above

  Shared Config (one-time)

  - Create ~/Vaults/.obsidian-shared/ from LGCM's config
  - Push to new GitHub repo
  - Run apply-shared-config.sh on ThinkPad
  - Clone .obsidian-shared/ on Work Ubuntu and run the script there
  - Add workspace.json and workspace-mobile.json to each vault's .gitignore

  Ongoing

  - Config changes: commit + push .obsidian-shared/, pull on work machine
  - New vault added: run apply-shared-config.sh again — it's idempotent
  - Phone Daily Notes: automatic via Syncthing → ThinkPad → GitHub → Work

  ---
  One Subtlety: the github-sync plugin on ThinkPad

  Since Syncthing can deliver phone notes to ThinkPad at any time, and the GitHub sync plugin runs on a timer — make sure the plugin's conflict strategy is set to handle incoming changes gracefully (most implementations do a
  pull-before-push). No special action needed, but worth verifying the plugin's settings in LGCM so it doesn't just overwrite with local state.
