#!/bin/bash

# --- CONFIGURATION ---
CONF_NAME="mikrotik-report.conf"
LOCAL_CONF="./$CONF_NAME"
ETC_CONF="/etc/$CONF_NAME"
LOGFILE="${1:-/var/log/mikrotik.log}"
DB="/var/lib/GeoIP/GeoLite2-City.mmdb"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
REPORT_TMP=$(mktemp)
LOADED=false

# 1. Check Precedence: Local, then /etc/
# -f checks if file exists; -r checks if it is readable
if [[ -f "$LOCAL_CONF" && -r "$LOCAL_CONF" ]]; then
	source "$LOCAL_CONF"
	LOADED=true
elif [[ -f "$ETC_CONF" && -r "$ETC_CONF" ]]; then
	source "$ETC_CONF"
	LOADED=true
fi

# 2. Exit if no config was found or readable
if [ "$LOADED" = false ]; then
	echo "Error: Configuration file '$CONF_NAME' not found or not readable in '.' or '/etc'." >&2
	exit 1
fi

# 3. Strict Variable Check
if [[ -z "$SENDER_EMAIL" || -z "$RECIPIENT_EMAIL" ]]; then
	echo "Error: SENDER_EMAIL or RECIPIENT_EMAIL is not defined in $CONF_NAME." >&2
	exit 1
fi

# --- LOGIC ---

# Generate raw data using Tabs for script logic
/usr/bin/sed -n '/BOMGAR/ s/.*TCP (SYN), \([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*:.*/\1.0/p' "$LOGFILE" | \
	/usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | \
	/usr/bin/awk '{print $2 "\t" $1}' > "$REPORT_TMP"

# Build the primary content
if [ -s "$REPORT_TMP" ]; then
	BODY="The following /24 Subnets attempted unpermitted access today:\n\n"
	
	HEADER_STR=$(printf "%-64.64s %s" "SUBNET/MASK (LOCATION/ORG)" "OCCURRENCES")
	BODY="${BODY}${HEADER_STR}\n"
	BODY="${BODY}----------------------------------------------------------------+-----------\n"
	
	while IFS=$'\t' read -r SUBNET COUNT; do
		IP_FOR_LOOKUP=$(echo "$SUBNET" | sed 's/\.0$/.1/')
		
		# GeoIP Lookup
		if [ -f "$DB" ]; then
			CITY=$(mmdblookup --file "$DB" --ip "$IP_FOR_LOOKUP" city names en 2>/dev/null | grep -m 1 'utf8_string' | cut -d '"' -f 2)
			STATE=$(mmdblookup --file "$DB" --ip "$IP_FOR_LOOKUP" subdivisions 0 iso_code 2>/dev/null | grep -m 1 'utf8_string' | cut -d '"' -f 2)
			COUNTRY=$(mmdblookup --file "$DB" --ip "$IP_FOR_LOOKUP" country iso_code 2>/dev/null | grep -m 1 'utf8_string' | cut -d '"' -f 2)

			if [ -n "$CITY" ]; then
				LOC="$CITY, $STATE, $COUNTRY"
			elif [ -n "$COUNTRY" ]; then
				# WHOIS fallback (skipping comments)
				ORG=$(whois "$IP_FOR_LOOKUP" | grep -v '^#' | grep -Ei "^\s*(OrgName|organization|descr|Registrant|Owner|Customer):" | head -n 1 | cut -d ':' -f 2- | xargs)
				
				if [ -n "$ORG" ]; then
					LOC="$COUNTRY - $ORG"
				else
					LOC="$COUNTRY"
				fi
			else
				LOC="Unknown Location"
			fi
		else
			LOC="GeoIP DB Not Found"
		fi
		
		LINE_DATA="${SUBNET}/24 (${LOC})"
		FORMATTED_LINE=$(printf "%-64.64s %s" "$LINE_DATA" "$COUNT")
		BODY="${BODY}${FORMATTED_LINE}\n"
	done < "$REPORT_TMP"
	
	SUBJECT="$(date --date yesterday +%F): Unpermitted Bomgar Access"
else
	BODY="No unpermitted IPs were detected today.\n"
	SUBJECT="$(date --date yesterday +%F): Unpermitted Bomgar Access - Clear"
fi

BODY="${BODY}\nReport Generated: ${TIMESTAMP}"

# Format as HTML Monospace
HTML_BODY="<html><body><pre style='font-family: monospace;'>$(echo -e "$BODY")</pre></body></html>"

# Send using variables from config
echo "$HTML_BODY" | /usr/bin/mailx -s "$SUBJECT" \
	-a "Content-Type: text/html" \
	-a "From: $SENDER_EMAIL" \
	"$RECIPIENT_EMAIL"

rm -f "$REPORT_TMP"
