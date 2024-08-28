### Chanisavvy Trim Proxmox host volumes and all LXCs on node script ###
# Run as weekly cron job
# !/bin/bash

# Path to FSTRIM
FSTRIM=/sbin/fstrim

# List of host volumes to trim separated by spaces
# eg TRIMVOLS="/mnt/a /mnt/b /mnt/c"
TRIMVOLS="/"

## Trim all LXC containers ##
echo "LXC CONTAINERS"
for i in $(/sbin/pct list | awk '/^[0-9]/ {print $1}'); do
  echo "Trimming Container $i"
  /sbin/pct fstrim $i 2>&1 | logger -t "pct fstrim [$$]"
done
echo ""

## Trim host volumes ##
echo "HOST VOLUMES"
for i in $TRIMVOLS; do
  echo "Trimming $i"
  $FSTRIM -v $i 2>&1 | logger -t "fstrim [$$]"
done
