# Proxmox VM/LXC Network Connectivity Issue

## Problem

After a power outage or an unclean shutdown, Virtual Machines (VMs) and LXC containers on Proxmox VE may lose their ability to access external networks, even if the Proxmox host itself (e.g., via its `vmbr0` interface) can communicate externally. Traffic originating from VMs/LXCs appears to be dropped at the Proxmox host's internal bridge.

## Root Cause

This issue is typically caused by the **IP forwarding** setting being disabled (`0`) on the Proxmox host. For virtualized environments like Proxmox, the host needs to be able to forward network packets between its virtual bridges (where VMs/LXCs are connected) and its physical network interfaces to allow external communication. A power outage can sometimes reset this setting.

## Solution

### 1\. Temporary Fix (Immediate Connectivity)

To immediately restore network connectivity for your VMs and LXC containers until the next reboot, execute the following command on your Proxmox VE host's console or via SSH:

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```

After running this, test connectivity from your VMs/LXCs. They should now be able to reach external networks.

### 2\. Permanent Fix (Survives Reboots)

To ensure IP forwarding remains enabled after system reboots, you need to modify the `sysctl` configuration file:

1.  **Open the `sysctl.conf` file** in your preferred text editor (e.g., `nano` or `vi`):

    ```bash
    nano /etc/sysctl.conf
    ```

2.  **Add or Uncomment the IP Forwarding Line:**

      * Look for a line that reads `#net.ipv4.ip_forward=1`. If you find it, remove the `#` (hash symbol) at the beginning of the line to uncomment it.

      * If the line doesn't exist, add the following line to the end of the file:

        ```
        net.ipv4.ip_forward=1
        ```

3.  **Save and Exit the Editor:**

      * If using `nano`: Press `Ctrl+X`, then `Y` to confirm saving, then `Enter`.
      * If using `vi`: Press `Esc`, then type `:wq` and press `Enter`.

4.  **Apply the Changes:**
    To load the new `sysctl` configuration without requiring a full system reboot, run:

    ```bash
    sysctl -p
    ```

After completing these steps, your Proxmox VE host will correctly forward network traffic for your VMs and LXC containers, and this configuration will persist across system reboots.
