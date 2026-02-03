# RTX 5090 GPU Passthrough on Proxmox 9.0 - Complete Guide

> **Tested Configuration**: RTX 5090 (32GB) on Proxmox VE 9.0 with Ubuntu 22.04 VM

## Table of Contents
- [Prerequisites](#prerequisites)
- [BIOS Settings](#bios-settings)
- [Host Configuration](#host-configuration)
- [Proxmox System Configuration](#proxmox-system-configuration)
- [VM Configuration Notes](#vm-configuration-notes)
- [Verification and Testing](#verification-and-testing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements
- **Motherboard**: Must support IOMMU/VT-d (Intel) or AMD-Vi (AMD)
- **CPU**: Intel VT-d or AMD-Vi enabled processor
- **GPU**: NVIDIA RTX 5090
- **Additional GPU**: Recommended for host display (iGPU or secondary GPU)

### Software Requirements
- **Proxmox VE**: 9.0 or later
- **Guest OS**: Ubuntu 22.04 LTS
- **NVIDIA Drivers**: 570+ series for RTX 5090 support

## BIOS Settings

### Critical BIOS Configuration
Access your system BIOS/UEFI and configure the following. These settings enable hardware virtualization features required for GPU passthrough and large memory addressing:

```
[REQUIRED SETTINGS]
✅ IOMMU/VT-d/AMD-Vi: ENABLED
✅ Above 4G Decoding: ENABLED  
✅ Resizable BAR: DISABLED (initially)
✅ CSM (Compatibility Support Module): DISABLED
✅ Secure Boot: DISABLED
✅ SR-IOV: ENABLED (if available)

[OPTIONAL SETTINGS]
⚡ CPU Virtualization: ENABLED
⚡ IOMMU Pass-through: ENABLED
⚡ PCIe Speed: Gen4/Gen5 (maximum supported)
```

> **⚠️ Important**: Above 4G Decoding is **critical** for RTX 5090's 32GB VRAM support

## Host Configuration

### 1. Update Proxmox System
Ensures you have the latest kernel and security patches that may improve VFIO compatibility and system stability.

```bash
apt update && apt upgrade -y
```

### 2. Configure GRUB Bootloader
Configures the bootloader to enable IOMMU and other virtualization features at kernel boot time.

#### For Intel Systems:
```bash
nano /etc/default/grub
```

Edit the GRUB_CMDLINE_LINUX_DEFAULT line:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
```

#### For AMD Systems:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
```

**Update GRUB:** Applies the bootloader configuration changes so they take effect on next reboot.
```bash
update-grub
```

### 3. Configure Kernel Modules
Loads the VFIO drivers at boot time, which are essential for PCI device passthrough functionality.

```bash
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
```

### 4. Identify RTX 5090 PCI IDs
Finds the unique hardware identifiers for your GPU that will be used to bind it to the VFIO driver.

```bash
lspci -nn | grep NVIDIA
```

Expected output:
```
c1:00.0 VGA compatible controller [0300]: NVIDIA Corporation GB202 [GeForce RTX 5090] [10de:2b85] (rev a1)
c1:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22e8] (rev a1)
```

Note your PCI IDs (10de:2b85 and 10de:22e8 in this example).

### 5. Configure VFIO Device Binding - ONLY to used with VM - LXC do not configure.
Tells the VFIO driver to claim ownership of your specific GPU hardware instead of the default graphics drivers.

```bash
echo "options vfio-pci ids=10de:2b85,10de:22e8" > /etc/modprobe.d/vfio.conf
```

> **📝 Note**: Replace `10de:2b85,10de:22e8` with your actual RTX 5090 PCI IDs

### 6. Blacklist GPU Drivers
Prevents the host system from loading GPU drivers that would conflict with VFIO passthrough. VM only.

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia_drm" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia_modeset" >> /etc/modprobe.d/blacklist.conf
```
LXC
```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
```

### 7. Additional VFIO Options (For Stability)
Enables workarounds for systems with interrupt sharing issues and allows VMs to access certain CPU features safely.

```bash
echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
```

### 8. Update Initramfs and Reboot
Rebuilds the initial RAM filesystem to include all the new module configurations and applies all changes.

```bash
update-initramfs -u
reboot
```

## Proxmox System Configuration

### 1. Verify IOMMU is Working
Confirms that hardware virtualization is properly enabled and functioning at the kernel level.

```bash
dmesg | grep -e DMAR -e IOMMU -e AMD-Vi
```

Expected output should include: `IOMMU enabled`

### 2. Verify GPU is Bound to VFIO
Ensures the GPU is successfully claimed by the VFIO driver and ready for passthrough to VMs.

```bash
lspci -nnk -s c1:00
```

Expected output:
```
c1:00.0 VGA compatible controller: NVIDIA Corporation GB202 [GeForce RTX 5090]
	Kernel driver in use: vfio-pci
c1:00.1 Audio device: NVIDIA Corporation Device
	Kernel driver in use: vfio-pci
```

### 3. Check IOMMU Groups
Verifies that devices are properly isolated in IOMMU groups for secure passthrough without conflicts.

```bash
find /sys/kernel/iommu_groups/ -type l | sort -V
```

Ensure RTX 5090 is in an isolated group or properly separated.

## VM Configuration Notes

### Essential VM Settings for RTX 5090 Passthrough:

**System Configuration:**
```
Machine: q35
BIOS: SeaBIOS (Default)
SCSI Controller: VirtIO SCSI single
Qemu Agent: Yes
```

**GPU Passthrough Configuration:**
```
PCI Device Settings:
✅ All Functions: ENABLED
✅ ROM-Bar: ENABLED  
✅ PCIe: ENABLED
✅ Primary GPU: ENABLED (if using as main display)
```

**Via Command Line:**
```bash
# Example for VM ID 100
qm set 100 -hostpci0 c1:00,pcie=1,rombar=1,x-vga=1
```

**Additional Optimizations:**
```bash
# Disable tablet pointer for better performance
qm set 100 -tablet 0

# Set CPU topology (adjust cores as needed)
qm set 100 -cpu host -cores 8

# Disable memory ballooning
qm set 100 -balloon 0
```

> **📝 Note**: With SeaBIOS and ROM-bar enabled, the configuration is more compatible with various guest operating systems while maintaining good performance.

For detailed NVIDIA driver installation instructions specific to RTX 5090 on Ubuntu 22.04, please follow this comprehensive guide:

**📋 [RTX 5090 Ubuntu 22.04 Driver Installation Guide](https://github.com/en4ble1337/ai-linux-tools/blob/main/ubuntu22.04-5090.md)**

## Verification and Testing

### 1. Verify RTX 5090 Recognition
Confirms the GPU is properly detected and functioning with full memory access after driver installation.

```bash
# Check NVIDIA driver status (after driver installation)
nvidia-smi
```

Expected output:
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 570.xx.xx    Driver Version: 570.xx.xx    CUDA Version: 12.4  |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce RTX 5090    Off  | 00000000:06:00.0  On |                  N/A |
| 30%   35C    P8    28W / 600W |   1024MiB / 32768MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
```

### 2. Test PCI Passthrough
Verifies the GPU hardware is accessible to the guest operating system through PCI passthrough.

```bash
# Check PCI passthrough in guest
lspci | grep NVIDIA

# Verify GPU is accessible
ls /dev/nvidia*
```

### 3. Performance Testing
Runs benchmarks to ensure the GPU is performing at expected levels with full hardware acceleration.

```bash
# Install GPU benchmarking tools
sudo apt install glmark2

# Run GPU benchmark
glmark2

# Monitor GPU performance
watch -n 1 nvidia-smi
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: VM Won't Start - "QEMU exited with code 1"
**Solution:** Verifies that all prerequisite steps were completed correctly.
```bash
# Check if GPU is bound to VFIO
lspci -nnk -s c1:00

# Verify IOMMU is enabled
dmesg | grep -i iommu

# Check VM configuration
qm config 100 | grep hostpci
```

#### Issue: GPU Not Detected in Guest
**Solution:** Ensures the PCI device passthrough is working and the VM can see the hardware.
```bash
# Check PCI passthrough in guest
lspci | grep NVIDIA

# Verify VFIO binding on host
lspci -nnk -s c1:00.0

# Ensure PCI device is properly configured
qm config 100 | grep hostpci
```

#### Issue: Display Issues After Driver Installation
**Solution:** Addresses common display configuration problems specific to RTX 5090.
- Follow the detailed troubleshooting steps in the [RTX 5090 Driver Guide](https://github.com/en4ble1337/ai-linux-tools/blob/main/ubuntu22.04-5090.md)
- Check X11 configuration
- Verify display manager settings

#### Issue: Host Freeze During Passthrough
**Solutions:** Adds additional kernel parameters to improve system stability during GPU operations.
```bash
# Add GRUB parameters for stability
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction video=efifb:off pci=noaer"

# Update initramfs
update-initramfs -u
```

### Debug Commands

**Check system logs:** Reviews system messages to identify any errors or issues with the passthrough setup.
```bash
# View VM startup logs
journalctl -f -u qemu-server@100.service

# Check kernel messages
dmesg | grep -i vfio
dmesg | grep -i nvidia

# Monitor system resources
htop
```

**IOMMU verification:** Displays detailed information about IOMMU groups and device assignments.
```bash
# Check IOMMU groups
for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done
```

## Performance Optimization Tips

### 1. CPU Configuration
Optimizes CPU settings for better VM performance and reduces virtualization overhead.

```bash
# Enable CPU host features
qm set 100 -cpu host,flags=+aes

# CPU pinning for dedicated cores (advanced)
qm set 100 -args '-smp 8,sockets=1,cores=8,threads=1'
```

### 2. Memory Optimization
Improves memory performance by disabling dynamic allocation and enabling large memory pages.

```bash
# Disable memory ballooning
qm set 100 -balloon 0

# Enable huge pages (optional)
echo 'vm.nr_hugepages=4096' >> /etc/sysctl.conf
```

### 3. Storage Optimization
Configures storage settings for optimal disk I/O performance with SSD features enabled.

```bash
# Use VirtIO with SSD
qm set 100 -scsi0 local-lvm:vm-100-disk-1,discard=on,ssd=1,iothread=1
```

## Final Notes

### ✅ Successful Configuration Summary
- **BIOS**: IOMMU + Above 4G Decoding enabled, Resizable BAR disabled
- **Host**: VFIO modules loaded, GPU bound to vfio-pci driver
- **VM**: q35 machine, SeaBIOS, All Functions + ROM-bar + PCIe enabled
- **Guest**: Ubuntu 22.04 with NVIDIA 570+ drivers

### 🔧 Key Success Factors for RTX 5090
1. **SeaBIOS compatibility** - Works reliably with ROM-bar enabled
2. **All Functions enabled** - Ensures both GPU and audio passthrough
3. **Above 4G decoding** - Required for 32GB VRAM access
4. **Latest NVIDIA drivers** - 570+ series for Blackwell support

### 📚 Additional Resources
- [RTX 5090 Ubuntu 22.04 Driver Guide](https://github.com/en4ble1337/ai-linux-tools/blob/main/ubuntu22.04-5090.md)
- [Proxmox VE PCI Passthrough Documentation](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [RTX 5090 Specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/)

***
**Last Updated**: September 2025  
**Tested On**: Proxmox VE 9.0, RTX 5090, Ubuntu 22.04 LTS

[1](https://www.reddit.com/r/Proxmox/comments/1kw98pq/proxmox_and_a_5090/)
[2](https://forum.proxmox.com/threads/2025-proxmox-pcie-gpu-passthrough-with-nvidia.169543/)
[3](https://pve.proxmox.com/wiki/NVIDIA_vGPU_on_Proxmox_VE)
[4](https://forum.level1techs.com/t/do-your-rtx-5090-or-general-rtx-50-series-has-reset-bug-in-vm-passthrough/228549)
[5](https://gist.github.com/KasperSkytte/6a2d4e8c91b7117314bceec84c30016b)
[6](https://www.youtube.com/watch?v=rkVrG4s_q34)
[7](https://www.youtube.com/watch?v=lNGNRIJ708k)
[8](https://www.youtube.com/watch?v=391GUL5sVy8)
[9](https://pve.proxmox.com/wiki/PCI_Passthrough)
