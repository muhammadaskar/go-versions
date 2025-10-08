#!/bin/bash

# Go Version Manager Script
# Usage: ./go-version-manager.sh [action] [version]

set -e

GO_VERSIONS_DIR="$HOME/go-versions"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default versions to install
DEFAULT_VERSIONS=("1.18.10" "1.19.13" "1.20.14" "1.21.7" "1.22.0")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Function to create directory structure
setup_directories() {
    mkdir -p "$GO_VERSIONS_DIR"
    print_status "Created Go versions directory: $GO_VERSIONS_DIR"
}

# Function to clean Go paths from environment
clean_go_paths() {
    # Clean PATH from all Go references
    export PATH=$(echo $PATH | sed 's|:[^:]*/\.gvm[^:]*||g')
    export PATH=$(echo $PATH | sed 's|:[^:]*/go-versions[^:]*||g')
    export PATH=$(echo $PATH | sed 's|:/usr/local/go/bin||g')
}

# Function to switch Go version
switch_go_version() {
    local version=$1
    local version_dir="go$version"
    local version_path="$GO_VERSIONS_DIR/$version_dir"
    
    # Check if version exists
    if [ ! -d "$version_path" ]; then
        print_error "Go version $version is not installed"
        echo "Available versions:"
        list_installed_versions
        return 1
    fi
    
    # Clean environment first
    clean_go_paths
    
    # Remove existing symlink and create new one
    rm -f "$GO_VERSIONS_DIR/current"
    ln -s "$version_path" "$GO_VERSIONS_DIR/current"
    
    # Clean bashrc and add clean configuration
    sed -i '/# ===== GO CONFIGURATION =====/,/# ===== END GO CONFIGURATION =====/d' ~/.bashrc
    
    # Add clean Go config to bashrc
    cat >> ~/.bashrc << 'EOF'

# ===== GO CONFIGURATION =====
# Clean Go configuration
export GOROOT="$HOME/go-versions/current"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
# ===== END GO CONFIGURATION =====
EOF
    
    # Update current session
    export GOROOT="$HOME/go-versions/current"
    export GOPATH="$HOME/go"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
    
    print_status "Switched to Go $version"
    
    # Verify the switch
    local go_binary="$version_path/bin/go"
    if [ -f "$go_binary" ]; then
        local actual_version=$("$go_binary" version | cut -d' ' -f3)
        echo "  Version confirmed: $actual_version"
    else
        print_error "Go binary not found in $version_path/bin/go"
        return 1
    fi
    
    echo ""
    print_warning "Please run 'source ~/.bashrc' or open a new terminal for changes to take effect in all sessions"
}

# Function to download and install specific Go version
download_go_version() {
    local version=$1
    local version_dir="go$version"
    local tar_file="go$version.linux-amd64.tar.gz"
    local download_url="https://go.dev/dl/$tar_file"
    
    # Check if version already exists
    if [ -d "$GO_VERSIONS_DIR/$version_dir" ]; then
        print_warning "Go version $version already exists. Skipping..."
        return 0
    fi
    
    print_status "Downloading Go version $version..."
    
    # Download Go
    if wget -q --show-progress "$download_url" -O "/tmp/$tar_file"; then
        print_status "Download completed for Go $version"
    else
        print_error "Failed to download Go $version"
        return 1
    fi
    
    # Extract and install
    print_status "Installing Go $version..."
    
    # Create temporary directory for extraction
    local temp_dir="/tmp/go_extract_$$"
    mkdir -p "$temp_dir"
    
    # Extract tar file
    if tar -xzf "/tmp/$tar_file" -C "$temp_dir"; then
        # Move to versions directory
        mv "$temp_dir/go" "$GO_VERSIONS_DIR/$version_dir"
        
        # Cleanup
        rm -rf "$temp_dir"
        rm "/tmp/$tar_file"
        
        print_status "Successfully installed Go $version to $GO_VERSIONS_DIR/$version_dir"
        
        # Ask if user wants to switch to the new version
        read -p "Do you want to switch to Go $version now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            switch_go_version "$version"
        fi
    else
        print_error "Failed to extract Go $version"
        rm -rf "$temp_dir"
        rm "/tmp/$tar_file"
        return 1
    fi
}

# Function to download multiple versions
download_multiple_versions() {
    local versions=("$@")
    
    for version in "${versions[@]}"; do
        download_go_version "$version"
    done
}

# Function to list installed versions
list_installed_versions() {
    print_status "Installed Go versions:"
    if [ -z "$(ls -A "$GO_VERSIONS_DIR")" ]; then
        print_warning "No Go versions installed"
        return 1
    fi
    
    for dir in "$GO_VERSIONS_DIR"/go*/; do
        if [ -d "$dir" ]; then
            local version_name=$(basename "$dir")
            local go_binary="$dir/bin/go"
            
            if [ -f "$go_binary" ]; then
                local actual_version=$("$go_binary" version | cut -d' ' -f3)
                if [ -L "$GO_VERSIONS_DIR/current" ] && [ "$(readlink -f "$GO_VERSIONS_DIR/current")" = "$dir" ]; then
                    echo "  * $version_name ($actual_version) [ACTIVE]"
                else
                    echo "  - $version_name ($actual_version)"
                fi
            else
                echo "  - $version_name (corrupted)"
            fi
        fi
    done
}

