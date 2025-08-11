```markdown
# Quick Guide: Fix Proxmox Installation Freeze with High-End NVIDIA GPUs (e.g., RTX 3090)

When installing Proxmox VE 8.x on systems with higher-end NVIDIA GPUs such as the RTX 3090 (Ampere generation), you may face boot or freeze issues at installation. This is caused by compatibility conflicts between the installer and NVIDIA's GPU drivers.

## Problem

- Proxmox installer hangs, freezes, or shows a black screen during boot.
- Caused by NVIDIA GPU driver conflicts with the Linux kernel during the installation phase.

## Solution: Use the `nomodeset` Boot Parameter

Adding the `nomodeset` parameter prevents the kernel from loading advanced GPU drivers during the installation, allowing it to proceed using a basic graphics mode.

### Step-by-Step Fix

1. **Boot Proxmox Installer:**

   When you see the Proxmox installer boot menu, **do NOT press Enter immediately**.

2. **Edit Boot Parameters:**

   Press `e` on your keyboard to enter the boot parameter editing mode.

3. **Find the Linux Line:**

   Use arrow keys to navigate to the line starting with `linux`—this line contains the kernel boot parameters.

4. **Add `nomodeset`:**

   At the end of the `linux` line, add a space then type:

   ```
   nomodeset
   ```

5. **Boot Installer:**

   Press `F10` or `Ctrl + X` to continue booting the installer with the modified parameters.

6. **Proceed with Installation:**

   The installer should now boot correctly. Complete the installation as usual.

## Notes

- This change is temporary and only required during the installation.
- After successful installation, configure GPU passthrough or driver settings inside your installed Proxmox system.
- For RTX 3090 passthrough, additional setup is required (GRUB parameters, module blacklisting, VFIO setup).

---

*This quick guide addresses common Proxmox installation issues with RTX 3090 GPUs and other similar NVIDIA cards from the Ampere generation.*  
```

This format is optimized for GitHub README or Gist usage—concise, clear, and focused on the typical failure case and its immediate fix. Let me know if you'd like me to create a more detailed full installation/passthrough setup guide as well.

[1] https://forum.proxmox.com/threads/pci-gpu-passthrough-on-proxmox-ve-8-installation-and-configuration.130218/page-3
[2] https://gist.github.com/KasperSkytte/6a2d4e8c91b7117314bceec84c30016b
[3] https://forum.proxmox.com/threads/cant-install-nvidia-driver.82448/
[4] https://gist.github.com/briann/79aa21950336909de47c1dcad60bb7f7
[5] https://www.youtube.com/watch?v=cPrOoeMxzu0
[6] https://www.reddit.com/r/Proxmox/comments/tmarrw/split_gpu_into_multiple_vms_vgpu/
[7] https://forum.proxmox.com/threads/help-with-rtx3090-passthrough-code-43.136893/
[8] https://forum.proxmox.com/tags/passthrough-gpu/page-2
[9] https://www.reddit.com/r/VFIO/comments/pjfyp1/yet_another_single_gpu_passthrough_post_proxmox/
[10] https://gitlab.com/polloloco/vgpu-proxmox
