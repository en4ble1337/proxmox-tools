cat << 'EOF' | bash
apt update && apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh
EOF
