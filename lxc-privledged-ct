# Creating Privileged LXC Container on Proxmox

This guide provides step-by-step instructions for creating and configuring a privileged LXC container on Proxmox with loop device access.

## Prerequisites

- Proxmox VE server with root access
- Basic familiarity with Linux command line
- Container ID available (example uses 9996)

## Step 1: Configure GRUB for Loop Devices

First, modify the GRUB configuration to increase the maximum number of loop devices available to the system.

```bash
nano /etc/default/grub
```

Modify the `GRUB_CMDLINE_LINUX_DEFAULT` line to include the loop device parameter:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet max_loop=255"
```

Update GRUB and reboot the Proxmox host:

```bash
update-grub
reboot
```

## Step 2: Create LXC Container

Create your LXC container through the Proxmox web interface or CLI with your desired specifications. Note the container ID for the next step.

## Step 3: Configure Container Privileges

Edit the container configuration file to add privileged access and device permissions:

```bash
nano /etc/pve/lxc/9996.conf
```

Add the following configuration lines to enable privileged mode and device access:

```bash
lxc.apparmor.profile: unconfined
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
lxc.cgroup2.devices.allow: b 7:* rwm
lxc.cgroup2.devices.allow: c 10:237 rwm
lxc.mount.entry: /dev/loop0 dev/loop0 none bind,create=file 0 0
lxc.mount.entry: /dev/loop1 dev/loop1 none bind,create=file 0 0
lxc.mount.entry: /dev/loop2 dev/loop2 none bind,create=file 0 0
lxc.mount.entry: /dev/loop3 dev/loop3 none bind,create=file 0 0
lxc.mount.entry: /dev/loop4 dev/loop4 none bind,create=file 0 0
lxc.mount.entry: /dev/loop5 dev/loop5 none bind,create=file 0 0
lxc.mount.entry: /dev/loop6 dev/loop6 none bind,create=file 0 0
lxc.mount.entry: /dev/loop7 dev/loop7 none bind,create=file 0 0
lxc.mount.entry: /dev/loop8 dev/loop8 none bind,create=file 0 0
lxc.mount.entry: /dev/loop9 dev/loop9 none bind,create=file 0 0
lxc.mount.entry: /dev/loop10 dev/loop10 none bind,create=file 0 0
lxc.mount.entry: /dev/loop11 dev/loop11 none bind,create=file 0 0
lxc.mount.entry: /dev/loop12 dev/loop12 none bind,create=file 0 0
lxc.mount.entry: /dev/loop13 dev/loop13 none bind,create=file 0 0
lxc.mount.entry: /dev/loop14 dev/loop14 none bind,create=file 0 0
lxc.mount.entry: /dev/loop15 dev/loop15 none bind,create=file 0 0
lxc.mount.entry: /dev/loop16 dev/loop16 none bind,create=file 0 0
lxc.mount.entry: /dev/loop17 dev/loop17 none bind,create=file 0 0
lxc.mount.entry: /dev/loop18 dev/loop18 none bind,create=file 0 0
lxc.mount.entry: /dev/loop19 dev/loop19 none bind,create=file 0 0
lxc.mount.entry: /dev/loop20 dev/loop20 none bind,create=file 0 0
lxc.mount.entry: /dev/loop21 dev/loop21 none bind,create=file 0 0
lxc.mount.entry: /dev/loop22 dev/loop22 none bind,create=file 0 0
lxc.mount.entry: /dev/loop23 dev/loop23 none bind,create=file 0 0
lxc.mount.entry: /dev/loop24 dev/loop24 none bind,create=file 0 0
lxc.mount.entry: /dev/loop25 dev/loop25 none bind,create=file 0 0
lxc.mount.entry: /dev/loop26 dev/loop26 none bind,create=file 0 0
lxc.mount.entry: /dev/loop27 dev/loop27 none bind,create=file 0 0
lxc.mount.entry: /dev/loop28 dev/loop28 none bind,create=file 0 0
lxc.mount.entry: /dev/loop29 dev/loop29 none bind,create=file 0 0
lxc.mount.entry: /dev/loop30 dev/loop30 none bind,create=file 0 0
lxc.mount.entry: /dev/loop31 dev/loop31 none bind,create=file 0 0
lxc.mount.entry: /dev/loop32 dev/loop32 none bind,create=file 0 0
lxc.mount.entry: /dev/loop33 dev/loop33 none bind,create=file 0 0
lxc.mount.entry: /dev/loop34 dev/loop34 none bind,create=file 0 0
lxc.mount.entry: /dev/loop35 dev/loop35 none bind,create=file 0 0
lxc.mount.entry: /dev/loop36 dev/loop36 none bind,create=file 0 0
lxc.mount.entry: /dev/loop37 dev/loop37 none bind,create=file 0 0
lxc.mount.entry: /dev/loop38 dev/loop38 none bind,create=file 0 0
lxc.mount.entry: /dev/loop39 dev/loop39 none bind,create=file 0 0
lxc.mount.entry: /dev/loop40 dev/loop40 none bind,create=file 0 0
lxc.mount.entry: /dev/loop41 dev/loop41 none bind,create=file 0 0
lxc.mount.entry: /dev/loop42 dev/loop42 none bind,create=file 0 0
lxc.mount.entry: /dev/loop43 dev/loop43 none bind,create=file 0 0
lxc.mount.entry: /dev/loop44 dev/loop44 none bind,create=file 0 0
lxc.mount.entry: /dev/loop45 dev/loop45 none bind,create=file 0 0
lxc.mount.entry: /dev/loop46 dev/loop46 none bind,create=file 0 0
lxc.mount.entry: /dev/loop47 dev/loop47 none bind,create=file 0 0
lxc.mount.entry: /dev/loop48 dev/loop48 none bind,create=file 0 0
lxc.mount.entry: /dev/loop49 dev/loop49 none bind,create=file 0 0
lxc.mount.entry: /dev/loop50 dev/loop50 none bind,create=file 0 0
lxc.mount.entry: /dev/loop51 dev/loop51 none bind,create=file 0 0
lxc.mount.entry: /dev/loop52 dev/loop52 none bind,create=file 0 0
lxc.mount.entry: /dev/loop53 dev/loop53 none bind,create=file 0 0
lxc.mount.entry: /dev/loop54 dev/loop54 none bind,create=file 0 0
lxc.mount.entry: /dev/loop55 dev/loop55 none bind,create=file 0 0
lxc.mount.entry: /dev/loop56 dev/loop56 none bind,create=file 0 0
lxc.mount.entry: /dev/loop57 dev/loop57 none bind,create=file 0 0
lxc.mount.entry: /dev/loop58 dev/loop58 none bind,create=file 0 0
lxc.mount.entry: /dev/loop59 dev/loop59 none bind,create=file 0 0
lxc.mount.entry: /dev/loop60 dev/loop60 none bind,create=file 0 0
lxc.mount.entry: /dev/loop61 dev/loop61 none bind,create=file 0 0
lxc.mount.entry: /dev/loop62 dev/loop62 none bind,create=file 0 0
lxc.mount.entry: /dev/loop63 dev/loop63 none bind,create=file 0 0
lxc.mount.entry: /dev/loop64 dev/loop64 none bind,create=file 0 0
lxc.mount.entry: /dev/loop65 dev/loop65 none bind,create=file 0 0
lxc.mount.entry: /dev/loop66 dev/loop66 none bind,create=file 0 0
lxc.mount.entry: /dev/loop67 dev/loop67 none bind,create=file 0 0
lxc.mount.entry: /dev/loop68 dev/loop68 none bind,create=file 0 0
lxc.mount.entry: /dev/loop69 dev/loop69 none bind,create=file 0 0
lxc.mount.entry: /dev/loop70 dev/loop70 none bind,create=file 0 0
lxc.mount.entry: /dev/loop71 dev/loop71 none bind,create=file 0 0
lxc.mount.entry: /dev/loop72 dev/loop72 none bind,create=file 0 0
lxc.mount.entry: /dev/loop73 dev/loop73 none bind,create=file 0 0
lxc.mount.entry: /dev/loop74 dev/loop74 none bind,create=file 0 0
lxc.mount.entry: /dev/loop75 dev/loop75 none bind,create=file 0 0
lxc.mount.entry: /dev/loop76 dev/loop76 none bind,create=file 0 0
lxc.mount.entry: /dev/loop77 dev/loop77 none bind,create=file 0 0
lxc.mount.entry: /dev/loop78 dev/loop78 none bind,create=file 0 0
lxc.mount.entry: /dev/loop79 dev/loop79 none bind,create=file 0 0
lxc.mount.entry: /dev/loop80 dev/loop80 none bind,create=file 0 0
lxc.mount.entry: /dev/loop81 dev/loop81 none bind,create=file 0 0
lxc.mount.entry: /dev/loop82 dev/loop82 none bind,create=file 0 0
lxc.mount.entry: /dev/loop83 dev/loop83 none bind,create=file 0 0
lxc.mount.entry: /dev/loop84 dev/loop84 none bind,create=file 0 0
lxc.mount.entry: /dev/loop85 dev/loop85 none bind,create=file 0 0
lxc.mount.entry: /dev/loop86 dev/loop86 none bind,create=file 0 0
lxc.mount.entry: /dev/loop87 dev/loop87 none bind,create=file 0 0
lxc.mount.entry: /dev/loop88 dev/loop88 none bind,create=file 0 0
lxc.mount.entry: /dev/loop89 dev/loop89 none bind,create=file 0 0
lxc.mount.entry: /dev/loop90 dev/loop90 none bind,create=file 0 0
lxc.mount.entry: /dev/loop91 dev/loop91 none bind,create=file 0 0
lxc.mount.entry: /dev/loop92 dev/loop92 none bind,create=file 0 0
lxc.mount.entry: /dev/loop93 dev/loop93 none bind,create=file 0 0
lxc.mount.entry: /dev/loop94 dev/loop94 none bind,create=file 0 0
lxc.mount.entry: /dev/loop95 dev/loop95 none bind,create=file 0 0
lxc.mount.entry: /dev/loop96 dev/loop96 none bind,create=file 0 0
lxc.mount.entry: /dev/loop97 dev/loop97 none bind,create=file 0 0
lxc.mount.entry: /dev/loop98 dev/loop98 none bind,create=file 0 0
lxc.mount.entry: /dev/loop99 dev/loop99 none bind,create=file 0 0
lxc.mount.entry: /dev/loop100 dev/loop100 none bind,create=file 0 0
lxc.mount.entry: /dev/loop101 dev/loop101 none bind,create=file 0 0
lxc.mount.entry: /dev/loop102 dev/loop102 none bind,create=file 0 0
lxc.mount.entry: /dev/loop103 dev/loop103 none bind,create=file 0 0
lxc.mount.entry: /dev/loop104 dev/loop104 none bind,create=file 0 0
lxc.mount.entry: /dev/loop105 dev/loop105 none bind,create=file 0 0
lxc.mount.entry: /dev/loop106 dev/loop106 none bind,create=file 0 0
lxc.mount.entry: /dev/loop107 dev/loop107 none bind,create=file 0 0
lxc.mount.entry: /dev/loop108 dev/loop108 none bind,create=file 0 0
lxc.mount.entry: /dev/loop109 dev/loop109 none bind,create=file 0 0
lxc.mount.entry: /dev/loop110 dev/loop110 none bind,create=file 0 0
lxc.mount.entry: /dev/loop111 dev/loop111 none bind,create=file 0 0
lxc.mount.entry: /dev/loop112 dev/loop112 none bind,create=file 0 0
lxc.mount.entry: /dev/loop113 dev/loop113 none bind,create=file 0 0
lxc.mount.entry: /dev/loop114 dev/loop114 none bind,create=file 0 0
lxc.mount.entry: /dev/loop115 dev/loop115 none bind,create=file 0 0
lxc.mount.entry: /dev/loop116 dev/loop116 none bind,create=file 0 0
lxc.mount.entry: /dev/loop117 dev/loop117 none bind,create=file 0 0
lxc.mount.entry: /dev/loop118 dev/loop118 none bind,create=file 0 0
lxc.mount.entry: /dev/loop119 dev/loop119 none bind,create=file 0 0
lxc.mount.entry: /dev/loop120 dev/loop120 none bind,create=file 0 0
lxc.mount.entry: /dev/loop-control dev/loop-control none bind,create=file 0 0
```

### Configuration Explanation

- `lxc.apparmor.profile: unconfined` - Disables AppArmor restrictions
- `lxc.cgroup2.devices.allow: a` - Allows access to all devices
- `lxc.cap.drop:` - Removes capability restrictions (empty value keeps all capabilities)
- `lxc.cgroup2.devices.allow: b 7:* rwm` - Allows read/write/mknod access to loop block devices
- `lxc.cgroup2.devices.allow: c 10:237 rwm` - Allows access to loop control character device
- `lxc.mount.entry` lines - Bind mounts loop devices into container

## Step 4: Start Container

Start the container after saving the configuration:

```bash
pct start 9996
```

## Step 5: Verify Configuration

Enter the container and verify loop device access:

```bash
pct enter 9996
ls -la /dev/loop*
```

You should see the loop devices available within the container.

## Important Notes

- Replace `9996` with your actual container ID
- Privileged containers have elevated security risks
- This configuration provides extensive device access - use only when necessary
- Always backup container configurations before making changes
- Consider security implications in production environments

## Troubleshooting

If loop devices are not available after configuration:
- Verify the host has rebooted after GRUB changes
- Check that the container configuration was saved correctly
- Ensure the container was fully stopped before editing configuration
- Verify loop modules are loaded on the host: `lsmod | grep loop`

