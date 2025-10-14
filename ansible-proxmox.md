# Ansible Proxmox LXC Automation Guide

Complete beginner's guide to deploying and managing Proxmox LXC containers using Ansible. This guide covers installation, configuration, and automated deployment workflows with custom configurations.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [SSH Authentication Setup](#ssh-authentication-setup)
- [Proxmox API Configuration](#proxmox-api-configuration)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- **Control Machine**: Linux system (Ubuntu/Debian recommended) where Ansible will run
- **Proxmox Server**: Running Proxmox VE installation with network access
- **Network Access**: SSH connectivity from control machine to Proxmox server
- **Sudo/Root Access**: Administrative privileges on the control machine

> **Note**: Ansible uses an **agentless architecture** - you only install Ansible on your control machine.[4][10]

## Installation

### Install Ansible (Ubuntu/Debian)

For Ubuntu 22.04 and later:

```bash
# Add the Ansible PPA repository
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Update package lists
sudo apt update

# Install required packages
sudo apt install software-properties-common -y

# Install Ansible
sudo apt install ansible -y
```

For Debian:

```bash
sudo apt update
sudo apt install ansible -y
```

### Install via Python PIP (Alternative)

```bash
# Install Python and pip
sudo apt install python3 python3-pip -y

# Install Ansible via pip
sudo pip3 install ansible
```

### Verify Installation

```bash
ansible --version
```

### Install Required Dependencies

```bash
# Install Proxmox API wrapper
sudo pip3 install proxmoxer

# Install requests library
sudo pip3 install requests

# Install passlib (for password hashing)
sudo pip3 install passlib
```

### Install Ansible Community Collection

```bash
# Install the community.general collection
ansible-galaxy collection install community.general

# Verify installation
ansible-galaxy collection list
```

## SSH Authentication Setup

### Generate SSH Key Pair

```bash
# Generate SSH key (ed25519 algorithm)
ssh-keygen -f ~/.ssh/ansible_key -t ed25519
```

### Copy Public Key to Proxmox

```bash
# Replace YOUR_PROXMOX_IP with your actual Proxmox IP address
ssh-copy-id -i ~/.ssh/ansible_key.pub root@YOUR_PROXMOX_IP
```

### Test SSH Connection

```bash
ssh -i ~/.ssh/ansible_key root@YOUR_PROXMOX_IP
```

You should connect without a password prompt.[11][12]

## Proxmox API Configuration

### Create API Token via Web UI

1. Log into Proxmox web interface
2. Click **Datacenter** in the left sidebar
3. Expand **Permissions** section
4. Click **API Tokens**
5. Click **Add** button
6. Configure the token:
   - **User**: Select `root@pam`
   - **Token ID**: Enter `ansible`
   - **Privilege Separation**: **Uncheck** this box (for full permissions)
7. Click **Add**
8. **Copy and save the Secret value immediately**

Your token format: `root@pam!ansible=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`[13][14][15]

## Project Structure

Create the following directory structure:

```
ansible-proxmox/
├── ansible.cfg
├── hosts
├── group_vars/
│   └── proxmox_secrets.yml
├── playbooks/
│   ├── create-lxc.yml
│   ├── modify-lxc-conf.yml
│   ├── configure-lxc.yml
│   └── complete-lxc-workflow.yml
└── roles/
```

### Create ansible.cfg

```ini
[defaults]
# Specify the inventory file location
inventory = ./hosts

# Disable SSH host key checking (convenient for labs)
host_key_checking = False

# Use Python 3 interpreter
interpreter_python = auto_silent

# Specify SSH private key
private_key_file = ~/.ssh/ansible_key

# Increase timeout for slower operations
timeout = 30
```

### Create Inventory File (hosts)

```ini
[proxmox_hosts]
pve01 ansible_host=192.168.1.100

[proxmox_hosts:vars]
ansible_user=root
ansible_connection=ssh
ansible_ssh_private_key_file=~/.ssh/ansible_key
```

Replace `192.168.1.100` with your actual Proxmox IP.[16][17]

### Test Ansible Connectivity

```bash
ansible proxmox_hosts -m ping
```

Expected output:

```
pve01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Quick Start

### 1. Create LXC Container

Create `playbooks/create-lxc.yml`:

```yaml
---
- name: Create and Configure LXC Container
  hosts: proxmox_hosts
  gather_facts: yes
  
  vars:
    # Proxmox API credentials
    proxmox_api_host: "192.168.1.100"
    proxmox_api_user: "root@pam"
    proxmox_api_password: "your_proxmox_password"
    
    # LXC Configuration
    lxc_vmid: 300
    lxc_hostname: "ansible-demo"
    lxc_password: "SecurePassword123"
    lxc_storage: "local-lvm"
    lxc_template: "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    lxc_cores: 2
    lxc_memory: 2048
    lxc_swap: 512
    lxc_disk_size: 8
    lxc_ip_address: "192.168.1.150/24"
    lxc_gateway: "192.168.1.1"
    lxc_nameserver: "8.8.8.8"
    lxc_node: "pve"
    
  tasks:
    - name: Create LXC Container
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        node: "{{ lxc_node }}"
        api_user: "{{ proxmox_api_user }}"
        api_password: "{{ proxmox_api_password }}"
        api_host: "{{ proxmox_api_host }}"
        hostname: "{{ lxc_hostname }}"
        ostemplate: "{{ lxc_template }}"
        password: "{{ lxc_password }}"
        cores: "{{ lxc_cores }}"
        memory: "{{ lxc_memory }}"
        swap: "{{ lxc_swap }}"
        disk: "{{ lxc_disk_size }}"
        storage: "{{ lxc_storage }}"
        netif: '{"net0":"name=eth0,ip={{ lxc_ip_address }},gw={{ lxc_gateway }},bridge=vmbr0"}'
        nameserver: "{{ lxc_nameserver }}"
        features:
          - nesting=1
        state: present
      register: lxc_creation
      
    - name: Start LXC Container
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        api_user: "{{ proxmox_api_user }}"
        api_password: "{{ proxmox_api_password }}"
        api_host: "{{ proxmox_api_host }}"
        state: started
        
    - name: Wait for container to be fully started
      pause:
        seconds: 10
```

Run the playbook:

```bash
ansible-playbook playbooks/create-lxc.yml
```

### 2. Modify LXC .conf File

Create `playbooks/modify-lxc-conf.yml`:

```yaml
---
- name: Modify LXC Configuration File
  hosts: proxmox_hosts
  gather_facts: yes
  
  vars:
    lxc_vmid: 300
    
  tasks:
    - name: Stop LXC container before modifying config
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        api_user: "root@pam"
        api_password: "your_proxmox_password"
        api_host: "192.168.1.100"
        state: stopped
        
    - name: Add custom mount point to LXC config
      ansible.builtin.lineinfile:
        path: "/etc/pve/lxc/{{ lxc_vmid }}.conf"
        line: "mp0: /mnt/shared,mp=/mnt/shared"
        state: present
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Enable nesting feature in LXC config
      ansible.builtin.lineinfile:
        path: "/etc/pve/lxc/{{ lxc_vmid }}.conf"
        regexp: '^features:'
        line: "features: nesting=1,keyctl=1"
        state: present
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Set custom CPU limit
      ansible.builtin.lineinfile:
        path: "/etc/pve/lxc/{{ lxc_vmid }}.conf"
        regexp: '^cpulimit:'
        line: "cpulimit: 2"
        state: present
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Start LXC container after config changes
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        api_user: "root@pam"
        api_password: "your_proxmox_password"
        api_host: "192.168.1.100"
        state: started
```

Run the playbook:

```bash
ansible-playbook playbooks/modify-lxc-conf.yml
```

### 3. Execute Commands Inside Container

Create `playbooks/configure-lxc.yml`:

```yaml
---
- name: Configure LXC Container After Deployment
  hosts: proxmox_hosts
  gather_facts: no
  
  vars:
    lxc_vmid: 300
    
  tasks:
    - name: Update package lists inside container
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "apt update"
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Upgrade all packages inside container
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "DEBIAN_FRONTEND=noninteractive apt upgrade -y"
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Install essential packages
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "apt install -y curl wget git vim htop net-tools"
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Create custom user inside container
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "useradd -m -s /bin/bash appuser && echo 'appuser:AppPass123' | chpasswd"
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Install Docker inside container
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "curl -fsSL https://get.docker.com | sh"
      delegate_to: "{{ inventory_hostname }}"
      
    - name: Create application directory
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "mkdir -p /opt/myapp && chown appuser:appuser /opt/myapp"
      delegate_to: "{{ inventory_hostname }}"
```

Run the playbook:

```bash
ansible-playbook playbooks/configure-lxc.yml
```

## Usage Examples

### Complete Workflow (All-in-One)

Create `playbooks/complete-lxc-workflow.yml`:

```yaml
---
- name: Complete LXC Deployment and Configuration Workflow
  hosts: proxmox_hosts
  gather_facts: yes
  
  vars:
    # Proxmox Configuration
    proxmox_api_host: "192.168.1.100"
    proxmox_api_user: "root@pam"
    proxmox_api_password: "your_password"
    proxmox_node: "pve"
    
    # LXC Container Specifications
    lxc_vmid: 301
    lxc_hostname: "web-server-01"
    lxc_password: "ContainerPass123"
    lxc_template: "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    lxc_storage: "local-lvm"
    lxc_cores: 2
    lxc_memory: 2048
    lxc_swap: 512
    lxc_disk_size: 10
    lxc_ip: "192.168.1.151/24"
    lxc_gateway: "192.168.1.1"
    lxc_nameserver: "8.8.8.8"
    
  tasks:
    # STEP 1: Create LXC Container
    - name: Create LXC container
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        node: "{{ proxmox_node }}"
        api_user: "{{ proxmox_api_user }}"
        api_password: "{{ proxmox_api_password }}"
        api_host: "{{ proxmox_api_host }}"
        hostname: "{{ lxc_hostname }}"
        ostemplate: "{{ lxc_template }}"
        password: "{{ lxc_password }}"
        cores: "{{ lxc_cores }}"
        memory: "{{ lxc_memory }}"
        swap: "{{ lxc_swap }}"
        disk: "{{ lxc_disk_size }}"
        storage: "{{ lxc_storage }}"
        netif: '{"net0":"name=eth0,ip={{ lxc_ip }},gw={{ lxc_gateway }},bridge=vmbr0"}'
        nameserver: "{{ lxc_nameserver }}"
        features:
          - nesting=1
        state: present
      register: container_created
      
    - name: Display container creation result
      debug:
        msg: "Container created: {{ container_created }}"
        
    # STEP 2: Modify LXC .conf file
    - name: Stop container for config modifications
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        api_user: "{{ proxmox_api_user }}"
        api_password: "{{ proxmox_api_password }}"
        api_host: "{{ proxmox_api_host }}"
        state: stopped
      when: container_created.changed
      
    - name: Add custom features to LXC config
      ansible.builtin.lineinfile:
        path: "/etc/pve/lxc/{{ lxc_vmid }}.conf"
        regexp: '^features:'
        line: "features: nesting=1,keyctl=1,fuse=1"
        state: present
        
    # STEP 3: Start container
    - name: Start LXC container
      community.general.proxmox:
        vmid: "{{ lxc_vmid }}"
        api_user: "{{ proxmox_api_user }}"
        api_password: "{{ proxmox_api_password }}"
        api_host: "{{ proxmox_api_host }}"
        state: started
        
    - name: Wait for container to initialize
      pause:
        seconds: 15
        
    # STEP 4: Execute configuration commands inside container
    - name: Update apt cache
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "apt update"
        
    - name: Upgrade system packages
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "DEBIAN_FRONTEND=noninteractive apt upgrade -y"
        
    - name: Install web server and dependencies
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "apt install -y nginx php-fpm php-mysql"
        
    - name: Install monitoring tools
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "apt install -y htop curl wget"
        
    - name: Create web application directory
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "mkdir -p /var/www/html/app && chown www-data:www-data /var/www/html/app"
        
    - name: Enable and start nginx
      ansible.builtin.shell: |
        pct exec {{ lxc_vmid }} -- bash -c "systemctl enable nginx && systemctl start nginx"
        
    - name: Display completion message
      debug:
        msg: "LXC container {{ lxc_hostname }} ({{ lxc_vmid }}) is ready at {{ lxc_ip }}"
```

Run the complete workflow:

```bash
ansible-playbook playbooks/complete-lxc-workflow.yml
```

## Best Practices

### Use Ansible Vault for Sensitive Data

Never store passwords in plain text:

```bash
# Create encrypted variables file
ansible-vault create group_vars/proxmox_secrets.yml
```

Add your sensitive variables:

```yaml
vault_proxmox_password: "your_password"
vault_lxc_password: "container_password"
```

Reference in playbooks:

```yaml
proxmox_api_password: "{{ vault_proxmox_password }}"
```

Run playbooks with:

```bash
ansible-playbook create-lxc.yml --ask-vault-pass
```

### Use Tags for Selective Execution

Add tags to tasks:

```yaml
tasks:
  - name: Create container
    community.general.proxmox:
      # configuration
    tags: create
    
  - name: Configure container
    shell: pct exec ...
    tags: configure
```

Run specific tags:

```bash
ansible-playbook complete-lxc-workflow.yml --tags configure
```

### Check Mode (Dry Run)

Test playbooks without making changes:

```bash
ansible-playbook create-lxc.yml --check
```

### Verbose Output for Debugging

```bash
ansible-playbook create-lxc.yml -v   # verbose
ansible-playbook create-lxc.yml -vv  # more verbose
ansible-playbook create-lxc.yml -vvv # very verbose
```

## Troubleshooting

### Module not found: community.general.proxmox

**Solution**: Install the collection:

```bash
ansible-galaxy collection install community.general
```

### SSH Connection Failures

**Solution**: Verify SSH key is properly copied:

```bash
ssh-copy-id -i ~/.ssh/ansible_key.pub root@YOUR_PROXMOX_IP
```

### Permission Denied When Modifying .conf Files

**Solution**: Ensure you're connecting as root user and using `delegate_to` properly.[18][19]

### Container Doesn't Start After Config Changes

**Solution**: Check LXC config syntax:

```bash
cat /etc/pve/lxc/VMID.conf
```

### apt Commands Hang in Container

**Solution**: Use `DEBIAN_FRONTEND=noninteractive` and add `-y` flag:

```bash
pct exec VMID -- bash -c "DEBIAN_FRONTEND=noninteractive apt install -y package"
```

## Useful Ansible Modules

- `community.general.proxmox` - Manage LXC containers[20][21]
- `community.general.proxmox_kvm` - Manage VMs[22]
- `ansible.builtin.lineinfile` - Edit configuration files[23]
- `ansible.builtin.shell` - Execute shell commands
- `ansible.builtin.copy` - Copy files to remote hosts
- `ansible.builtin.template` - Deploy Jinja2 templates

## Additional Resources

- [Official Ansible Documentation](https://docs.ansible.com)
- [Community General Collection](https://docs.ansible.com/ansible/latest/collections/community/general/)
- [Proxmox Module Documentation](https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_module.html)
- [Ansible Best Practices Guide](https://redhat-cop.github.io/automation-good-practices/)[3][5]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this guide for personal or commercial projects.

***
[1](https://spacelift.io/blog/github-actions-ansible)
[2](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/developing_automation_content/publishing-playbook-collection-aap)
[3](https://github.com/redhat-cop/automation-good-practices)
[4](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html)
[5](https://redhat-cop.github.io/automation-good-practices/)
[6](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.4/html/automation_controller_user_guide/controller-projects)
[7](https://www.reddit.com/r/ansible/comments/nx9of3/beginner_question_git_repositories_playbook/)
[8](https://github.com/nleiva/ansible-links)
[9](https://github.com/varunpalekar/ansible-structure)
[10](https://www.youtube.com/watch?v=XdozKMndWdo)
[11](https://dev.to/rimelek/ansible-playbook-and-ssh-keys-33bo)
[12](https://jhooq.com/ansible-ssh-keys-for-server-mgmt/)
[13](https://www.youtube.com/watch?v=wK8PUp7rjzs)
[14](https://kenwardtown.com/2024/06/25/create-an-api-token-for-proxmox-ve/)
[15](https://www.youtube.com/watch?v=EWeRsXbNnbk)
[16](https://www.linuxtechi.com/how-to-install-ansible-on-ubuntu/)
[17](https://www.techtutorials.tv/sections/promox/proxmox-how-to-automate-using-ansible/)
[18](https://forum.proxmox.com/threads/how-to-make-changes-to-an-lxc-container-with-ansible.117594/)
[19](https://www.reddit.com/r/ansible/comments/14u61he/how_to_change_a_proxmox_lxc_with_ansible/)
[20](https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_module.html)
[21](https://docs.ansible.com/ansible/5/collections/community/general/proxmox_module.html)
[22](https://joshrnoll.com/deploying-proxmox-vms-with-ansible/)
[23](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html)
