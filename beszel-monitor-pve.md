# Beszel Installation Guide for LXC Ubuntu 22.04 with NVIDIA GPU Support

A comprehensive step-by-step guide to install Beszel monitoring system on Ubuntu 22.04 LXC container with Docker and NVIDIA GPU monitoring capabilities.

## Prerequisites

- Ubuntu 22.04 LXC container
- Docker and Docker Compose installed
- NVIDIA drivers and nvidia-smi configured
- NVIDIA Container Toolkit installed

## Step 1: Install Beszel Hub

Install the Beszel hub using Docker with persistent storage :[1]

```bash
# Create Docker volume for persistent data
docker volume create beszel_data

# Run Beszel hub container
docker run -d \
  --name beszel \
  --restart=unless-stopped \
  --volume beszel_data:/beszel_data \
  -p 8090:8090 \
  henrygd/beszel
```

Docker-compose

```bash
# Create directory for agent configuration
mkdir -p ~/beszel-agent
cd ~/beszel-agent

# Create docker-compose.yml file
nano docker-compose.yml
```

```base
services:
  beszel:
    image: henrygd/beszel
    container_name: beszel
    restart: unless-stopped
    ports:
      - 8090:8090
    volumes:
      - ./beszel_data:/beszel_data
```


Verify the container is running:
```bash
docker ps | grep beszel
```

## Step 2: Access Beszel Web Interface

Navigate to the Beszel web interface :[1]

```
http://YOUR_LXC_IP:8090
```

Replace `YOUR_LXC_IP` with your LXC container's IP address. You'll be prompted to create an admin account on first access.

## Step 3: Add New System with GPU Monitoring

1. **Click "Add System"** in the web interface upper right corner[2]
2. **Select the Docker tab** for agent deployment[2]
3. **Fill in system details**:
   - **Name**: Choose a descriptive name for your system
   - **Host/IP**: Enter your LXC container IP address
   - **Port**: Leave default (45876)
4. **Copy the generated configuration** but **DO NOT click "Add System" yet**[2]

## Step 4: Create Docker Compose Configuration

Create the Docker Compose file with NVIDIA GPU support :[3][1]

```bash
# Create directory for agent configuration
mkdir -p ~/beszel-agent
cd ~/beszel-agent

# Create docker-compose.yml file
nano docker-compose.yml
```

Add the following configuration with your specific KEY and TOKEN from Step 3:

```yaml
services:
  beszel-agent:
    image: henrygd/beszel-agent-nvidia
    container_name: beszel-agent-nvidia
    restart: unless-stopped
    network_mode: host
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities:
                - utility
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./beszel_agent_data:/var/lib/beszel-agent
      # Optional: monitor additional disks/partitions
      # - /mnt/disk/.beszel:/extra-filesystems/sda1:ro
    environment:
      LISTEN: 45876
      GPU: true
      KEY: 'YOUR_SSH_KEY_FROM_STEP_3'
      TOKEN: YOUR_TOKEN_FROM_STEP_3
      HUB_URL: http://localhost:8090
```

**Important**: Replace `YOUR_SSH_KEY_FROM_STEP_3` and `YOUR_TOKEN_FROM_STEP_3` with the actual values provided by the Beszel web interface.[4][3]

## Step 5: Deploy the Agent

Run the Docker Compose configuration:

```bash
# Start the agent container
docker compose up -d

# Verify the container is running
docker compose ps

# Check logs for any issues
docker compose logs beszel-agent
```

## Step 6: Complete System Addition

1. **Return to the Beszel web interface**
2. **Click "Add System"** to complete the setup[2]
3. **Verify the system appears** in your monitoring dashboard

## Step 7: Verify GPU Monitoring

Check that GPU statistics are being collected:

1. **View the system dashboard** - GPU metrics should appear within a few minutes
2. **Check container logs** for GPU detection:
   ```bash
   docker logs beszel-agent-nvidia
   ```
3. **Test nvidia-smi access** in the container:
   ```bash
   docker exec beszel-agent-nvidia nvidia-smi
   ```

## Troubleshooting

### No GPU Statistics Showing

If GPU statistics aren't appearing :[3][4]

1. **Verify GPU environment variable**:
   ```bash
   docker exec beszel-agent-nvidia env | grep GPU
   ```

2. **Check nvidia-smi access**:
   ```bash
   docker exec beszel-agent-nvidia nvidia-smi
   ```

3. **Enable debug logging** by adding to environment section:
   ```yaml
   environment:
     LOG_LEVEL: debug
   ```

### Container Won't Start

1. **Check Docker Compose syntax**:
   ```bash
   docker compose config
   ```

2. **Verify NVIDIA Container Toolkit**:
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   ```

### Connection Issues

1. **Verify network connectivity** between hub and agent
2. **Check firewall rules** for port 45876
3. **Confirm correct IP addresses** in configuration

## Additional Configuration

### Monitor Additional Filesystems

To monitor additional disks or partitions, uncomment and modify the volume mount :[1]

```yaml
volumes:
  - /mnt/your-disk/.beszel:/extra-filesystems/disk1:ro
```

### Custom Port Configuration

If using a different port, update both the `LISTEN` environment variable and ensure the port is accessible between containers.[1]

This guide provides a complete setup for Beszel monitoring with NVIDIA GPU support on Ubuntu 22.04 LXC containers, ensuring proper Docker integration and persistent monitoring capabilities.[3][1]

[1](https://beszel.dev/guide/gpu)
[2](https://wiki.opensourceisawesome.com/books/beszel-monitor/chapter/beszel-server-and-agent/export/html)
[3](https://jasontucker.blog/getting-beszel-agent-to-monitor-gpu-usage-when-using-docker/)
[4](https://github.com/henrygd/beszel/issues/262)
[5](https://computingforgeeks.com/how-to-install-lxc-lxc-ui-on-ubuntu/)
[6](https://linuxcontainers.org/lxc/getting-started/)
[7](https://www.cyberciti.biz/faq/install-lxd-on-ubuntu-22-04-lts-using-apt-snap/)
[8](https://lxdware.com/installing-the-lxd-dashboard-on-ubuntu-22-04/)
[9](https://www.youtube.com/watch?v=hvRvoWi1GQM)
[10](https://discuss.linuxcontainers.org/t/odd-behavior-installing-ubuntu-desktop-on-ubuntu-22-04-and-lxd-22-04-containers/14275)
[11](https://mariushosting.com/how-to-install-beszel-on-your-synology-nas/)
[12](https://www.youtube.com/watch?v=nIgxpvAsbKk)
[13](https://blog.ktz.me/using-beszel-to-monitor-windows/)
[14](https://beszel.dev/guide/agent-installation)
[15](https://forum.proxmox.com/threads/network-ups-tools-nut-as-ubuntu-22-04-lxc-container.152248/)
[16](https://beszel.dev/guide/getting-started)
[17](https://cloudspinx.com/run-linux-containers-with-lxc-lxd-on-ubuntu/)
[18](https://hub.docker.com/r/henrygd/beszel-agent-nvidia)
[19](https://upcloud.com/resources/tutorials/basic-server-monitoring-beszel/)
[20](https://www.youtube.com/watch?v=Ca5CFCnn-NQ)
