# Proxmox USB Backup Drive Setup Guide

A comprehensive guide to adding a USB drive as backup storage in Proxmox VE, including scheduling, retention policies, and troubleshooting.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Adding Storage to Proxmox](#adding-storage-to-proxmox)
- [Creating Backup Jobs](#creating-backup-jobs)
- [Schedule Examples](#schedule-examples)
- [Testing and Verification](#testing-and-verification)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Restoration Guide](#restoration-guide)

---

## Prerequisites

- Proxmox VE installed and running
- USB external drive connected to server
- Root SSH access to Proxmox host
- Basic knowledge of Linux command line

---

## Initial Setup

### Step 1: Identify Your USB Drive

Connect your USB drive and identify it:

```bash
# List all block devices
lsblk

# Check USB devices
lsusb

# View recent kernel messages
dmesg | tail -20
```

Look for your USB drive (usually `/dev/sdc`, `/dev/sdd`, etc.). In this guide, we'll use `/dev/sdd` as an example.

**⚠️ WARNING**: Make absolutely sure you've identified the correct drive. Formatting the wrong drive will result in data loss!

### Step 2: Format the Drive

```bash
# Wipe any existing filesystem signatures
wipefs -a /dev/sdd

# Create an ext4 filesystem with a label
mkfs.ext4 -F -L "proxmox-backup" /dev/sdd
```

**Output example:**
```
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 244190208 4k blocks and 61054976 inodes
Filesystem UUID: 12345678-1234-1234-1234-123456789abc
```

### Step 3: Get the Drive UUID

The UUID ensures the drive is always mounted correctly, even if the device letter changes:

```bash
blkid /dev/sdd
```

**Output example:**
```
/dev/sdd: UUID="12345678-1234-1234-1234-123456789abc" TYPE="ext4" LABEL="proxmox-backup"
```

**Copy the UUID value** (the part between quotes after `UUID=`). You'll need it in the next step.

### Step 4: Create Mount Point

```bash
# Create directory where the drive will be mounted
mkdir -p /mnt/usb-backup
```

### Step 5: Configure Automatic Mounting

Edit the fstab file to mount the drive automatically on boot:

```bash
nano /etc/fstab
```

Add this line at the bottom (replace `YOUR-UUID-HERE` with your actual UUID from Step 3):

```
UUID=YOUR-UUID-HERE /mnt/usb-backup ext4 defaults,nofail 0 2
```

**Important**: The `nofail` option ensures your server boots even if the USB drive is disconnected.

Save and exit: `Ctrl+X`, then `Y`, then `Enter`

### Step 6: Mount the Drive

```bash
# Mount all filesystems in fstab
mount -a

# Verify it's mounted
df -h | grep usb-backup
```

**Expected output:**
```
/dev/sdd        916G   28K  870G   1% /mnt/usb-backup
```

### Step 7: Create Directory Structure

```bash
# Create the dump directory for Proxmox backups
mkdir -p /mnt/usb-backup/dump

# Set correct permissions
chmod 755 /mnt/usb-backup
chmod 755 /mnt/usb-backup/dump

# Test write access
echo "test" > /mnt/usb-backup/test.txt
cat /mnt/usb-backup/test.txt
rm /mnt/usb-backup/test.txt
```

If you can create, read, and delete the test file, everything is working correctly.

---

## Adding Storage to Proxmox

### Method 1: Using Web UI (Recommended for Beginners)

1. **Log into Proxmox Web Interface**
2. Click **"Datacenter"** in the top left
3. Click **"Storage"** in the left panel
4. Click **"Add"** button → Select **"Directory"**
5. Fill in the form:
   - **ID**: `usb-backup` (or any name you prefer)
   - **Directory**: `/mnt/usb-backup`
   - **Content**: Check **"VZDump backup file"** ✓
   - **Enable**: Check ✓
   - **Shared**: Leave unchecked (unless you have a cluster)
   - **Nodes**: Select the node(s) where this storage should be available
6. Click **"Add"**

### Method 2: Using CLI (Faster)

```bash
# Add storage via command line
pvesm add dir usb-backup --path /mnt/usb-backup --content backup

# Verify it was added
pvesm status
```

**Expected output:**
```
Name            Type     Status           Total            Used       Available        %
...
usb-backup      dir      active      976762584        28672      927399520    0.00%
```

---

## Creating Backup Jobs

### Via Web UI

1. Go to **Datacenter** → **Backup**
2. Click **"Add"** to create a new backup job
3. Configure the **General** tab:
   - **Node**: Select `-- All --` (to backup VMs from all nodes) or specific node
   - **Storage**: Select **`usb-backup`**
   - **Schedule**: Configure your schedule (see examples below)
   - **Selection mode**: 
     - `All` - Backup all VMs automatically
     - `Include selected VMs` - Choose specific VMs
     - `Exclude selected VMs` - Backup all except selected
   - **Send email to**: (Optional) Your email for notifications
   - **Compression**: `ZSTD (fast and good)` (recommended)
   - **Mode**: `Snapshot` (for live backups)
   - **Enable**: Check ✓

4. Configure the **Retention** tab:
   - **Keep Last**: Number of most recent backups to keep
   - **Keep Hourly**: Number of hourly backups to keep
   - **Keep Daily**: Number of daily backups to keep
   - **Keep Weekly**: Number of weekly backups to keep
   - **Keep Monthly**: Number of monthly backups to keep
   - **Keep Yearly**: Number of yearly backups to keep

5. (Optional) **Note Template** tab: Add custom notes to backups
6. (Optional) **Advanced** tab: Configure performance settings
7. Click **"Create"**

### Via CLI

```bash
# Create a backup job that runs daily at 2 AM, keeps last 7 backups
pvesh create /cluster/backup --schedule '0 2 * * *' --storage usb-backup --mode snapshot --compress zstd --all 1 --enabled 1 --prune-backups 'keep-last=7'

# List all backup jobs
pvesh get /cluster/backup
```

---

## Schedule Examples

Proxmox uses cron format for scheduling: `minute hour day month weekday`

### Common Schedules

| Description | Cron Format | When It Runs |
|------------|-------------|--------------|
| Every day at 2:00 AM | `0 2 * * *` | Daily at 2 AM |
| Every Sunday at 3:00 AM | `0 3 * * 0` | Weekly |
| Every Monday at 1:00 AM | `0 1 * * 1` | Weekly |
| 1st day of month at 2:00 AM | `0 2 1 * *` | Monthly |
| 15th day of month at 3:00 AM | `0 3 15 * *` | Monthly |
| Every 6 hours | `0 */6 * * *` | 4 times daily |
| Every 12 hours | `0 */12 * * *` | Twice daily |
| Mon-Fri at 11:00 PM | `0 23 * * 1-5` | Weekdays only |
| Sat-Sun at 1:00 AM | `0 1 * * 6-7` | Weekends only |

### Retention Policy Examples

#### Example 1: Simple - Keep Last 7 Backups
Perfect for daily backups where you want one week of history:
- **Keep Last**: `7`
- All other fields: `0` or empty

#### Example 2: Monthly - Keep Last 2
Perfect for monthly backups where space is limited:
- **Keep Last**: `2`
- All other fields: `0` or empty

#### Example 3: Comprehensive Retention
Daily backups with long-term retention:
- **Keep Last**: `3` (last 3 backups regardless of age)
- **Keep Daily**: `7` (one backup per day for 7 days)
- **Keep Weekly**: `4` (one backup per week for 4 weeks)
- **Keep Monthly**: `6` (one backup per month for 6 months)
- **Keep Yearly**: `2` (one backup per year for 2 years)

#### Example 4: Aggressive Space Management
For limited storage, keep minimal backups:
- **Keep Last**: `2`
- **Keep Daily**: `3`
- **Keep Weekly**: `2`
- All others: `0`

---

## Testing and Verification

### Test the Backup Job Immediately

Don't wait for the scheduled time - test it now:

#### Via Web UI:
1. Go to **Datacenter** → **Backup**
2. Select your backup job
3. Click **"Run now"**
4. Watch the task log for completion

#### Via CLI:
```bash
# Find your backup job ID
pvesh get /cluster/backup

# Run the backup job (replace 'backup-xxxx' with your job ID)
vzdump --all 1 --compress zstd --mode snapshot --storage usb-backup

# Watch backup progress
tail -f /var/log/pve/tasks/*/vzdump*
```

### Verify Backup Files

```bash
# List backup files
ls -lh /mnt/usb-backup/dump/

# Check backup file details
vzdump --info /mnt/usb-backup/dump/vzdump-qemu-*.vma.zst
```

**Expected output:**
```
-rw-r--r-- 1 root root 2.5G Nov  4 14:23 vzdump-qemu-100-2025_11_04-14_23_01.vma.zst
-rw-r--r-- 1 root root  150 Nov  4 14:23 vzdump-qemu-100-2025_11_04-14_23_01.log
```

### Check Storage Status

```bash
# Check storage status and usage
pvesm status

# Check specific storage
pvesm status --storage usb-backup
```

### Monitor Backup Logs

```bash
# View recent backup logs
cat /var/log/pve/tasks/*/vzdump* | tail -50

# Or use Proxmox web interface:
# Node → System → Syslog
# Or: Datacenter → Backup → Select job → Show
```

---

## Troubleshooting

### Issue 1: "Parameter verification failed - path: invalid format"

**Cause**: Directory doesn't exist or isn't mounted

**Solution**:
```bash
# Check if directory exists
ls -la /mnt/usb-backup

# Check if drive is mounted
df -h | grep usb-backup

# If not mounted, mount it
mount -a
```

---

### Issue 2: "mkdir /mnt/usb-backup/dump: Input/output error"

**Cause**: Filesystem corruption or drive disconnected

**Solution**:
```bash
# Check if drive is still connected
lsblk | grep sd

# Check for errors in kernel log
dmesg | tail -50 | grep -i error

# If you see "attempt to access beyond end of device", unmount and fix:
umount /mnt/usb-backup

# Check and repair filesystem
e2fsck -f -y /dev/sdd

# Remount
mount -a

# If fsck fails, reformat (THIS ERASES DATA):
wipefs -a /dev/sdd
mkfs.ext4 -F -L "proxmox-backup" /dev/sdd
mount -a
mkdir -p /mnt/usb-backup/dump
```

---

### Issue 3: Drive Letter Changes (sdc → sdd)

**Cause**: USB drive reconnected and kernel assigned different letter

**Why this isn't a problem**: Using UUID in fstab automatically handles this

**To verify**:
```bash
# Check current mount
df -h | grep usb-backup

# Should still be mounted correctly even if device letter changed
```

**If not mounted**:
```bash
# Check which device has your UUID
blkid | grep proxmox-backup

# Mount using fstab
mount -a
```

---

### Issue 4: "Storage 'usb-backup' is not online"

**Cause**: Drive not mounted or storage not activated

**Solution**:
```bash
# Check mount status
df -h | grep usb-backup

# If not mounted
mount -a

# Reactivate storage in Proxmox
pvesm set usb-backup --disable 0

# Check storage status
pvesm status
```

---

### Issue 5: Backup Job Fails with "no space left on device"

**Cause**: USB drive is full

**Solution**:
```bash
# Check disk usage
df -h /mnt/usb-backup

# List backups by size
ls -lhS /mnt/usb-backup/dump/

# Manually delete old backups (be careful!)
rm /mnt/usb-backup/dump/vzdump-qemu-*-2024_*.vma.zst

# Or adjust retention policy to keep fewer backups
```

---

### Issue 6: USB Drive Keeps Disconnecting

**Possible causes and solutions**:

1. **Power issue** - External drives may need their own power supply
   ```bash
   # Check for power-related errors
   dmesg | grep -i "power\|suspend"
   ```
   
2. **Bad USB port** - Try different USB port (preferably USB 3.0)

3. **Bad cable** - Replace USB cable

4. **USB auto-suspend** - Disable USB auto-suspend:
   ```bash
   # Edit GRUB config
   nano /etc/default/grub
   
   # Find line: GRUB_CMDLINE_LINUX_DEFAULT="quiet"
   # Change to: GRUB_CMDLINE_LINUX_DEFAULT="quiet usbcore.autosuspend=-1"
   
   # Update GRUB
   update-grub
   
   # Reboot
   reboot
   ```

5. **Failing drive** - Run SMART test:
   ```bash
   # Install smartmontools if not present
   apt install smartmontools
   
   # Check drive health
   smartctl -a /dev/sdd
   
   # Look for "SMART overall-health self-assessment test result: PASSED"
   ```

---

### Issue 7: Backup is Very Slow

**Causes and solutions**:

1. **USB 2.0 vs USB 3.0** - Check USB version:
   ```bash
   lsusb -t
   # Look for "5000M" (USB 3.0) vs "480M" (USB 2.0)
   ```

2. **Compression overhead** - Try different compression:
   - Edit backup job → Change Compression to `LZO (fast)` instead of `ZSTD`

3. **Multiple VMs backing up simultaneously** - Adjust backup job to run VMs sequentially

4. **Drive fragmentation** - Not usually an issue with ext4, but can reformat if persistent

---

### Issue 8: Cannot Restore from Backup

**Solution**:
```bash
# List available backups
ls -lh /mnt/usb-backup/dump/

# Test backup integrity
vzdump --info /mnt/usb-backup/dump/vzdump-qemu-100-*.vma.zst

# If corrupted, check if there's a .log file with errors
cat /mnt/usb-backup/dump/vzdump-qemu-100-*.log
```

---

## Best Practices

### 1. **Test Your Backups Regularly**

**The only backup that matters is one you can restore from.**

```bash
# Test restore to a new VM ID
qmrestore /mnt/usb-backup/dump/vzdump-qemu-100-*.vma.zst 999 --storage local-lvm

# Or via Web UI:
# Storage → usb-backup → Backups → Select backup → Restore
```

### 2. **Follow the 3-2-1 Backup Rule**

- **3** copies of your data
- **2** different media types
- **1** copy offsite

**USB drive should be ONE of your backup locations, not the only one.**

### 3. **Monitor Backup Jobs**

Set up email notifications:
- Edit backup job → **Send email to**: `your-email@example.com`
- Configure mail relay in Proxmox if not already done

### 4. **Document Your Retention Policy**

Create a comment in your backup job explaining your retention strategy:
```
Daily backups at 2 AM
Keep: Last 3, Daily 7, Weekly 4, Monthly 6
Estimated storage: ~500GB for 10 VMs
```

### 5. **Secure Your Backup Drive**

```bash
# If storing sensitive data, consider encryption
# (Advanced - requires LUKS setup, beyond scope of this guide)

# At minimum, set proper permissions
chmod 700 /mnt/usb-backup
```

### 6. **Label Your Physical Drive**

Put a physical label on the USB drive:
```
PROXMOX BACKUP - usb-backup
Server: pve-lab1
Created: 2025-11-04
```

### 7. **Regular Health Checks**

Schedule a monthly reminder to check:
```bash
# Drive health
smartctl -H /dev/sdd

# Storage usage
df -h /mnt/usb-backup

# Recent backup logs
ls -lt /mnt/usb-backup/dump/ | head -10

# Check for filesystem errors
dmesg | grep sdd | grep -i error
```

### 8. **Rotation Strategy for Multiple Drives**

For critical systems, use multiple USB drives in rotation:
- **Week 1**: Use Drive A
- **Week 2**: Use Drive B, store Drive A offsite
- **Week 3**: Use Drive A, store Drive B offsite
- Repeat

---

## Restoration Guide

### Restore a VM from Backup

#### Method 1: Web UI (Easiest)

1. Go to **Storage** → **usb-backup** → **Backups**
2. Select the backup file
3. Click **"Restore"**
4. Configure:
   - **VM ID**: Use original ID or enter new ID
   - **Storage**: Select storage location
   - **Unique**: Check to generate new MAC addresses
   - **Start after restore**: Optional
5. Click **"Restore"**

#### Method 2: CLI

```bash
# List available backups
ls /mnt/usb-backup/dump/

# Restore to original VM ID (will overwrite existing VM!)
qmrestore /mnt/usb-backup/dump/vzdump-qemu-100-2025_11_04-14_23_01.vma.zst 100

# Restore to NEW VM ID (safer for testing)
qmrestore /mnt/usb-backup/dump/vzdump-qemu-100-2025_11_04-14_23_01.vma.zst 999 --storage local-lvm

# For containers (CT)
pct restore 100 /mnt/usb-backup/dump/vzdump-lxc-100-*.tar.zst
```

### Restore Individual Files from VM Backup

```bash
# Mount the backup as a loop device (advanced)
# This requires extracting the VMA archive first

# Easier method: Restore entire VM to temporary ID, boot it, copy files, then delete it
```

---

## Maintenance Checklist

### Daily
- [ ] Check that backup job completed successfully (automated email)

### Weekly
- [ ] Review backup logs for errors
- [ ] Verify backup file sizes are reasonable
- [ ] Check storage space usage

### Monthly
- [ ] Test restore from backup
- [ ] Check USB drive health with `smartctl`
- [ ] Verify oldest backup matches retention policy
- [ ] Review and adjust retention if needed

### Quarterly
- [ ] Full restore test to new VM
- [ ] Check physical drive for damage
- [ ] Update documentation if configuration changed
- [ ] Consider rotating to fresh USB drive if >2 years old

---

## Quick Reference Commands

```bash
# Check drive status
lsblk
df -h | grep usb-backup
pvesm status

# Check for errors
dmesg | grep sdd | tail -20
smartctl -H /dev/sdd

# Mount/unmount
mount -a
umount /mnt/usb-backup

# List backups
ls -lh /mnt/usb-backup/dump/

# Manual backup (all VMs)
vzdump --all 1 --compress zstd --mode snapshot --storage usb-backup

# Manual backup (specific VM)
vzdump 100 --compress zstd --mode snapshot --storage usb-backup

# Check backup integrity
vzdump --info /mnt/usb-backup/dump/vzdump-qemu-100-*.vma.zst

# Restore VM
qmrestore /mnt/usb-backup/dump/vzdump-qemu-100-*.vma.zst 100

# Remove storage from Proxmox
pvesm remove usb-backup
```

---

## Appendix: Cron Schedule Format

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, both 0 and 7 are Sunday)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)

Special characters:
* = any value
, = list (e.g., 1,3,5)
- = range (e.g., 1-5)
/ = step (e.g., */2 = every 2)
```

---

## Support and Resources

- **Proxmox Official Documentation**: https://pve.proxmox.com/pve-docs/
- **Proxmox Forum**: https://forum.proxmox.com/
- **Backup Documentation**: https://pve.proxmox.com/wiki/Backup_and_Restore

---

## License

This guide is provided as-is for educational purposes. Always test in a non-production environment first.

## Contributing

Found an issue or have suggestions? Please open an issue or submit a pull request.

---

**Last Updated**: November 2025  
**Tested On**: Proxmox VE 8.x
