#!/bin/bash
# Initialization script for openSUSE Leap 15.1 image on Hetzner

# -e: Exit on commands not found
# -u: Exit on unset variables
# -x: Write to standard error a trace for each command after it expands the command and before it executes it
set -eux

#### Parameters ####

USER="$(whoami)"
PORT=6697
ZNC_VERSION=1.7.3

##### Updates & Packages #####

# Refresh repositories
sudo zypper refresh

# Update packages
sudo zypper update --no-confirm

# Install packages
sudo zypper install --no-confirm docker fail2ban

##### Setup SSH #####

# Disallow root logins over SSH
sudo sed --in-place --regexp-extended "s/#?PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config

# Disable SSH password authentication
sudo sed --in-place --regexp-extended "s/#?PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config

# Restart the SSH service to load the new configuration
sudo systemctl restart sshd

##### Setup Fail2ban #####

# Enable and start the Fail2ban service
sudo systemctl enable --now fail2ban

# Setup Fail2ban configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

##### Setup Docker #####

# Add the user to the docker group
sudo usermod -aG docker "$USER"

# Enable and start the Docker service
sudo systemctl enable --now docker

##### Setup Firewall #####

sudo firewall-cmd --permanent --add-port "$PORT"/tcp

sudo systemctl restart firewalld

##### Configure ZNC #####

## Without an existing configuration

# Generate the basic ZNC configuration (it will be configured later through the UI)
# docker run --interactive --tty --rm --volume znc-data:/znc-data znc:"$ZNC_VERSION" --makeconf

## With an existing configuration on another host (or before reinstalling OS)

### Before reinstalling OS
# Backup existing configuration
# docker run --rm --volumes-from CONTAINER_NAME -v $(PWD):/znc-data busybox tar cvf /znc-data-backup.tar /DESTINATION/ON/HOST

# Copy archive from local to remote
# scp -r user@your.server.example.com:/path/to/foo /home/user/znc-data-backup.tar

### After reinstalling OS
# Copy archive from remote to local
# scp /home/user/znc-data-backup.tar user@your.server.example.com:/path/to/foo/

# Extract archive
# tar xvf /home/user/znc-data-backup.tar

# Create temporary container and volume
# docker container create --name CONTAINER_NAME -v VOLUME_NAME:/znc-data busybox

# Copy directory to volume
# docker cp /home/user/znc-data CONTAINER_NAME:/

# Remove temporary container
# docker container rm CONTAINER_NAME

# Remove unneeded busybox image
# docker image rm busybox

##### Run ZNC #####

# docker run --detach --rm --publish "$PORT:$PORT" --volume znc-data:/znc-data znc:"$ZNC_VERSION"
