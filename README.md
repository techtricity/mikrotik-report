# Mikrotik Firewall Bomgar Reporter

This script parses Mikrotik firewall logs for unpermitted access attempts (specifically targeting "BOMGAR" related traffic), aggregates hits by `/24` subnets, performs GeoIP and WHOIS lookups to identify the source, and sends a formatted monospaced HTML report.

## Features
* **Subnet Aggregation**: Consolidates individual IP hits into `/24` blocks to reduce report noise.
* **Dual-Layer Identification**: Uses MaxMind GeoLite2 for geographic data and falls back to WHOIS lookups to identify Organizations (ISPs/Data Centers).
* **Monospaced Formatting**: Uses `printf` padding and HTML `<pre>` tags to ensure perfectly aligned columns in email clients.
* **Fail-Fast Configuration**: Script exits safely if required configuration variables are missing.

---

## Prerequisites (Ubuntu/Debian)

The script requires a few standard packages and the MaxMind GeoIP database.

### 1. System Packages
```bash
sudo apt update
sudo apt install mailutils whois mmdb-bin sed awk -y
\`\`\`

### 2. MaxMind GeoLite2 Database
The script expects the GeoLite2 City database at `/var/lib/GeoIP/GeoLite2-City.mmdb`.
1. Sign up for a free account at [MaxMind](https://www.maxmind.com/).
2. Download the **GeoLite2 City** binary (\`.mmdb\`) file.
3. Place it on your system:
   \`\`\`bash
   sudo mkdir -p /var/lib/GeoIP
   sudo mv GeoLite2-City.mmdb /var/lib/GeoIP/
   \`\`\`

---

## Installation

### 1. Configure Emails
To keep your credentials out of version control, the script reads configuration from \`/etc/mikrotik-report.conf\`. Create this file:

\`\`\`bash
sudo nano /etc/mikrotik-report.conf
\`\`\`

**Add the following lines:**
\`\`\`bash
SENDER_EMAIL="Techtricity Firewall Report <firewall@yourdomain.com>"
RECIPIENT_EMAIL="yourname@yourdomain.com"
\`\`\`

### 2. Install the Script
1. Move \`mikrotik-report.sh\` to \`/usr/local/bin/\`.
2. Ensure it is executable:
   \`\`\`bash
   sudo chmod +x /usr/local/bin/mikrotik-report.sh
   \`\`\`

---

## Automation (Logrotate)

To run the report automatically before your logs are rotated, add it to your \`logrotate\` configuration (usually in \`/etc/logrotate.d/mikrotik\`):

\`\`\`text
/var/log/mikrotik.log {
    daily
    rotate 31
    prerotate
        /usr/local/bin/mikrotik-report.sh "$1"
    endscript
    postrotate
        [ -x /usr/lib/rsyslog/rsyslog-rotate ] && /usr/lib/rsyslog/rsyslog-rotate || true
    endscript
}
\`\`\`

---

## Manual Usage

You can run the script manually at any time to test the output:

\`\`\`bash
sudo /usr/local/bin/mikrotik-report.sh
\`\`\`
