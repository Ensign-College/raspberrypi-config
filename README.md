# Raspberry Pi Wi-Fi Configuration Tool

A friendly setup script that configures your Raspberry Pi to connect to your home Wi-Fi network automatically.

---

## Why Do I Need This?

Your Raspberry Pi comes pre-configured to connect to the TechLab's wireless network. This is great for working on campus, but what about when you want to continue your projects at home?

This script lets you add your home Wi-Fi credentials so your Pi can connect there too. You'll run it once while connected at the TechLab, and then your Pi will automatically connect to your home network whenever you plug it in there.

**The workflow:**

1. Connect to your Pi at the TechLab (like you normally do)
2. Run this script and enter your home Wi-Fi info
3. Take your Pi home and plug it in — it just works!

---

## Quick Start

### What You'll Need

- Your Raspberry Pi (connected to the TechLab network)
- SSH access to your Pi (like you normally use)
- Your home Wi-Fi network name (SSID)
- Your home Wi-Fi password
- A few minutes of your time

### Step 1: SSH Into Your Pi

From your laptop on the TechLab network, connect to your Pi like usual:

```bash
ssh pi@your-pi-hostname.local
# or
ssh pi@<your-pi-ip-address>
```

### Step 2: Download the Script

Run these commands to download the configuration script:

```bash
# Download the script and its checksum
curl -fsSL -O https://github.com/Ensign-College/raspberrypi-config/releases/download/v1.0.0-alpha1/config.sh
curl -fsSL -O https://github.com/Ensign-College/raspberrypi-config/releases/download/v1.0.0-alpha1/config.sh.sha256

# Verify the download (security check)
sha256sum -c config.sh.sha256

# Make it executable
chmod +x config.sh
```

You should see `config.sh: OK` after the verification step. If you see `FAILED`, try downloading again if it keeps failing, contact the TechLab support team immediately.

> [!CAUTION]
> Running scripts with `sudo` can affect your system. Make sure you trust the source and understand what the script does before proceeding.

### Step 3: Run the Script

```bash
sudo ./config.sh
```

Follow the prompts to enter your home Wi-Fi credentials.

### Step 4: Shut Down and Take Your Pi Home

Once configured, shut down your Pi safely:

```bash
sudo shutdown now
```

Take it home, plug it in, and it will automatically connect to your home network!

---

## Managing Your Networks

The script includes tools to manage your saved Wi-Fi networks:

```bash
# Add a new network (interactive setup)
sudo ./config.sh

# List all saved Wi-Fi networks
sudo ./config.sh --list

# Delete a saved network
sudo ./config.sh --delete

# Show help
sudo ./config.sh --help
```

### Already configured a network?

If you run the script for a network that's already saved, it will ask if you want to:

1. **Update** the password (useful if your home Wi-Fi password changed)
2. **Keep** the existing configuration

### Need to switch networks?

Use `--delete` to remove an old network, then run the script again to add a new one. Or just run the script — it will offer to update existing networks automatically.

---

## Understanding the Download Commands

_For curious students who want to know what they're running:_

