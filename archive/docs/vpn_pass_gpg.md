
# Setup vpn and dependencies:
- openconnect
- pass
- gpg

```bash
sudo apt-get update
sudo apt-get install -y openconnect pass gpg xclip
```

```bash
gpg --full-generate-key
```
- Select RSA and RSA as the key type.
- Choose a key size of 4096.
- Set the expiry to 0 (no expiry) or a specific period.
- Enter your name, email, and a strong passphrase.
- Find your Key ID using: gpg --list-secret-keys --keyid-format LONG (look for the ID after rsa4096/). 

## Initializing and Using the Store
Initialize the password store: Create the ~/.password-store/ directory and link it to your GPG key:

```bash
pass init YOUR_GPG_KEY_ID
# Or using email: pass init your.email@example.com
```

### Manage passwords:
- Add a password: pass insert Service/username (interactive) or pass generate Service/username 24 (random 24-char password).
- Retrieve a password: pass Service/username (prints to terminal) or pass -c Service/username (copies to clipboard for 45 seconds).
- List entries: pass ls or pass to see the directory tree.
- Remove a password: pass rm Service/username.

### Optional: Git Integration: To sync your password store across machines:

```bash
pass git init
pass git remote add origin git@yourserver:password-store.git
pass git push -u origin master
```
