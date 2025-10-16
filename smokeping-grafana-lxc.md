# Smokeping Monitoring Dashboard Setup Guide

This guide will help you integrate the Smokeping dashboard (ID 11335) into your existing Prometheus and Grafana setup to monitor network latency and packet loss.

## Prerequisites

Before following this guide, ensure you have already set up Prometheus and Grafana using the instructions at:
https://github.com/en4ble1337/proxmox-tools/blob/main/prometheus_grafana_pve_lxc.md

## Step 1: Download and Install the Smokeping Prober

The Smokeping dashboard relies on an external tool called `smokeping_prober` to perform pings and provide data to Prometheus. Install this on the same server where Prometheus is running.

1. Download the latest release:
```bash
cd /tmp
wget https://github.com/SuperQ/smokeping_prober/releases/download/v0.8.1/smokeping_prober-0.8.1.linux-amd64.tar.gz
```

2. Extract and install the binary:
```bash
tar xvf smokeping_prober-0.8.1.linux-amd64.tar.gz
sudo mv smokeping_prober-0.8.1.linux-amd64/smokeping_prober /usr/local/bin/
```

3. Verify the installation:
```bash
smokeping_prober --version
```

## Step 2: Create a Configuration File for the Prober

Configure which hosts you want to monitor for latency and packet loss.

1. Create a configuration directory:
```bash
sudo mkdir /etc/smokeping_prober
```

2. Create and edit the configuration file:
```bash
sudo nano /etc/smokeping_prober/config.yml
```

3. Add your targets to the file (customize the IP addresses as needed):
```yaml
targets:
  - hosts:
    - 192.168.1.1    # Default gateway
    - 1.1.1.1        # Cloudflare DNS
    - 8.8.8.8        # Google DNS
```

4. Save and close the file (`Ctrl+X`, then `Y`, then `Enter`).

## Step 3: Create a systemd Service to Run the Prober

Ensure `smokeping_prober` runs automatically and restarts on failure.

1. Create the service file:
```bash
sudo nano /etc/systemd/system/smokeping_prober.service
```

2. Add the service definition:
```ini
[Unit]
Description=Smokeping Prober
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/smokeping_prober --config.file=/etc/smokeping_prober/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
```

3. Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable smokeping_prober
sudo systemctl start smokeping_prober
```

4. Check the service status:
```bash
sudo systemctl status smokeping_prober
```

You should see an `active (running)` status in the output.

## Step 4: Grant Network Capabilities (Critical Step)

⚠️ **Important:** The `smokeping_prober` needs special permissions to send ICMP ping packets. Without this, the service will run but won't collect any data.

Grant the required Linux capability:
```bash
sudo setcap cap_net_raw+ep /usr/local/bin/smokeping_prober
```

Restart the service to apply the permissions:
```bash
sudo systemctl restart smokeping_prober
```

### Verification

Wait about 30 seconds, then verify that pings are being sent:
```bash
curl http://localhost:9374/metrics | grep smokeping_requests_total
```

You should see non-zero values like:
```
smokeping_requests_total{host="1.1.1.1",ip="1.1.1.1",source=""} 5
smokeping_requests_total{host="192.168.1.1",ip="192.168.1.1",source=""} 5
smokeping_requests_total{host="8.8.8.8",ip="8.8.8.8",source=""} 5
```

If all values are `0`, the capability was not applied correctly. Double-check the previous step.

## Step 5: Configure Prometheus to Scrape the Prober

Tell Prometheus to collect metrics from the running `smokeping_prober`.

1. Edit your Prometheus configuration file:
```bash
sudo nano /etc/prometheus/prometheus.yml
```

2. Add a new scrape job under the `scrape_configs` section:
```yaml
- job_name: 'smokeping'
  static_configs:
    - targets: ['localhost:9374']
```

Your complete `prometheus.yml` should look similar to this:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Your existing Proxmox VE Exporter job
  - job_name: 'pve'
    # ... existing pve configuration ...

  # New job for the ping monitor
  - job_name: 'smokeping'
    static_configs:
      - targets: ['localhost:9374']
```

3. Restart Prometheus to apply the changes:
```bash
sudo systemctl restart prometheus
```

4. Verify Prometheus is scraping the target:
   - Open your Prometheus web UI: `http://<your-server-ip>:9090`
   - Go to **Status** → **Targets**
   - Find the `smokeping` job and confirm the state is **UP**

## Step 6: Import the Dashboard into Grafana

The final step is to import the pre-made Smokeping dashboard into Grafana.

1. Log in to your Grafana web interface.

2. Navigate to the Import page:
   - On the left-hand menu, click on **Dashboards**
   - Click the **New** button in the top right
   - Select **Import**

3. Import the dashboard:
   - In the "Import via grafana.com" field, enter the dashboard ID: `11335`
   - Click the **Load** button
   - On the next screen, select your **Prometheus** data source from the dropdown menu
   - Click the **Import** button

## Done! 🎉

You should now have a functional Smokeping dashboard showing latency and packet loss for your monitored targets. It may take a few minutes for data to populate.

## Troubleshooting

If you don't see data on the dashboard:

1. **Check the time range:** In the top-right corner of Grafana, ensure the time range is set to "Last 15 minutes" or similar.

2. **Verify the prober is collecting data:**
   ```bash
   curl http://localhost:9374/metrics | grep smokeping_requests_total
   ```
   All values should be greater than 0. If they're all 0, review Step 4.

3. **Check Prometheus targets:** Go to `http://<your-server-ip>:9090` → Status → Targets and ensure the `smokeping` target is UP.

4. **Check service logs:**
   ```bash
   sudo journalctl -u smokeping_prober -f
   ```

## Customizing Monitored Hosts

To add or remove hosts from monitoring:

1. Edit the configuration file:
   ```bash
   sudo nano /etc/smokeping_prober/config.yml
   ```

2. Modify the `hosts` list under `targets`

3. Restart the service:
   ```bash
   sudo systemctl restart smokeping_prober
   ```
