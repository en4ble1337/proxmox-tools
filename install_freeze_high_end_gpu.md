# 🚀 Quick Guide: Fix Proxmox Installation Freeze with High-End NVIDIA GPUs (e.g., RTX 3090)

When installing **Proxmox VE 8.x** on systems with high‑end NVIDIA GPUs (such as the **RTX 3090** from the Ampere generation), the installer may **hang, freeze, or display a black screen**.  

This happens because NVIDIA’s drivers can conflict with the Linux kernel during the early boot process.

---

## 🛑 Problem

- Proxmox installer **fails to start** or locks up on boot.
- Common with **Ampere-generation GPUs** (RTX 3000 series).
- Caused by advanced GPU driver initialization before the installer loads.

---

## ✅ Solution — Use the `nomodeset` Boot Parameter

`nomodeset` tells the kernel to skip loading high‑end GPU drivers and use basic graphics mode, allowing the installer to run.

---

### Step-by-Step Installation Fix

1. **Start the Proxmox Installer**
   - Boot from your USB stick or mounted ISO.
   - **Do not** press Enter yet at the menu.

2. **Edit Boot Parameters**
   - Highlight the default installer option.
   - Press **`e`** on your keyboard.

3. **Find the Linux Boot Line**
   - Look for the long line beginning with:
     ```
     linux /boot/vmlinuz...
     ```

4. **Append `nomodeset`**
   - Go to the **end** of that line.
   - Add a space, then type:
     ```
     nomodeset
     ```

5. **Boot with the Change**
   - Press **`F10`** or **`Ctrl + X`** to boot.

6. **Install Proxmox Normally**
   - The installer should now load without freezing.

---

## ℹ️ Notes

- This fix is **temporary** — only needed for installation.
- Remove `nomodeset` post‑install for normal operation.
- If you plan GPU passthrough:
  - Update GRUB kernel parameters.
  - Blacklist conflicting NVIDIA drivers.
  - Load **VFIO** modules.
- **vGPU note:** Consumer RTX 3090 does **not** support NVIDIA’s vGPU partitioning. Passthrough only.

---

💡 **Maintainer’s Tip:** For best stability, enable **IOMMU / VT‑d**, **Above 4G Decoding**, and disable **CSM** in your motherboard BIOS before installing.

---

*Tested on Proxmox VE 8.3 with RTX 3090 Founders Edition — Updated August 2025.*
