# SSH Key Authentication Setup for LXC Container

Complete step-by-step guide to set up SSH key authentication for root access to an Ubuntu 22.04 LXC container using PuTTY on Windows.

## Prerequisites

- Ubuntu 22.04 LXC container running
- Root SSH access enabled
- PuTTY suite installed on Windows (including PuTTYgen)
- Container IP address known

## Step 1: Generate SSH Key with PuTTYgen

1. **Open PuTTYgen** (comes with PuTTY suite)

2. **⚠️ IMPORTANT: Select the correct key type**
   - Select **RSA** (first option) - this is SSH-2 format
   - **DO NOT** select "SSH-1 (RSA)" - this is obsolete and will cause issues
   - Set key length to 2048 bits (default)

3. **Generate the key:**
   - Click **"Generate"**
   - Move your mouse randomly in the blank area to generate randomness
   - Wait for key generation to complete

4. **Configure the key:**
   - Add a comment in **"Key comment"** field (e.g., `lxc-access-key`)
   - Optionally add a passphrase for extra security (leave blank for passwordless access)

5. **Save the keys:**
   - Click **"Save private key"** → save as `lxc-key.ppk` (PuTTY format)
   - Click **"Save public key"** → save as `lxc-key.pub`
   - **Copy the public key text** from the top text box (starts with `ssh-rsa AAAAB3NzaC1...`)

## Step 2: Set Up SSH Key on LXC Container

1. **Connect to your LXC container** (via console or existing SSH):
   ```bash
   lxc exec container-name bash
   ```

2. **Create SSH directory for root** (if it doesn't exist):
   ```bash
   mkdir -p /root/.ssh
   chmod 700 /root/.ssh
   ```

3. **Add the public key:**
   ```bash
   nano /root/.ssh/authorized_keys
   ```
   - Paste the public key text you copied from PuTTYgen
   - **Ensure it's all on one line** (no line breaks in the middle)
   - Should look like: `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... lxc-access-key`
   - Save and exit (`Ctrl+X`, `Y`, `Enter`)

4. **Set correct permissions:**
   ```bash
   chmod 600 /root/.ssh/authorized_keys
   chown root:root /root/.ssh/authorized_keys
   ```

5. **Verify the setup:**
   ```bash
   ls -la /root/.ssh/
   # Should show: drwx------ for .ssh directory and -rw------- for authorized_keys
   
   ssh-keygen -l -f /root/.ssh/authorized_keys
   # Should show key fingerprint without errors
   ```

## Step 3: Configure SSH Server

1. **Edit SSH configuration:**
   ```bash
   nano /etc/ssh/sshd_config
   ```

2. **Ensure these settings are present and uncommented:**
   ```
   PermitRootLogin yes
   PubkeyAuthentication yes
   AuthorizedKeysFile .ssh/authorized_keys
   ```

3. **Check for conflicting configurations:**
   ```bash
   # Check if there are additional config files
   ls /etc/ssh/sshd_config.d/
   cat /etc/ssh/sshd_config.d/*
   ```

4. **Restart SSH service:**
   ```bash
   systemctl restart sshd
   systemctl status sshd
   ```

## Step 4: Test Connection with PuTTY

1. **Get your container's IP address:**
   ```bash
   # From host system:
   lxc list
   
   # Or from inside container:
   ip addr show
   ```

2. **Configure PuTTY:**
   - **Session tab:**
     - Host Name: Your LXC container's IP address
     - Port: 22
     - Connection type: SSH

3. **Configure SSH key authentication:**
   - Go to **Connection → SSH → Auth → Credentials**
   - Click **"Browse"** next to "Private key file for authentication"
   - Select your `lxc-key.ppk` file

4. **Set auto-login username:**
   - Go to **Connection → Data**
   - Enter `root` in **"Auto-login username"**

5. **Save session (optional):**
   - Go back to **Session** tab
   - Enter a name in **"Saved Sessions"** (e.g., `LXC-Root`)
   - Click **"Save"**

6. **Test the connection:**
   - Click **"Open"**
   - If prompted about host key, click **"Accept"**
   - You should now be logged in as root **without entering a password**

## Troubleshooting

### Still asking for password?

1. **Check authorized_keys format:**
   ```bash
   cat /root/.ssh/authorized_keys
   ```
   - Should start with `ssh-rsa AAAAB3NzaC1...` (not numbers)
   - Should be one continuous line

2. **Verify file permissions:**
   ```bash
   ls -la /root/.ssh/
   # .ssh should be 700, authorized_keys should be 600
   ```

3. **Check SSH logs in real-time:**
   ```bash
   # Stop SSH service
   systemctl stop sshd
   
   # Start in debug mode
   /usr/sbin/sshd -D -d
   ```
   Try connecting from PuTTY in another session and watch the debug output.

4. **Verify PuTTY configuration:**
   - Make sure you're using the `.ppk` file (not `.pub`)
   - Verify the path to the private key file
   - Check that auto-login username is set to `root`

### Common Issues

- **Wrong key format:** Make sure you selected **RSA** (not SSH-1) in PuTTYgen
- **Line breaks in key:** Public key must be on a single line in authorized_keys
- **Wrong file permissions:** SSH is strict about permissions on .ssh directory and files
- **Multiple config files:** Check `/etc/ssh/sshd_config.d/` for conflicting settings

## Security Considerations

⚠️ **Important Security Notes:**

- This setup allows **anyone with the private key** to access your container as root
- For production environments, consider:
  - Using a regular user account instead of root
  - Adding a passphrase to the private key
  - Implementing IP address restrictions
  - Using certificate-based authentication
  - Disabling password authentication entirely

## Alternative Key Types

For enhanced security, you can use **Ed25519** instead of RSA:

1. In PuTTYgen, select **"EdDSA"**
2. Set curve to **"Ed25519"**
3. Generate and follow the same steps
4. The public key will start with `ssh-ed25519` instead of `ssh-rsa`

---

**Success!** You now have passwordless SSH key authentication set up for your LXC container.
