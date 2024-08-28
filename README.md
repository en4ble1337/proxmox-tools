# Repository for Proxmox Tools

### Create raid0


**#check which drives you want to combine (min 2)<br/>**

```
lsblk
```

**#name the pool and pick your drives as device1-2<br/>**

```
create -f -o ashift=12 <pool> <device1> <device2>
```

**#go to data center > storage > add > zfs > pick new raid name <pool> > select "thin prvisioning" > add**

**#reference:**
https://pve.proxmox.com/wiki/ZFS_on_Linux

---

### Disable Cluster Services
Disabling cluster services in Proxmox VE can be beneficial in  lowering cpu and memory consumption which improves performance of the system (with unnecessary overhead).

```
systemctl disable -q --now pve-ha-lrm
systemctl disable -q --now pve-ha-crm
systemctl disable -q --now corosync
```


---

### Disable atime on both zfs and other systems:
Disabling atime (access time) updates on filesystems can provide several benefits, especially in environments like Proxmox where performance and efficiency are critical. </br>
- reduce disk i/o
- extending disk lifespan
- cpu overhead leading to higher performance

**#non zfs filesystem**
```	
mount | grep "atime"
mount | grep ' / '
```
**#access fstab and add noatime to pve root**

```
nano /etc/fstab
```
```
/dev/pve/root / ext4 errors=remount-ro,noatime 0 1
```
#reload services 

```
systemctl daemon-reload
mount -o remount,noatime /
```
#verify if applied

```
mount | grep ' / '
```

---
