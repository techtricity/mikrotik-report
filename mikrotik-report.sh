#!/bin/bash

# --- CONFIGURATION ---
CONF_NAME="mikrotik-report.conf"
LOCAL_CONF="./$CONF_NAME"
ETC_CONF="/etc/$CONF_NAME"

# Order of Precedence: 1. Local Directory, 2. /etc/
if [ -f "$LOCAL_CONF" ]; then
	source "$LOCAL_CONF"
elif [ -f "$ETC_CONF" ]; then
	source "$ETC_CONF"
else
	echo "Error: Configuration file '$CONF_NAME' not found in . or /etc." >&2
	exit 1
fi

# Strict Variable Check
if [[ -z "$SENDER_EMAIL" || -z "$RECIPIENT_EMAIL" ]]; then
	echo "Error: SENDER_EMAIL or RECIPIENT_EMAIL is not defined in $CONF_NAME." >&2
	exit 1
fi

# Variables
LOGFILE="${1:-/var/log/mikrotik.log}"
DB="/var/lib/GeoIP/GeoLite2-City.mmdb"
TIMESTAMP=$(date +"%Y%m%d:%H:%M:%S")
REPORT_TMP=$(mktemp)

# --- LOGIC ---

# Generate raw data using Tabs for script logic
/usr/bin/sed -n '/BOMGAR/ s/.*TCP (SYN), \([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*:.*/\1.0/p' "$LOGFILE" | \
	/usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | \
	/usr/bin/awk '{print $2 "\t" $1}' > "$REPORT_TMP"

# 1. Build the primary content
if [ -s "$REPORT_TMP" ]; then
	BODY="The following /24 Subnets attempted unpermitted access today:\n\n"
	
	HEADER_STR=$(printf "%-64.64s %s" "SUBNET/MASK (LOCATION/ORG)" "OCCURRENCES")
	BODY="${BODY}${HEADER_STR}\n"
	BODY="${BODY}----------------------------------------------------------------------------\n"
	
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
	
	SUBJECT="$(date +%F): Unpermitted Bomgar Access"
else
	BODY="No unpermitted IPs were detected today.\n"
	SUBJECT="$(date +%F): Unpermitted Bomgar Access - Clear"
fi

BODY="${BODY}\nReport Generated: ${TIMESTAMP}"

# 2. Format as HTML Monospace
HTML_BODY="<html><body><pre style='font-family: monospace;'>$(echo -e "$BODY")</pre></body></html>"

# 3. Send using variables from config
echo "$HTML_BODY" | /usr/bin/mailx -s "$SUBJECT" \
	-a "Content-Type: text/html" \
	-a "From: $SENDER_EMAIL" \
	"$RECIPIENT_EMAIL"

rm -f "$REPORT_TMP"
