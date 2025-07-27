# Backup of installed packages

Usually required for all other setups to work. Should work on a fresh installation.

## Explicitly installed native packages

- Installed through `pacman -S`
- Queried through `pacman -Qqen`
- Should be installed on a fresh system by `pacman -Syu --needed - < pkglist.txt`

## Foreign packages tracked by pacman

- Usually (and ideally exclusively) installed from the AUR
- Queried through `pacman -Qqem`
- May be required by native packages as dependencies
- Have to be installed manually and individually, through cloning and `makepkg -sirc`

## Running the hook

- Create a hook on the default pacman directory (seen on `/etc/pacman.conf`):

```bash
sudo mkdir -p /etc/pacman.d/hooks
sudo $EDITOR /etc/pacman.d/hooks/backup-packages.hook
```

- Write the hook:

```ini
[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Updating package backup lists...
When = PostTransaction
Exec = /usr/local/bin/update-package-list
```

- Copy `update-package-list` to `/usr/local/bin/update-package-list`
