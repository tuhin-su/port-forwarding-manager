#!/bin/bash

# Define colors
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Banner function
print_banner() {
    local border="${MAGENTA}═"
    local text="${BOLD}${CYAN}tuhin-su${RESET}"
    echo -e "${MAGENTA}╔${border}═════════════════════════════${border}╗${RESET}"
    echo -e "${MAGENTA}║${WHITE} ${text} ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╚${border}═════════════════════════════${border}╝${RESET}"
    echo
}

# Print banner
print_banner

# Variables
USERNAME="sshforward"
PORT_FORWARDING_PORT="12345"  # Example port number to forward
SSH_CONFIG="/etc/ssh/sshd_config"
RSSH_CONF="/etc/rssh.conf"
USER_HOME="/home/$USERNAME"

# Create the user
if id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}User $USERNAME already exists.${RESET}"
else
    sudo useradd -m -s /usr/bin/rssh "$USERNAME"
    echo -e "${GREEN}User $USERNAME created.${RESET}"
fi

# Install rssh if not already installed
if ! dpkg -l | grep -q rssh; then
    sudo apt-get update
    sudo apt-get install -y rssh
    echo -e "${GREEN}rssh installed.${RESET}"
else
    echo -e "${YELLOW}rssh is already installed.${RESET}"
fi

# Configure rssh to allow port forwarding only
sudo tee -a $RSSH_CONF > /dev/null <<EOL
# Allow only port forwarding and deny other commands
allowscp
allowcvs
allowrsync
allowsftp
EOL
echo -e "${GREEN}rssh configured to allow port forwarding.${RESET}"

# Configure SSH server for the new user
sudo tee -a $SSH_CONFIG > /dev/null <<EOL

# Configuration for user $USERNAME
Match User $USERNAME
    AllowTcpForwarding yes
    PermitOpen 127.0.0.1:$PORT_FORWARDING_PORT
    ForceCommand /usr/bin/rssh
EOL
echo -e "${GREEN}SSH configuration updated for $USERNAME.${RESET}"

# Generate SSH key pair for the user
if [ ! -f "$USER_HOME/.ssh/id_rsa" ]; then
    sudo -u $USERNAME ssh-keygen -t rsa -b 4096 -f "$USER_HOME/.ssh/id_rsa" -N ""
    echo -e "${GREEN}SSH key pair generated for $USERNAME.${RESET}"
else
    echo -e "${YELLOW}SSH key pair already exists for $USERNAME.${RESET}"
fi

# Create the .ssh directory and set permissions
sudo mkdir -p "$USER_HOME/.ssh"
sudo chown $USERNAME:$USERNAME "$USER_HOME/.ssh"
sudo chmod 700 "$USER_HOME/.ssh"

# Copy the public key to authorized_keys
if [ -f "$USER_HOME/.ssh/id_rsa.pub" ]; then
    sudo cp "$USER_HOME/.ssh/id_rsa.pub" "$USER_HOME/.ssh/authorized_keys"
    sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo -e "${GREEN}SSH public key installed for $USERNAME.${RESET}"
else
    echo -e "${RED}No public key found. Key generation might have failed.${RESET}"
fi

# Apply the ownership and permissions
sudo chown -R $USERNAME:$USERNAME "$USER_HOME/.ssh"

# Restart SSH service to apply changes
sudo systemctl restart ssh
echo -e "${GREEN}SSH configuration updated and service restarted.${RESET}"

echo -e "${BLUE}Setup complete for user $USERNAME.${RESET}"
