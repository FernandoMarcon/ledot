# Brave Browser Installation
## Prepare Ubuntu for Brave APT Repository

Refresh APT first so Ubuntu has current package metadata before you add Brave’s external source:

```bash
sudo apt update
```

These commands use sudo for tasks that need root privileges. If your user account is not in the sudoers file yet, follow the guide on how to add and manage sudo users on Ubuntu.

Install the small tools used to download Brave’s keyring and repository file over HTTPS:

```bash
sudo apt install curl ca-certificates -y
```

The curl command downloads the repository files, and ca-certificates lets APT and curl verify HTTPS certificates. Both are common on Ubuntu desktops, but minimal installs may need them.

### Add Official Brave APT Repository

Brave publishes a binary GPG keyring and a ready-made DEB822 .sources file, so there is no need for apt-key, a Launchpad PPA, or manual codename substitution. Install the stable source for normal browsing.

### Add Brave Stable Repository

Download the stable channel keyring to the path referenced by Brave’s source file:

```bash
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
```

Then download Brave’s stable APT source definition:

```bash
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
```

### Update & Install
```bash
sudo apt update
sudo apt install brave-browser -y
```

## After Installation
1. access proton mail ( https://account.proton.me/login )
2. access bitwarden
    - install browser extension: https://bitwarden.com/download/#downloads-web-browser-extensions
    - or login via website: https://vault.bitwarden.com/#/login
3. insert sync code into brave ( brave://settings/braveSync/setup )