| Command                         | What It Does                                                            |
| ------------------------------- | ----------------------------------------------------------------------- |
| `curl -fsSL -O <url>`           | Downloads a file from the internet                                      |
| `-f`                            | Fail silently on HTTP errors (don't save error pages)                   |
| `-s`                            | Silent mode (no progress bar)                                           |
| `-S`                            | Show errors if something goes wrong                                     |
| `-L`                            | Follow redirects (GitHub uses these)                                    |
| `-O`                            | Save with the original filename                                         |
| `sha256sum -c config.sh.sha256` | Verifies the file wasn't corrupted or tampered with                     |
| `chmod +x config.sh`            | Makes the script executable                                             |
| `sudo ./config.sh`              | Runs the script with admin privileges (needed to save network settings) |

### Why Verify the Checksum?

The `.sha256` file contains a cryptographic hash of the script. When you run `sha256sum -c`, it:

1. Calculates the hash of your downloaded `config.sh`
2. Compares it to the expected hash in `config.sh.sha256`
3. Tells you if they match

This protects you from running a corrupted or malicious file. It's good security hygiene, especially when downloading scripts from the internet that you'll run with `sudo`!

---

## Troubleshooting

### My Pi won't connect at home

| Issue                | Solution                                                                                                    |
| -------------------- | ----------------------------------------------------------------------------------------------------------- |
| Wrong password       | Run `sudo ./config.sh` again — it will offer to update the password                                         |
| 5GHz network         | The Pis we provide only support **2.4GHz** Wi-Fi. Check your router settings or connect to a 2.4GHz network |
| Out of range         | Move your Pi closer to your router                                                                          |
| Network not visible  | Make sure your router is broadcasting the SSID (not hidden)                                                 |
| Typo in network name | Use `sudo ./config.sh --delete` to remove it, then set up again                                             |

### How do I know if it's connected?

Once your Pi boots up, you can check the connection status:

```bash
# See your current connection
nmcli connection show --active

# Check your IP address
ip addr show wlan0

# See all saved networks
sudo ./config.sh --list
```

### Need to update your password?

Just run the script again with the same network name:

```bash
sudo ./config.sh
```

It will detect the existing network and ask if you want to update it.

### Want to remove a network?

```bash
sudo ./config.sh --delete
```

This shows you a numbered list of saved networks and lets you choose which one to remove.

### Still stuck?

Visit the TechLab during open hours — we're happy to help!

---

## For Curious Students 🔍

_Want to understand what's actually happening? Read on!_

### What This Script Does

When you run the script, it uses **NetworkManager** (the standard Linux network management tool) to save your Wi-Fi credentials securely. Here's the key command under the hood:

```bash
nmcli connection add type wifi con-name "NetworkName" \
    ifname wlan0 ssid "YourSSID" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "YourPassword"
```

Let's break that down:

| Part                        | What It Does                                                        |
| --------------------------- | ------------------------------------------------------------------- |
| `nmcli`                     | NetworkManager Command Line Interface — talks to the network daemon |
| `connection add`            | Creates a new saved network profile                                 |
| `type wifi`                 | Specifies this is a wireless connection                             |
| `con-name`                  | A friendly name for this connection profile                         |
| `ifname wlan0`              | The wireless interface (wlan0 is the default Wi-Fi adapter)         |
| `ssid`                      | The network name you're connecting to                               |
| `wifi-sec.key-mgmt wpa-psk` | Use WPA/WPA2 with a Pre-Shared Key (standard home Wi-Fi security)   |
| `wifi-sec.psk`              | Your actual Wi-Fi password                                          |

### Input Validation

The script validates your input before saving anything:

| Check                       | Why It Matters                                     |
| --------------------------- | -------------------------------------------------- |
| SSID ≤ 32 characters        | Wi-Fi standard maximum                             |
| Password 8-63 characters    | WPA2 requirement                                   |
| Control characters stripped | Prevents shell injection and weird behavior        |
| Existing network detection  | Avoids duplicate configs, offers to update instead |

This is defensive programming — the script doesn't trust user input blindly.

### Command-Line Arguments

The script uses a `case` statement to handle different modes:

```bash
case "${1:-}" in
    --help|-h) show_help ;;
    --list|-l) list_networks ;;
    --delete|-d) delete_network ;;
    "") ;;  # No argument = run setup
    *) echo "Unknown option" ;;
esac
```

The `${1:-}` syntax means "first argument, or empty string if none" — this prevents errors when no argument is provided (because of `set -u` strict mode).

### Where Are Credentials Stored?

NetworkManager stores connection profiles in `/etc/NetworkManager/system-connections/`. Each network gets its own file:

```bash
# List saved networks (requires sudo)
sudo ls /etc/NetworkManager/system-connections/

# View a connection's details (careful — shows passwords!)
sudo cat /etc/NetworkManager/system-connections/YourNetwork.nmconnection
```

The password is stored in these files, which is why they're only readable by root. On a personal device this is fine, but be aware of this if you're working with shared systems.

### Understanding the Script Structure

The script uses several shell scripting patterns worth knowing:

#### Strict Mode

```bash
set -euo pipefail
```

- `-e`: Exit immediately if any command fails
- `-u`: Treat unset variables as errors
- `-o pipefail`: Catch errors in piped commands

This makes scripts more reliable by failing fast rather than continuing with errors.

#### ANSI Color Codes

```bash
AMBER='\033[0;33m'
NC='\033[0m'  # No Color (reset)
```

These escape sequences tell the terminal to change text colors. The `\033[` is the escape sequence, followed by formatting codes.

#### Background Processes and Spinners

```bash
( some_commands ) &  # Run in background
spinner $!           # $! is the PID of the last background process
```

The script runs configuration in the background while showing an animated spinner — a common UX pattern in CLI tools.

### Useful NetworkManager Commands

Now that you understand the basics, here are commands to manage your networks:

```bash
# List all saved connections
nmcli connection show

# See available Wi-Fi networks
nmcli device wifi list

# Connect to a saved network
nmcli connection up "NetworkName"

# Disconnect from current network
nmcli connection down "NetworkName"

# Delete a saved network
nmcli connection delete "NetworkName"

# See detailed info about your Wi-Fi
nmcli device show wlan0
```

### The Bigger Picture: How Linux Networking Works

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Application                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    NetworkManager Daemon                     │
│  • Manages all network connections                          │
│  • Handles automatic reconnection                           │
│  • Stores credentials securely                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   wpa_supplicant                            │
│  • Handles WPA/WPA2 authentication                          │
│  • Manages the 4-way handshake with your router             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Kernel (Linux)                           │
│  • wifi driver (e.g., brcmfmac for Pi's built-in WiFi)     │
│  • Manages the actual hardware                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Hardware (wlan0)                         │
│  • Your Pi's Wi-Fi chip                                     │
│  • Sends/receives radio signals                             │
└─────────────────────────────────────────────────────────────┘
```

### Security Considerations

A few things to keep in mind:

1. **Passwords in plain text**: NetworkManager stores passwords readable by root. On multi-user systems, consider using 802.1X or other enterprise authentication.

2. **Script security**: The script reads your password into a variable. While running, this exists in memory. The script doesn't log it anywhere, but be aware of this in sensitive environments.

3. **WPA2 vs WPA3**: This script uses WPA-PSK (WPA2). If your router uses WPA3, you may need to adjust the `key-mgmt` parameter to `sae`.

### Want to Learn More?

- **NetworkManager documentation**: `man nmcli` or `man NetworkManager`
- **Linux networking**: The Arch Wiki has excellent articles on networking concepts
- **Shell scripting**: [Bash Guide](https://mywiki.wooledge.org/BashGuide) is a great resource
- **Raspberry Pi networking**: The official Raspberry Pi documentation covers hardware specifics

---

## Contributing

Found a bug or have an improvement? Talk to the TechLab team or submit a pull request!

## License

[MIT License](LICENSE) — use this however you'd like.

---

_Built with 🧡 by the Ensign College TechLab team_
