# Repo for Proxmox Tools

### Create raid0


**#check which drives you want to combine (min 2)<br/>**

```
lsblk
```

**#name the <pool> and pick your drives as <device1-2><br/>**

```
create -f -o ashift=12 <pool> <device1> <device2>
```

**#go to data center > storage > add > zfs > pick new raid name <pool> > select "thin prvisioning" > add**

**#reference:**
https://pve.proxmox.com/wiki/ZFS_on_Linux

---


