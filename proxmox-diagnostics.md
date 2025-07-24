# Proxmox Unexpected Reboot Diagnostics Guide

A comprehensive guide to diagnosing unexpected reboots in Proxmox environments through log analysis.

## Quick Start

Start with these two commands to identify the most common causes:

```bash
sensors  # Check current temperatures
dmesg -T | tail -100  # Recent kernel messages with timestamps
```

## System-Level Logs

### Check System Journal for Critical Events

```bash
journalctl -p err -S "24 hours ago" | grep -E "(kernel|hardware|power|thermal)"
journalctl -p crit -S "24 hours ago"
```

### Check Kernel Messages for Hardware Issues

```bash
dmesg | grep -E "(error|fail|critical|thermal|power|hardware)"
dmesg -T | tail -100  # Recent kernel messages with timestamps
```

### Check System Logs

```bash
grep -E "(reboot|shutdown|panic|segfault)" /var/log/syslog
grep -E "(Out of memory|oom-killer)" /var/log/syslog
```

## Hardware-Specific Logs

### Check for Thermal Issues

```bash
sensors  # Current temperatures
journalctl -u systemd-logind | grep -i thermal
```

### Check Power Management

```bash
journalctl | grep -E "(power|acpi|suspend)"
```

### Check for Memory Issues

```bash
grep -i "memory" /var/log/kern.log
cat /proc/meminfo  # Current memory status
```

## Proxmox-Specific Logs

### Check Proxmox Cluster and Service Logs

```bash
journalctl -u pve-cluster
journalctl -u pveproxy
journalctl -u pvedaemon
```

### Check VM/Container Logs

```bash
grep -r "error\|fail" /var/log/pve/
```

## Most Likely Causes

Listed in order of frequency for sudden reboots:

1. **Thermal shutdown** - Check `sensors` output and thermal logs
2. **Power supply issues** - Look for ACPI/power-related kernel messages
3. **Memory problems** - Check for OOM killer or memory errors
4. **Hardware failure** - Check dmesg for hardware error messages
5. **Kernel panic** - Look for panic messages in logs

## Troubleshooting Workflow

1. **Start here**: Run `sensors` and `dmesg -T | tail -100`
2. **Check critical logs**: Run the system journal commands
3. **Investigate hardware**: Check thermal, power, and memory logs
4. **Review Proxmox services**: Check cluster and daemon logs
5. **Analyze patterns**: Look for recurring issues or timing patterns

## Additional Tips

- Use timestamps to correlate events across different log files
- Pay attention to events occurring just before the reboot timestamp
- Consider hardware monitoring tools for ongoing surveillance
- Check BIOS/UEFI logs if system logs don't reveal the cause
