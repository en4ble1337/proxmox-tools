# Proxmox Tools Repository

A comprehensive collection of scripts and configurations for optimizing Proxmox Virtual Environment (VE) installations. This repository provides essential tools for storage management, performance optimization, and system maintenance to help you get the most out of your Proxmox deployment.

## 📋 Table of Contents

1. [Features](#-features)
2. [Create RAID0 Storage Pool](#-create-raid0-storage-pool)
3. [Optimize Performance by Disabling Cluster Services](#-optimize-performance-by-disabling-cluster-services)
4. [Disable Access Time Updates (atime)](#-disable-access-time-updates-atime)
   - [For Non-ZFS Filesystems](#for-non-zfs-filesystems)
   - [For ZFS Filesystems](#for-zfs-filesystems)
5. [Proxmox VE Post-Installation Script](#️-proxmox-ve-post-installation-script)
6. [Automated LXC Container Maintenance](#-automated-lxc-container-maintenance)
7. [Quick Start Guide](#-quick-start-guide)
8. [Important Notes](#️-important-notes)
9. [Contributing](#-contributing)
10. [License](#-license)


## 🚀 Features

- **Storage Management**: Easy RAID0 setup with ZFS pools
- **Performance Optimization**: Cluster service management and filesystem tuning
- **System Maintenance**: Automated container cleanup and post-installation configuration
- **Enterprise-Ready**: Scripts tested for production environments

---

## 📦 Create RAID0 Storage Pool

Setting up a ZFS RAID0 configuration provides improved performance by striping data across multiple drives. This is ideal for scenarios where you need maximum throughput and can tolerate the loss of redundancy.

**Check available drives (minimum 2 required):**
```
lsblk
```

**Create the ZFS pool with optimal settings:**
```
zpool create -f -o ashift=12 <pool> <device1> <device2>
```

**Configure storage in Proxmox Web Interface:**
1. Navigate to **Data Center > Storage > Add > ZFS**
2. Select your newly created pool name
3. Enable **"Thin Provisioning"** for efficient space usage
4. Click **Add** to complete the setup

**📚 Reference Documentation:**  
https://pve.proxmox.com/wiki/ZFS_on_Linux

---

## ⚡ Optimize Performance by Disabling Cluster Services

For single-node Proxmox installations, cluster services consume unnecessary CPU and memory resources. Disabling these services can significantly improve system performance by reducing overhead.

**Benefits:**
- Lower CPU utilization
- Reduced memory consumption  
- Improved overall system responsiveness
- Elimination of unnecessary network traffic

```
systemctl disable -q --now pve-ha-lrm
systemctl disable -q --now pve-ha-crm
systemctl disable -q --now corosync
```

---

## 🔧 Disable Access Time Updates (atime)

Disabling atime updates prevents the filesystem from recording access timestamps, resulting in substantial performance improvements and reduced wear on storage devices.

**Performance Benefits:**
- Dramatically reduced disk I/O operations
- Extended SSD/HDD lifespan through fewer write cycles
- Lower CPU overhead from filesystem operations
- Improved overall system responsiveness

### For Non-ZFS Filesystems

**Check current mount options:**
```	
mount | grep "atime"
mount | grep ' / '
```

**Edit filesystem table:**
```
nano /etc/fstab
```

**Add noatime option to root filesystem:**
```
/dev/pve/root / ext4 errors=remount-ro,noatime 0 1
```

**Apply changes:**
```
systemctl daemon-reload
mount -o remount,noatime /
```

**Verify the configuration:**
```
mount | grep ' / '
```

### For ZFS Filesystems

**List all ZFS mountpoints:**
```
zfs list
```

**Disable atime for all mountpoints:**
```
zfs set atime=off rpool            
zfs set atime=off rpool/ROOT       
zfs set atime=off rpool/ROOT/pve-1 
zfs set atime=off rpool/data       
zfs set atime=off rpool/var-lib-vz 
```

**Verify changes (should show 'off' for all pools):**
```
zfs get atime
```

---

## 🛠️ Proxmox VE Post-Installation Script

This comprehensive script automates common post-installation tasks for Proxmox VE 8.x, including repository management, subscription handling, and system updates.

**Script Features:**
- Disable Enterprise Repository (requires paid subscription)
- Add/correct PVE community sources
- Enable No-Subscription Repository for free updates
- Add testing repository (optional)
- Remove subscription nag dialogs
- Perform system updates
- Handle system reboots

**Credits:** [Community Scripts Project](https://community-scripts.github.io/ProxmoxVE/)

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```

---

## 🧹 Automated LXC Container Maintenance

The TRIM feature enables efficient storage management by informing the underlying storage system which data blocks are no longer needed. This automated solution runs weekly to optimize LXC container storage.

**Key Benefits:**  
- Automatic reclamation of unused storage space
- Improved SSD performance and longevity
- Reduced storage fragmentation
- Zero-maintenance operation once configured

**Install and configure the automated TRIM cronjob:**
```
wget https://raw.githubusercontent.com/en4ble1337/proxmox-tools/main/lxc-trim-prox.sh && chmod 777 lxc-trim-prox.sh && (crontab -l ; echo "0 0 * * 3 /root/lxc-trim-prox.sh") | crontab -
```

**Verify the cronjob installation:**
```
crontab -l
```

**Remove the cronjob if needed:**
```
crontab -l | grep -v "/pathTo/File/lxc-trim-prox.sh" | crontab -
```

---

## 📋 Quick Start Guide

1. **Fresh Installation**: Run the post-installation script first
2. **Storage Setup**: Configure RAID0 if you have multiple drives
3. **Performance Tuning**: Disable cluster services and atime updates
4. **Maintenance**: Set up automated LXC container TRIM

## ⚠️ Important Notes

- Always backup your system before making configuration changes
- RAID0 provides no redundancy - ensure you have proper backups
- Test changes in a non-production environment first
- Some optimizations are irreversible without system reinstallation

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements or additional tools that would benefit the Proxmox community.

## 📄 License

This project is open source and available under standard open source licensing terms.

