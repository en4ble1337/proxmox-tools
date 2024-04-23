# proxmox-tools

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
