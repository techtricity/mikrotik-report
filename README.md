Markdown formatting can be a bit finicky, especially when nesting code blocks inside other code blocks or heredocs. GitHub's renderer is strict about how it handles backticks (```).

The issue likely stems from the "backtick escaping." In my previous example, I used backslashes to prevent the terminal from executing the script's code blocks, but GitHub sees those backslashes and gets confused.

Here is the **corrected `README.md` text** optimized specifically for GitHub's display. I've also updated the instructions to reflect the new "fail-fast" configuration logic.

### Method: Create the file manually

To ensure the formatting is perfect, I recommend creating the file directly on GitHub or via `nano README.md` and pasting the content below:

---

```markdown
# Mikrotik Firewall Bomgar Reporter

This script parses Mikrotik firewall logs for unpermitted access attempts (specifically targeting "BOMGAR" related traffic), aggregates hits by `/24` subnets, and performs GeoIP/WHOIS lookups.

## Features
* **Subnet Aggregation**: Consolidates hits into `/24` blocks.
* **Dual-Layer Identification**: Uses MaxMind GeoLite2 and WHOIS for Org/ISP identification.
* **Fail-Fast Configuration**: The script will strictly exit if the configuration file is missing or unreadable.
* **Monospaced HTML Email**: Ensures report columns stay perfectly aligned.

---

## Prerequisites (Ubuntu/Debian)

### 1. System Packages
```bash
sudo apt update
sudo apt install mailutils whois mmdb-bin sed awk -y

```

### 2. MaxMind GeoLite2 Database

The script expects the GeoLite2 City database at `/var/lib/GeoIP/GeoLite2-City.mmdb`.

1. Sign up for a free account at [MaxMind](https://www.maxmind.com/).
2. Download the **GeoLite2 City** binary (`.mmdb`) file.
3. Place it on your system:
```bash
sudo mkdir -p /var/lib/GeoIP
sudo mv GeoLite2-City.mmdb /var/lib/GeoIP/

```



---

## Installation

### 1. Configuration File

The script requires a file named `mikrotik-report.conf`. It searches in this order:

1. The local directory (`./mikrotik-report.conf`)
2. The system directory (`/etc/mikrotik-report.conf`)

**Required Content:**

```bash
SENDER_EMAIL="Techtricity Firewall Report <firewall@yourdomain.com>"
RECIPIENT_EMAIL="yourname@yourdomain.com"

```

### 2. Script Deployment

1. Move `mikrotik-report.sh` to `/usr/local/bin/`.
2. Ensure it is executable:
```bash
sudo chmod +x /usr/local/bin/mikrotik-report.sh

```



---

## Automation (Logrotate)

Integrate with your logrotate config (e.g., `/etc/logrotate.d/mikrotik`):

```text
/var/log/mikrotik.log {
    daily
    rotate 31
    prerotate
        /usr/local/bin/mikrotik-report.sh "$1"
    endscript
}

```

---

## Manual Usage

Run the script manually to test the configuration and output:

```bash
sudo /usr/local/bin/mikrotik-report.sh

```

```

---

