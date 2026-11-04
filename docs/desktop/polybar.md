# Polybar Installation and Configuration

This document outlines the steps taken to install and configure Polybar on this system.

## Installation

Polybar was installed using the `apt` package manager:

```bash
sudo apt install polybar
```

## Configuration

The Polybar configuration files are located in the `polybar` directory within this `ledot` repository.

### 1. Directory and Configuration File

A `polybar` directory was created in the root of the `ledot` repository. The default Polybar configuration was copied to `polybar/config`.

### 2. Launch Script

A launch script, `polybar/launch.sh`, was created to handle starting and stopping Polybar instances. The script is as follows:

```bash
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/ledot/polybar/config
polybar mybar &

echo "Polybar launched..."
```

The script was made executable with `chmod +x polybar/launch.sh`.

### 3. i3 Configuration

The i3 configuration file, located at `i3/config`, was modified to launch Polybar on startup. The default `i3bar` was disabled and the following line was added:

```
exec_always --no-startup-id ~/ledot/polybar/launch.sh
```

### 4. Symbolic Link

To ensure Polybar can find its configuration, a symbolic link was created from `~/.config/polybar` to the `polybar` directory in this repository:

```bash
ln -s /home/fernando/ledot/polybar ~/.config/polybar
```

### 5. Polybar Configuration

The `polybar/config` file was updated with a self-contained configuration and modified to work with i3. The bar name was set to `mybar` to match the launch script, and `wm-restack = i3` was enabled.
