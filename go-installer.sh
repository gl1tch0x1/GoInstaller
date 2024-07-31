#!/bin/bash

# Constants
GO_VERSION="1.20.7"  # Set the version you want to install
ARCH=$(dpkg --print-architecture)
GO_TAR="go$GO_VERSION.linux-$ARCH.tar.gz"
GO_URL="https://golang.org/dl/$GO_TAR"
INSTALL_DIR="/usr/local"
PROFILE_FILE="/etc/profile"
LOG_FILE="/var/log/go_install.log"
SUPPORTED_ARCHS=("amd64" "arm64" "386")

# Functions
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_go_installed() {
    if command -v go &> /dev/null; then
        log "Go is already installed"
        return 0
    else
        return 1
    fi
}

check_architecture() {
    if [[ ! " ${SUPPORTED_ARCHS[@]} " =~ " ${ARCH} " ]]; then
        log "Unsupported architecture: $ARCH"
        exit 1
    fi
}

install_go() {
    log "Downloading Go $GO_VERSION for $ARCH"
    wget -q --show-progress "$GO_URL" -O "/tmp/$GO_TAR"
    if [ $? -ne 0 ]; then
        log "Failed to download Go"
        exit 1
    fi
    
    log "Extracting Go tarball"
    tar -C "$INSTALL_DIR" -xzf "/tmp/$GO_TAR"
    if [ $? -ne 0 ]; then
        log "Failed to extract Go"
        exit 1
    fi

    log "Setting up environment variables"
    if ! grep -q '/usr/local/go/bin' "$PROFILE_FILE"; then
        echo "export PATH=\$PATH:/usr/local/go/bin" >> "$PROFILE_FILE"
    fi
    if ! grep -q '\$HOME/go/bin' "$PROFILE_FILE"; then
        echo "export PATH=\$PATH:\$HOME/go/bin" >> "$PROFILE_FILE"
    fi
    source "$PROFILE_FILE"

    log "Cleaning up"
    rm "/tmp/$GO_TAR"

    log "Go $GO_VERSION has been installed"
}

ensure_root() {
    if [ "$EUID" -ne 0 ]; then
        log "Please run as root"
        exit 1
    fi
}

update_system() {
    log "Checking for system updates"
    apt-get update -qq
    if [ $? -ne 0 ]; then
        log "Failed to update package list"
        exit 1
    fi
    
    log "Upgrading system packages"
    apt-get upgrade -y -qq
    if [ $? -ne 0 ]; then
        log "Failed to upgrade packages"
        exit 1
    fi
    
    log "System is up to date"
}

install_go_tools() {
    log "Installing assetfinder and waybackurls"
    
    go install github.com/tomnomnom/assetfinder@latest
    if [ $? -ne 0 ]; then
        log "Failed to install assetfinder"
        exit 1
    fi
    
    go install github.com/tomnomnom/waybackurls@latest
    if [ $? -ne 0 ]; then
        log "Failed to install waybackurls"
        exit 1
    fi

    log "assetfinder and waybackurls have been installed"
}

# Script Execution
log "Starting Go installation script"
ensure_root
update_system

if ! check_go_installed; then
    check_architecture
    install_go
fi

install_go_tools

log "Go installation script completed"
