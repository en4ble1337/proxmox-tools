# Creating Privileged LXC Container on Proxmox

This guide provides step-by-step instructions for creating and configuring a privileged LXC container on Proxmox with loop device access.

A privileged LXC container runs with elevated permissions similar to the host system, bypassing many of the security isolation features that normally separate containers from the underlying hardware and kernel. Unlike unprivileged containers that map user IDs for security, privileged containers have direct access to host resources and can perform operations typically restricted to the host system. The objective of this configuration is to enable the container to access loop devices and mount disk images or ISO files, which is commonly needed for applications that require direct block device manipulation or for running nested virtualization scenarios.

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
lxc.mount.entry: /dev/loop0 dev/loop0 none bind,optional,create=file
lxc.mount.entry: /dev/loop1 dev/loop1 none bind,optional,create=file
lxc.mount.entry: /dev/loop2 dev/loop2 none bind,optional,create=file
lxc.mount.entry: /dev/loop3 dev/loop3 none bind,optional,create=file
lxc.mount.entry: /dev/loop4 dev/loop4 none bind,optional,create=file
lxc.mount.entry: /dev/loop5 dev/loop5 none bind,optional,create=file
lxc.mount.entry: /dev/loop6 dev/loop6 none bind,optional,create=file
lxc.mount.entry: /dev/loop7 dev/loop7 none bind,optional,create=file
lxc.mount.entry: /dev/loop-control dev/loop-control none bind,optional,create=file
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

