# Neovim: migrate packer.nvim → lazy.nvim

packer.nvim is archived (unmaintained since Aug 2023). Its README recommends
[lazy.nvim](https://github.com/folke/lazy.nvim). Do this once comfortable with
the current config.

## 1. Swap the installer in `setup/dotfiles.sh`

Replace the body of `install_pkg_manager()`:

```bash
install_pkg_manager() {
    local lazy="${HOME}/.local/share/nvim/lazy/lazy.nvim"
    if [ ! -d "$lazy" ]; then
        echo "  [>] nvim: installing lazy.nvim..."
        git clone --quiet --filter=blob:none --branch=stable \
            https://github.com/folke/lazy.nvim.git "$lazy"
        track_install nvim-lazy "git:folke/lazy.nvim" "$(git -C "$lazy" rev-parse --short HEAD)"
        echo "  [>] nvim: lazy.nvim installed"
    else
        track_detected nvim-lazy
    fi
}
```

Optional: skip the script install entirely and let `init.lua` bootstrap
lazy.nvim itself (the snippet in step 2 does this already).

## 2. Bootstrap lazy in `config/nvim/init.lua`

Put this before any plugin config. Set `mapleader` before it, since lazy
reads mappings on load.

```lua
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")  -- loads every file in lua/plugins/
```

Each file in `config/nvim/lua/plugins/` returns a table of plugin specs.

## 3. Translate plugin specs

| packer                                  | lazy                                   |
|-----------------------------------------|----------------------------------------|
| `use 'user/repo'`                       | `{ 'user/repo' }`                      |
| `requires = {...}`                      | `dependencies = {...}`                 |
| `run = ':TSUpdate'`                     | `build = ':TSUpdate'`                  |
| `config = function() ... end`           | `config = function() ... end` (same)   |
| `setup = function() ... end`            | `init = function() ... end`            |
| `tag = 'v1.*'`                          | `version = '1.*'` (or `tag = ...`)     |
| `branch`, `commit`                      | same                                   |
| `opt = true`                            | `lazy = true`                          |
| `cmd`, `ft`, `keys`, `event`            | same (`event` also takes `VeryLazy`)   |
| `after = 'other'`                       | put `'other'` in `dependencies`        |
| `as = 'name'`                           | `name = 'name'`                        |
| `disable = true`                        | `enabled = false`                      |
| `lock = true`                           | `pin = true`                           |

When a plugin only needs `require('x').setup(opts)`, lazy shortens it to
`opts = { ... }`.

Example:

```lua
-- packer
use { 'nvim-telescope/telescope.nvim', tag = '0.1.8',
      requires = { 'nvim-lua/plenary.nvim' } }

-- lazy: lua/plugins/telescope.lua
return {
  'nvim-telescope/telescope.nvim', tag = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },
}
```

## 4. Remove packer

```bash
rm -rf ~/.local/share/nvim/site/pack/packer
rm -f  ~/ledot/config/nvim/plugin/packer_compiled.lua
```

Drop any `require('packer')` / `packer.startup` code and the
`PackerCompile` autocmd from the config.

## 5. Verify

- `nvim` → `:Lazy` opens the UI; `:Lazy sync` installs everything.
- `:checkhealth lazy`
- Commit `config/nvim/lazy-lock.json` (pins plugin versions).

Command mapping: `:PackerSync` → `:Lazy sync`, `:PackerStatus` → `:Lazy`,
`:PackerClean` → `:Lazy clean`, `:PackerCompile` → not needed.
