# Mikrotik Firewall Bomgar Reporter

This script parses Mikrotik firewall logs for unpermitted access attempts (in this case specifically traffic keyed with the word BOMGAR), aggregates hits by /24 subnets, and performs GeoIP/WHOIS lookups to identify the source. Results then are sent out via the mail-x client.

## Features
* Subnet Aggregation: Consolidates individual IP hits into /24 blocks to reduce report noise.
* Dual-Layer Identification: Uses MaxMind GeoLite2 for geography and falls back to WHOIS to identify the Organization/ISP.
* Fail-Fast Configuration: The script will strictly exit with an error if the configuration file is missing, unreadable, or missing required variables.
* Monospaced HTML Email: Uses printf padding and HTML pre tags to ensure perfectly aligned columns in your inbox.

---

## Prerequisites (Ubuntu/Debian)

### 1. System Packages
Install the necessary tools for WHOIS lookups, GeoIP parsing, and email delivery:

    sudo apt update
    sudo apt install mailutils whois mmdb-bin sed awk -y

### 2. MaxMind GeoLite2 Database
The script requires the GeoLite2 City binary database.
1. Sign up for a free account at MaxMind.
2. Download the GeoLite2 City binary (.mmdb) file.
3. Move the file to the standard location:

    sudo mkdir -p /var/lib/GeoIP
    sudo mv GeoLite2-City.mmdb /var/lib/GeoIP/

---

## Installation

### 1. Configuration File
The script requires a configuration file named mikrotik-report.conf. It searches for this file in the following order:
1. Local Directory: ./mikrotik-report.conf (useful for development)
2. System Directory: /etc/mikrotik-report.conf (standard production location)

Create the file and add your details:

    SENDER_EMAIL="Firewall Report <firewall@yourdomain.com>"
    RECIPIENT_EMAIL="yourname@yourdomain.com"

### 2. Script Deployment
Move the script to your local bin and ensure it has execution permissions:

    sudo mv mikrotik-report.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/mikrotik-report.sh

---

## Automation (Logrotate)

To automate the report before your firewall logs are rotated, add a prerotate block to your logrotate configuration (e.g., /etc/logrotate.d/mikrotik):

    /var/log/mikrotik.log {
        daily
        rotate 31
        prerotate
            /usr/local/bin/mikrotik-report.sh "$1"
        endscript
    }

---

## Manual Usage

Run the script manually to test the configuration and verify the email output:

    sudo /usr/local/bin/mikrotik-report.sh

To test against a specific rotated log file:

    sudo /usr/local/bin/mikrotik-report.sh /var/log/mikrotik.log.1
