# Terraform Proxmox LXC Container Management Guide

A comprehensive guide for managing Proxmox LXC containers using Terraform on Ubuntu 22.04.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Proxmox API Token Setup](#proxmox-api-token-setup)
- [Project Structure](#project-structure)
- [Configuration Files](#configuration-files)
- [Usage](#usage)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Prerequisites

- Ubuntu 22.04 server
- Proxmox VE 7.x or 8.x
- Root or sudo access
- Network connectivity to Proxmox host

---

## Installation

### Install Terraform on Ubuntu 22.04

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install required dependencies
sudo apt-get install -y gnupg software-properties-common

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Verify the key fingerprint
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt-get update
sudo apt-get install terraform

# Verify installation
terraform version
```

Expected output:
```
Terraform v1.x.x
on linux_amd64
```

### Install Additional Tools (Optional but Recommended)

```bash
# Install jq for JSON parsing
sudo apt-get install -y jq

# Install git for version control
sudo apt-get install -y git
```

---

## Proxmox API Token Setup

### Create API Token via Web UI

1. Log in to Proxmox web interface: `https://your-proxmox-ip:8006`
2. Navigate to **Datacenter → Permissions → API Tokens**
3. Click **Add**
4. Fill in the details:
   - **User**: `root@pam`
   - **Token ID**: `terraform`
   - **Privilege Separation**: Unchecked (☐)
   - **Expire**: `never`
5. Click **Add**
6. **IMPORTANT**: Copy the secret immediately (shown only once)

Example token format:
- **Token ID**: `root@pam!terraform`
- **Secret**: `433151eb-f03a-4ff9-9ecc-1bf9f3d9068e`

### Create API Token via CLI (Alternative)

```bash
# SSH into Proxmox server
ssh root@your-proxmox-ip

# Create token
pveum user token add root@pam terraform --privsep=0

# Grant permissions
pveum acl modify / -token 'root@pam!terraform' -role Administrator
```

---

## Project Structure

Create an organized directory structure:

```bash
# Create project directory
mkdir -p ~/terraform-projects/proxmox-lxc/{plans,backups}
cd ~/terraform-projects/proxmox-lxc

# Initialize Git (optional but recommended)
git init
```

### Recommended File Structure

```
~/terraform-projects/proxmox-lxc/
├── .gitignore                # Git ignore file
├── README.md                 # Project documentation
├── providers.tf              # Provider configuration
├── variables.tf              # Variable definitions
├── lxc_containers.tf         # LXC resource definitions
├── outputs.tf                # Output values (optional)
├── terraform.tfvars          # Variable values (optional, not in git)
├── plans/                    # Saved execution plans
│   └── *.tfplan
├── backups/                  # State file backups
│   └── *.backup
├── terraform.tfstate         # Current state (auto-generated)
└── terraform.tfstate.backup  # Previous state (auto-generated)
```

### Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files (may contain sensitive data)
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore plan files
*.tfplan
plans/*.tfplan

# Ignore backup files
*.backup
backups/*.backup
EOF
```

---

## Configuration Files

### 1. providers.tf

Provider configuration for Proxmox connection.

```hcl
terraform {
  required_version = ">= 1.1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.5"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure     = true
  pm_api_url          = "https://10.1.20.136:8006/api2/json"
  pm_api_token_id     = "root@pam!terraform"
  pm_api_token_secret = "your-secret-token-here"
}
```

**Important Notes:**
- Default Proxmox API port is **8006**, not 443
- Replace IP address with your Proxmox server IP
- Replace token secret with your actual token
- For production, use environment variables instead of hardcoding secrets

**Using Environment Variables (Recommended for Production):**

```bash
# Set environment variables
export PM_API_TOKEN_ID="root@pam!terraform"
export PM_API_TOKEN_SECRET="your-secret-token-here"
export PM_API_URL="https://10.1.20.136:8006/api2/json"

# providers.tf without hardcoded secrets
provider "proxmox" {
  pm_tls_insecure = true
  # Reads from environment variables automatically
}
```

### 2. variables.tf

Variable definitions with default values.

```hcl
variable "containers" {
  description = "Map of LXC containers to create"
  type = map(object({
    hostname    = string
    vmid        = optional(number)
    cores       = optional(number, 1)
    memory      = optional(number, 512)
    swap        = optional(number, 512)
    disk_size   = optional(string, "8G")
    storage     = optional(string, "local-lvm")
    ip          = optional(string, "dhcp")
    ip6         = optional(string, "dhcp")
    gateway     = optional(string, null)
    nameserver  = optional(string, null)
    searchdomain = optional(string, null)
    bridge      = optional(string, "vmbr0")
    start       = optional(bool, false)
    onboot      = optional(bool, false)
    protection  = optional(bool, false)
    unprivileged = optional(bool, true)
    nesting     = optional(bool, true)
    description = optional(string, "")
  }))
  
  default = {
    web-server = {
      hostname    = "web-01"
      vmid        = 101
      cores       = 2
      memory      = 2048
      disk_size   = "20G"
      description = "Web server container"
    }
    db-server = {
      hostname    = "db-01"
      vmid        = 102
      cores       = 4
      memory      = 4096
      disk_size   = "50G"
      description = "Database server container"
    }
    cache-server = {
      hostname    = "cache-01"
      vmid        = 103
      cores       = 2
      memory      = 1024
      disk_size   = "10G"
      description = "Redis cache server"
    }
  }
}

variable "target_node" {
  description = "Proxmox node name"
  type        = string
  default     = "ai-node1"
}

variable "ostemplate" {
  description = "LXC OS template path"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "default_password" {
  description = "Default root password for containers"
  type        = string
  default     = "changeme"
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys to add to containers"
  type        = string
  default     = ""
}
```

### 3. lxc_containers.tf

Resource definitions using variables.

```hcl
resource "proxmox_lxc" "containers" {
  for_each = var.containers
  
  # Basic settings
  target_node  = var.target_node
  hostname     = each.value.hostname
  vmid         = each.value.vmid
  description  = each.value.description
  ostemplate   = var.ostemplate
  password     = var.default_password
  unprivileged = each.value.unprivileged
  start        = each.value.start
  onboot       = each.value.onboot
  protection   = each.value.protection
  
  # SSH keys (optional)
  ssh_public_keys = var.ssh_public_keys != "" ? var.ssh_public_keys : null
  
  # Resource allocation
  cores      = each.value.cores
  memory     = each.value.memory
  swap       = each.value.swap
  
  # Root filesystem
  rootfs {
    storage = each.value.storage
    size    = each.value.disk_size
  }
  
  # Network configuration
  network {
    name   = "eth0"
    bridge = each.value.bridge
    ip     = each.value.ip
    ip6    = each.value.ip6
    gw     = each.value.gateway
  }
  
  # Container features
  features {
    nesting = each.value.nesting
  }
  
  # Nameserver configuration (optional)
  nameserver = each.value.nameserver
  searchdomain = each.value.searchdomain
}
```

### 4. outputs.tf (Optional)

Display useful information after creation.

```hcl
output "container_info" {
  description = "Information about created containers"
  value = {
    for k, v in proxmox_lxc.containers : k => {
      id       = v.id
      vmid     = v.vmid
      hostname = v.hostname
      ip       = v.network[0].ip
    }
  }
}

output "container_ids" {
  description = "Map of container names to VMIDs"
  value = {
    for k, v in proxmox_lxc.containers : k => v.vmid
  }
}
```

### 5. terraform.tfvars (Optional)

Override default values without modifying variables.tf.

**⚠️ NEVER commit this file to git (contains secrets)**

```hcl
# Override target node
target_node = "pve-node2"

# Override default password
default_password = "MySecurePassword123!"

# Add SSH keys
ssh_public_keys = <<-EOT
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... user@host
EOT

# Override container definitions
containers = {
  production-web = {
    hostname  = "prod-web-01"
    vmid      = 201
    cores     = 4
    memory    = 8192
    disk_size = "100G"
    ip        = "10.0.0.10/24"
    gateway   = "10.0.0.1"
  }
  production-db = {
    hostname  = "prod-db-01"
    vmid      = 202
    cores     = 8
    memory    = 16384
    disk_size = "200G"
    ip        = "10.0.0.11/24"
    gateway   = "10.0.0.1"
  }
}
```

---

## Usage

### Initial Setup

```bash
# Navigate to project directory
cd ~/terraform-projects/proxmox-lxc

# Initialize Terraform (downloads provider plugins)
terraform init

# Validate configuration
terraform validate

# Format configuration files
terraform fmt
```

### Plan Changes

```bash
# Preview what will be created
terraform plan

# Save plan to file for review
terraform plan -out=plans/deployment-$(date +%Y%m%d-%H%M%S).tfplan

# Review saved plan
terraform show plans/deployment-*.tfplan
```

### Apply Changes

```bash
# Apply changes (will prompt for confirmation)
terraform apply

# Apply with auto-approve (use carefully)
terraform apply -auto-approve

# Apply from saved plan (no prompt)
terraform apply plans/deployment-*.tfplan
```

### Destroy Resources

```bash
# Destroy all managed resources
terraform destroy

# Destroy specific resource
terraform destroy -target='proxmox_lxc.containers["web-server"]'
```

---

## Common Operations

### Add a New Container

Edit `variables.tf` and add to the `containers` map:

```hcl
default = {
  # Existing containers...
  
  # Add new container
  app-server = {
    hostname  = "app-01"
    vmid      = 104
    cores     = 2
    memory    = 2048
    disk_size = "15G"
  }
}
```

Then apply:

```bash
terraform plan   # Shows: 1 to add
terraform apply  # Creates the new container
```

### Remove a Container

Remove the container definition from `variables.tf` and apply:

```bash
terraform plan   # Shows: 1 to destroy
terraform apply  # Removes the container
```

Or use targeted destroy:

```bash
terraform destroy -target='proxmox_lxc.containers["app-server"]'
```

### Modify Container Resources

Edit the container definition in `variables.tf`:

```hcl
web-server = {
  hostname  = "web-01"
  vmid      = 101
  cores     = 4        # Changed from 2
  memory    = 4096     # Changed from 2048
  disk_size = "20G"
}
```

**Note**: Some changes require container recreation (hostname, disk size). Check plan carefully.

### View Current State

```bash
# List all managed resources
terraform state list

# Show details of specific resource
terraform state show 'proxmox_lxc.containers["web-server"]'

# Show all outputs
terraform output

# Show specific output
terraform output container_ids
```

### Import Existing Container

If you have an existing container not managed by Terraform:

```bash
# Add definition to variables.tf first
# Then import it
terraform import 'proxmox_lxc.containers["existing"]' node-name/lxc/vmid

# Example:
terraform import 'proxmox_lxc.containers["existing"]' ai-node1/lxc/100
```

### Backup State File

```bash
# Manual backup
cp terraform.tfstate backups/terraform.tfstate.$(date +%Y%m%d-%H%M%S)

# Automated backup script
cat > backup-state.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
cp terraform.tfstate backups/terraform.tfstate.$DATE
echo "State backed up to: backups/terraform.tfstate.$DATE"
EOF

chmod +x backup-state.sh
./backup-state.sh
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Connection Refused Error

**Error:**
```
Error: dial tcp 10.1.20.136:443: connect: connection refused
```

**Solution:**
- Use port **8006** instead of 443 in `pm_api_url`
- Verify Proxmox is running: `systemctl status pveproxy`
- Check firewall: `iptables -L | grep 8006`

#### 2. Authentication Failed

**Error:**
```
Error: authentication failure
```

**Solution:**
- Verify token ID format: `root@pam!terraform`
- Check token hasn't expired
- Verify token permissions: `pveum user token list root@pam`
- Ensure privilege separation is disabled (unchecked)

#### 3. Template Not Found

**Error:**
```
Error: template not found
```

**Solution:**
```bash
# SSH to Proxmox and check templates
pvesh get /nodes/{node}/storage/{storage}/content --content vztmpl

# Download Ubuntu 22.04 template
pveam update
pveam available | grep ubuntu-22
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
```

#### 4. Storage Pool Not Found

**Error:**
```
Error: storage 'local-lvm' does not exist
```

**Solution:**
```bash
# List available storage
pvesh get /storage

# Use correct storage name in variables.tf
storage = "local-lvm"  # or "local" or your custom storage
```

#### 5. VMID Already Exists

**Error:**
```
Error: VM 101 already exists
```

**Solution:**
- Change VMID in `variables.tf`
- Or remove existing container in Proxmox
- Or import existing container into Terraform state

#### 6. Network Bridge Not Found

**Error:**
```
Error: bridge 'vmbr0' does not exist
```

**Solution:**
```bash
# Check available bridges on Proxmox
ip link show | grep vmbr

# Update variables.tf with correct bridge
bridge = "vmbr0"  # or vmbr1, vmbr2, etc.
```

### Enable Debug Logging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# Run terraform command
terraform plan

# Review logs
less terraform-debug.log

# Disable logging
unset TF_LOG
unset TF_LOG_PATH
```

### Refresh State

```bash
# Refresh state to match real infrastructure
terraform refresh

# Force refresh during plan
terraform plan -refresh=true
```

### Recover from Failed Apply

```bash
# View current state
terraform show

# Attempt to fix by re-applying
terraform apply -auto-approve

# If corrupted, restore from backup
cp backups/terraform.tfstate.YYYYMMDD-HHMMSS terraform.tfstate

# Verify state matches reality
terraform plan
```

---

## Best Practices

### Security

1. **Never commit secrets to Git**
   - Use `.gitignore` for `*.tfvars`
   - Use environment variables for sensitive data
   - Consider using HashiCorp Vault or similar

2. **Use strong passwords**
   ```hcl
   default_password = "$(openssl rand -base64 32)"
   ```

3. **Enable SSH keys instead of passwords**
   ```hcl
   ssh_public_keys = file("~/.ssh/id_rsa.pub")
   password = null  # Disable password auth
   ```

4. **Use unprivileged containers**
   ```hcl
   unprivileged = true  # Always use this unless you have a reason not to
   ```

### Organization

1. **Use meaningful names**
   ```hcl
   # Good
   web-server = { hostname = "prod-web-01" }
   
   # Bad
   container1 = { hostname = "server1" }
   ```

2. **Add descriptions**
   ```hcl
   description = "Production web server running Nginx"
   ```

3. **Group related containers**
   ```hcl
   # Production
   prod-web-01 = { ... }
   prod-web-02 = { ... }
   
   # Development
   dev-web-01 = { ... }
   ```

### Version Control

1. **Commit often with meaningful messages**
   ```bash
   git add providers.tf variables.tf lxc_containers.tf
   git commit -m "Add database server container configuration"
   ```

2. **Tag releases**
   ```bash
   git tag -a v1.0.0 -m "Initial production release"
   git push origin v1.0.0
   ```

3. **Create branches for experiments**
   ```bash
   git checkout -b feature/add-monitoring-stack
   # Make changes
   git commit -m "Add Prometheus and Grafana containers"
   git checkout main
   git merge feature/add-monitoring-stack
   ```

### State Management

1. **Regular backups**
   ```bash
   # Create daily backup cron job
   crontab -e
   # Add: 0 2 * * * cd ~/terraform-projects/proxmox-lxc && cp terraform.tfstate backups/terraform.tfstate.$(date +\%Y\%m\%d)
   ```

2. **Use remote state for teams** (Advanced)
   ```hcl
   terraform {
     backend "s3" {
       bucket = "my-terraform-state"
       key    = "proxmox-lxc/terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

### Testing

1. **Always run plan before apply**
   ```bash
   terraform plan -out=tfplan
   # Review carefully
   terraform apply tfplan
   ```

2. **Test in development first**
   ```bash
   # Use separate tfvars for environments
   terraform plan -var-file="dev.tfvars"
   terraform plan -var-file="prod.tfvars"
   ```

3. **Validate before committing**
   ```bash
   terraform fmt -check
   terraform validate
   ```

### Monitoring

1. **Use outputs to track resources**
   ```hcl
   output "container_ips" {
     value = {
       for k, v in proxmox_lxc.containers : 
       k => v.network[0].ip
     }
   }
   ```

2. **Enable container monitoring in Proxmox**
   - Check resource usage in Proxmox UI
   - Set up alerts for high CPU/memory usage

### Documentation

1. **Maintain a README.md in your project**
   - Document custom configurations
   - List prerequisites
   - Include troubleshooting steps

2. **Comment complex logic**
   ```hcl
   # Use static IP only for production containers
   ip = can(regex("^prod-", each.key)) ? "10.0.0.${100 + index(keys(var.containers), each.key)}/24" : "dhcp"
   ```

---

## References

- **Terraform Proxmox Provider**: https://github.com/Telmate/terraform-provider-proxmox
- **Provider Documentation**: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
- **Terraform Documentation**: https://www.terraform.io/docs
- **Proxmox VE Documentation**: https://pve.proxmox.com/pve-docs/
- **Terraform Best Practices**: https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html

---

## Quick Reference Commands

```bash
# Installation
sudo apt-get install terraform

# Initialize project
terraform init

# Validate configuration
terraform validate

# Format files
terraform fmt

# Plan changes
terraform plan
terraform plan -out=tfplan

# Apply changes
terraform apply
terraform apply tfplan
terraform apply -auto-approve

# Destroy resources
terraform destroy
terraform destroy -target='resource.name'

# State management
terraform state list
terraform state show 'resource.name'
terraform state rm 'resource.name'

# Outputs
terraform output
terraform output output_name

# Import existing resource
terraform import 'resource.name' node/type/vmid

# Refresh state
terraform refresh

# Show current state
terraform show

# Debug
export TF_LOG=DEBUG
terraform plan
```

---

## License

This guide is provided as-is for educational purposes.

## Contributing

Feel free to submit issues and enhancement requests!

---

**Created**: 2025
**Last Updated**: 2025-10-16
