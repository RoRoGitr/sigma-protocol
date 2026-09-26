#!/usr/bin/env bash
# Install a local daily SigmaHQ refresh.
#
# macOS: creates ~/Library/LaunchAgents/com.sigmahq.daily-refresh.plist
# Linux: adds a crontab entry.

set -euo pipefail

HOUR=8
MINUTE=0
COMMANDBOARD="${SIGMAHQ_HOME:-$HOME/.commandboard}"
SYNC_SCRIPT="$COMMANDBOARD/sync-dashboard.sh"
LOG_DIR="$COMMANDBOARD/logs"
LOG_FILE="$LOG_DIR/daily-refresh.log"
LABEL="com.sigmahq.daily-refresh"

usage() {
  cat <<USAGE
Usage: ~/.commandboard/install-daily-refresh.sh [--time HH:MM] [--remove]

Examples:
  ~/.commandboard/install-daily-refresh.sh
  ~/.commandboard/install-daily-refresh.sh --time 08:00
  ~/.commandboard/install-daily-refresh.sh --remove
USAGE
}

REMOVE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --time)
      shift
      TIME_VALUE="${1:-}"
      if ! printf '%s' "$TIME_VALUE" | grep -Eq '^[0-2]?[0-9]:[0-5][0-9]$'; then
        echo "Invalid --time value. Use HH:MM, for example 08:00." >&2
        exit 1
      fi
      HOUR="${TIME_VALUE%%:*}"
      MINUTE="${TIME_VALUE#*:}"
      HOUR=$((10#$HOUR))
      MINUTE=$((10#$MINUTE))
      ;;
    --remove)
      REMOVE=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if [ ! -x "$SYNC_SCRIPT" ]; then
  echo "SigmaHQ sync script not found or not executable: $SYNC_SCRIPT" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

if [ "$(uname -s)" = "Darwin" ]; then
  AGENTS_DIR="$HOME/Library/LaunchAgents"
  PLIST="$AGENTS_DIR/$LABEL.plist"
  mkdir -p "$AGENTS_DIR"

  if [ "$REMOVE" -eq 1 ]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo "Removed SigmaHQ daily refresh LaunchAgent."
    exit 0
  fi

  cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SYNC_SCRIPT</string>
    <string>--no-open</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$HOUR</integer>
    <key>Minute</key>
    <integer>$MINUTE</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$LOG_FILE</string>
  <key>StandardErrorPath</key>
  <string>$LOG_FILE</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
PLIST

  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  echo "Installed SigmaHQ daily refresh at $(printf '%02d:%02d' "$HOUR" "$MINUTE") via launchd."
  echo "Log: $LOG_FILE"
  exit 0
fi

if [ "$REMOVE" -eq 1 ]; then
  (crontab -l 2>/dev/null | grep -v "$SYNC_SCRIPT --no-open") | crontab -
  echo "Removed SigmaHQ daily refresh cron entry."
  exit 0
fi

CRON_LINE="$MINUTE $HOUR * * * /bin/bash \"$SYNC_SCRIPT\" --no-open >> \"$LOG_FILE\" 2>&1 # SigmaHQ daily refresh"
(crontab -l 2>/dev/null | grep -v "$SYNC_SCRIPT --no-open"; echo "$CRON_LINE") | crontab -
echo "Installed SigmaHQ daily refresh at $(printf '%02d:%02d' "$HOUR" "$MINUTE") via cron."
echo "Log: $LOG_FILE"
