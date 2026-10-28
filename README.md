# Dotfiles

## Before `setup/bootstrap.sh` (full guide: [setup/README.md](setup/README.md))
Use the **GitHub CLI device flow** — it gives you a one-time code you enter in any browser (including your phone).

```bash
# Install gh CLI
sudo apt update && sudo apt install gh -y

# Authenticate — choose HTTPS, then "Login with a web browser"
gh auth login
```

It will print something like:

```
! First copy your one-time code: ABCD-1234
- Press Enter to open github.com in your browser...
```

Don't press Enter (no browser on a server). Instead, **open `github.com/login/device` on your phone**, enter the code, and approve. Back on the server, the auth completes automatically.

Then clone:

```bash
gh repo clone FernandoMarcon/ledot ~/ledot
# or
git clone https://github.com/FernandoMarcon/ledot.git ~/ledot
```

---

## After cloning: set up a proper SSH key (`setup/bootstrap.sh` does this for you)

Once you're in, generate a key and add it to GitHub so future pushes work normally:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
# Accept defaults, optionally set a passphrase

# Print the public key
cat ~/.ssh/id_ed25519.pub
```

Then add it to GitHub: **Settings → SSH and GPG keys → New SSH key**, paste it in. From then on you can switch your remote to SSH:

```bash
cd ~/ledot
git remote set-url origin git@github.com:FernandoMarcon/ledot.git
```

## Main Programs
- vim
- i3
- dmenu
- ranger
- tmux
- vimwiki

Run:
```bash
git clone git@github.com:FernandoMarcon/ledot.git ~/ledot
bash ~/ledot/setup/install.sh
```

## TO-DO
### NVIM/VIM
- vim -> nvim
- Add (, [, etc surrounding word
- Folding 
- File tree
- render-markdown (plugin)

### TMUX
- when new tab, load .env and activate conda prj env
- Floating terminal 
- Lazygit
- 

## Resources
### VIM/NVIM
#### vimrc
- [mikehaertl](https://gist.github.com/mikehaertl/1612035)
- https://www.youtube.com/watch?v=g1gyYttzxcI

### BASH
- https://www.youtube.com/watch?v=b3W7Ky_aaaY
- https://www.youtube.com/watch?v=D6HmEi9C5K8

### RANGER
- https://www.youtube.com/watch?v=L6Vu7WPkoJo
- https://www.youtube.com/watch?v=EyW6pRlWv6Q

### TMUX
- https://www.youtube.com/watch?v=7BP9iWiKx8Q

### I3WM

### DMENU
- https://www.youtube.com/watch?v=a2GWqF32U8Q
- https://www.youtube.com/watch?v=Dlj_SbE8zG4
- https://www.youtube.com/watch?v=R9m723tAurA

### VIMWIKI/MARKDOWN
- 