# Function to show current active version
show_current_version() {
    if [ -L "$GO_VERSIONS_DIR/current" ]; then
        local current_path=$(readlink -f "$GO_VERSIONS_DIR/current")
        local current_version=$(basename "$current_path")
        local go_binary="$current_path/bin/go"
        
        if [ -f "$go_binary" ]; then
            local actual_version=$("$go_binary" version | cut -d' ' -f3)
            print_status "Current active version: $current_version ($actual_version)"
        else
            print_error "Current version is corrupted"
        fi
    else
        print_warning "No active Go version set"
    fi
}

# Function to remove a specific version
remove_go_version() {
    local version=$1
    local version_dir="go$version"
    
    if [ ! -d "$GO_VERSIONS_DIR/$version_dir" ]; then
        print_error "Go version $version is not installed"
        return 1
    fi
    
    # Check if trying to remove active version
    if [ -L "$GO_VERSIONS_DIR/current" ] && [ "$(readlink -f "$GO_VERSIONS_DIR/current")" = "$GO_VERSIONS_DIR/$version_dir" ]; then
        print_warning "You are removing the currently active version!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Removal cancelled"
            return 0
        fi
    fi
    
    print_warning "Removing Go version $version..."
    rm -rf "$GO_VERSIONS_DIR/$version_dir"
    print_status "Successfully removed Go $version"
}

# Function to cleanup all versions
cleanup_all_versions() {
    print_warning "This will remove ALL installed Go versions!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$GO_VERSIONS_DIR"/*
        rm -f "$GO_VERSIONS_DIR"/current
        print_status "All Go versions have been removed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show usage
show_usage() {
    echo "Go Version Manager"
    echo ""
    echo "Usage: $0 [action] [version]"
    echo "       $0 [command]"
    echo ""
    echo "Actions:"
    echo "  download <version>      Download and install specific Go version"
    echo "  remove <version>        Remove specific Go version"
    echo "  switch <version>        Switch to specific Go version"
    echo ""
    echo "Commands:"
    echo "  list                    List all installed Go versions"
    echo "  current                 Show current active version"
    echo "  default                 Install default versions (${DEFAULT_VERSIONS[*]})"
    echo "  clean                   Remove all installed versions"
    echo "  setup                   Setup directory structure only"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 download 1.18.10    Download and install Go 1.18.10"
    echo "  $0 download 1.19.13    Download and install Go 1.19.13"
    echo "  $0 download 1.20.14    Download and install Go 1.20.14"
    echo "  $0 download 1.21.7     Download and install Go 1.21.7"
    echo "  $0 download 1.22.0     Download and install Go 1.22.0"
    echo "  $0 download 1.23.0     Download and install Go 1.23.0"
    echo "  $0 switch 1.18.10      Switch to Go 1.18.10"
    echo "  $0 remove 1.18.10      Remove Go 1.18.10"
    echo "  $0 default             Install all default versions"
    echo "  $0 list                List installed versions"
    echo "  $0 current             Show current version"
    echo ""
    echo "Available versions format: 1.18.10, 1.19.13, 1.20.14, etc."
}

# Main script logic
main() {
    # Create directories if they don't exist
    setup_directories
    
    local action=$1
    local version=$2
    
    case $action in
        "list")
            list_installed_versions
            ;;
        "current")
            show_current_version
            ;;
        "switch")
            if [ -z "$version" ]; then
                print_error "Version required for switch"
                echo "Usage: $0 switch <version>"
                list_installed_versions
                exit 1
            fi
            switch_go_version "$version"
            ;;
        "download")
            if [ -z "$version" ]; then
                print_error "Version required for download"
                echo "Usage: $0 download <version>"
                echo "Available versions: https://go.dev/dl/"
                exit 1
            fi
            download_go_version "$version"
            ;;
        "remove")
            if [ -z "$version" ]; then
                print_error "Version required for removal"
                echo "Usage: $0 remove <version>"
                list_installed_versions
                exit 1
            fi
            remove_go_version "$version"
            ;;
        "default")
            print_status "Installing default Go versions: ${DEFAULT_VERSIONS[*]}"
            download_multiple_versions "${DEFAULT_VERSIONS[@]}"
            list_installed_versions
            ;;
        "clean")
            cleanup_all_versions
            ;;
        "setup")
            print_status "Directory setup completed"
            ;;
        "help"|"-h"|"--help"|"")
            show_usage
            ;;
        *)
            # Support old format: version action (for backward compatibility)
            if [[ $action =~ ^[0-9] ]]; then
                local old_version=$action
                local old_action=$version
                
                print_warning "Deprecated format detected. Please use: $0 $old_action $old_version"
                echo ""
                
                case $old_action in
                    "download")
                        download_go_version "$old_version"
                        ;;
                    "remove")
                        remove_go_version "$old_version"
                        ;;
                    *)
                        print_error "Unknown action: $old_action"
                        show_usage
                        exit 1
                        ;;
                esac
            else
                print_error "Unknown action: $action"
                show_usage
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"