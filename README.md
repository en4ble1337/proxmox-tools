# Proxmox Tool Kit of usefull tricks
### Create raid0

```
#check which drives you want to combine (min 2)
lsblk zpool

#name the <pool> and pick your drives as <device1-2>
create -f -o ashift=12 <pool> <device1> <device2>
```

go to data center > storage > add > zfs > pick new raid > mark "thin" > create

reference:
https://pve.proxmox.com/wiki/ZFS_on_Linux


raid0 proxmox cli

sudo apt update
sudo apt install mdadm

mdadm --create /dev/md0 --level=stripe --raid-devices=2 /dev/sdX1 /dev/sdY1

mkfs.ext4 /dev/md0

mkdir /mnt/raid0
mount /dev/md0 /mnt/raid0

pvesm add dir raid0 --path /mnt/raid0


#unmounting raid

mdadm --detail --scan
mdadm --stop /dev/md/raid:0

mdadm --zero-superblock /dev/sdX1 

mdadm --zero-superblock /dev/sdY1
