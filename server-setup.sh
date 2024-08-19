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
USERNAME="pfm"
SSH_CONFIG="/etc/ssh/sshd_config"
USER_HOME="/home/$USERNAME"
SHELL_SCRIPT="/usr/local/bin/keep_alive.sh"

# Create the user
if id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}User $USERNAME already exists.${RESET}"
else
    sudo useradd -m -s /bin/bash "$USERNAME"
    echo -e "${GREEN}User $USERNAME created.${RESET}"
fi

# Generate SSH key pair for the user
if [ ! -f "$USER_HOME/.ssh/id_rsa" ]; then
    sudo -u $USERNAME ssh-keygen -t rsa -b 4096 -f "$USER_HOME/.ssh/id_rsa" -N ""
    echo -e "${GREEN}SSH key pair generated for $USERNAME.${RESET}"
else
    echo -e "${YELLOW}SSH key pair already exists for $USERNAME.${RESET}"
fi

# Copy the public key to authorized_keys
if [ -f "$USER_HOME/.ssh/id_rsa.pub" ]; then
    sudo mkdir -p "$USER_HOME/.ssh"
    sudo cp "$USER_HOME/.ssh/id_rsa.pub" "$USER_HOME/.ssh/authorized_keys"
    sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo -e "${GREEN}SSH public key installed for $USERNAME.${RESET}"
else
    echo -e "${RED}No public key found. Key generation might have failed.${RESET}"
fi

# Apply the ownership and permissions
sudo chown -R $USERNAME:$USERNAME "$USER_HOME/.ssh"
# Create a script to keep the session alive
sudo tee $SHELL_SCRIPT > /dev/null <<EOL
#!/bin/bash
sleep infinity
exit
EOL
sudo chmod +x $SHELL_SCRIPT

# Configure SSH server for the new user
{
    echo
    echo "# Configuration for user $USERNAME"
    echo "Match User $USERNAME"
    echo "    AllowTcpForwarding yes"
    echo "    PermitOpen any"
    echo "    ForceCommand $SHELL_SCRIPT"
} | sudo tee -a $SSH_CONFIG

echo -e "${GREEN}SSH configuration updated for $USERNAME.${RESET}"
sudo cat $USER_HOME/.ssh/id_rsa > access.key
# Restart SSH service to apply changes
sudo systemctl restart ssh
echo -e "${GREEN}SSH configuration updated and service restarted.${RESET}"

echo -e "${BLUE}Setup complete for user $USERNAME.${RESET}"
