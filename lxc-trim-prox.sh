#!/bin/bash
### ChainSavvy Trim Proxmox host volumes and all LXCs on node script ###
# Run as weekly cron job: 0 0 * * 3 /root/lxc-trim-prox.sh

LOGFILE="/var/log/lxc-trim.log"
FSTRIM=/sbin/fstrim
TRIMVOLS="/"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGFILE"
}

log "========================================="
log "TRIM JOB STARTED"
log "========================================="

## Trim all LXC containers ##
log "--- LXC CONTAINERS ---"
FAIL_COUNT=0
SUCCESS_COUNT=0

for i in $(/sbin/pct list | awk '/^[0-9]/ {print $1}'); do
  STATUS=$(/sbin/pct status "$i" 2>/dev/null | awk '{print $2}')
  if [ "$STATUS" = "running" ]; then
    OUTPUT=$(/sbin/pct fstrim "$i" 2>&1)
    if [ $? -eq 0 ]; then
      log "  Container $i: OK | $OUTPUT"
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      log "  Container $i: FAILED | $OUTPUT"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    log "  Container $i: SKIPPED (status: ${STATUS:-unknown})"
  fi
done

## Trim host volumes ##
log "--- HOST VOLUMES ---"
for i in $TRIMVOLS; do
  OUTPUT=$($FSTRIM -v "$i" 2>&1)
  if [ $? -eq 0 ]; then
    log "  $i: OK | $OUTPUT"
  else
    log "  $i: FAILED | $OUTPUT"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

log "--- SUMMARY ---"
log "  Successful: $SUCCESS_COUNT | Failed: $FAIL_COUNT"
log "TRIM JOB COMPLETED"
log ""
